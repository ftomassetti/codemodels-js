require 'js-lightmodels/metamodel'
require 'js-lightmodels/monkey_patching'
require 'lightmodels'

module LightModels
module Js

# TODO move some stuff to the lightmodels module

class << self
	attr_accessor :skip_unknown_node
end

def self.parse_file(path)
	content = IO.read(path)
	self.parse_code(content,path)
end

class ParsingError < Exception
 	attr_reader :node

 	def initialize(node,msg)
 		@node = node
 		@msg = msg
 	end

 	def to_s
 		"#{@msg}, start line: #{@node.position.start_line}"
 	end

end

class UnknownNodeType < ParsingError

 	def initialize(node,where=nil)
 		super(node,"UnknownNodeType: type=#{node.node_type.name} , where: #{where}")
 	end

end

def self.parse_code(code,filename='<code>')
	java_import 'java.io.StringReader'
	java_import 'org.mozilla.javascript.CompilerEnvirons'
	java_import 'org.mozilla.javascript.Parser'
	env = CompilerEnvirons.new
	parser = Parser.new(env)
	reader = StringReader.new(code)

	tree = parser.parse(reader, filename, 1)
	tree_to_model(tree,code)
end

def self.tree_to_model(tree,code)
	node_to_model(tree,code)
end

def self.adapter_specific_class(model_class,ref)
	return nil unless LightModels::Js::ParsingAdapters[model_class]
	LightModels::Js::ParsingAdapters[model_class][ref.name]
end

# TODO remove code below, moved to LightModels

def self.adapter(model_class,ref)
	if LightModels::Js::ParsingAdapters[model_class] && LightModels::Js::ParsingAdapters[model_class][ref.name]
		LightModels::Js::ParsingAdapters[model_class][ref.name]
	else
		if model_class.superclass!=Object
			adapter(model_class.superclass,ref) 
		else
			nil
		end
	end
end

def self.reference_to_method(model_class,ref)
	s = ref.name
	#s = 'value' if s=='body'
	adapted = adapter(model_class,ref)
	s = adapted if adapted		
	s.to_sym
end

def self.attribute_to_method(model_class,att)
	s = att.name
	adapted = adapter(model_class,att)
	s = adapted if adapted		
	s.to_sym
end

def self.assign_ref_to_model(model,ref,value,code)
	return unless value!=nil # we do not need to assign a nil...
	if ref.many
		adder_method = :"add#{ref.name.capitalize}"
		value.each {|el| model.send(adder_method,node_to_model(el,code))}
	else
		setter_method = :"#{ref.name}="
		raise "Trying to assign an array to a single property. Class #{model.class}, property #{ref.name}" if value.is_a?(::Array)
		model.send(setter_method,node_to_model(value,code))
	end
rescue Object => e
	puts "Problem while assigning ref #{ref.name} (many? #{ref.many}) to #{model.class}. Value: #{value.class}"
	puts "\t<<#{e}>>"
	raise e
end

def self.assign_att_to_model(model,att,value)
	if att.many
		adder_method = :"add#{att.name.capitalize}"
		value.each {|el| model.send(adder_method,el)}
	else
		setter_method = :"#{att.name}="
		raise "Trying to assign an array to a single property. Class #{model.class}, property #{att.name}" if value.is_a?(::Array)
		model.send(setter_method,value)
	end
end

def self.populate_attr(node,att,model)	
	raise "Error: the attribute has no name" unless att.name
	value = get_feature_value(node,att.name,model)
	#puts "Value got for #{node.class} #{att} : #{value.class}"
	# nil are ignored
	model.send(:"#{att.name}=",value) if value!=nil
end

def self.populate_ref(node,ref,model,code)
	value = get_feature_value(node,ref.name,model)
	if value
		if value==node
			puts "avoiding loop... #{ref.name}, class #{node.class}" 
			return
		end
		if value.is_a?(Java::JavaUtil::Collection)
			capitalized_name = ref.name.proper_capitalize	
			value.each do |el|
				model.send(:"add#{capitalized_name}",node_to_model(el,code))
			end
		else
			model.send(:"#{ref.name}=",node_to_model(value,code))
		end
	end
end

def self.assign_attr_value(model,prop_name,value)
	if value.is_a?(Java::JavaUtil::Collection)
		capitalized_name = prop_name.proper_capitalize	
		value.each do |el|
			model.send(:"add#{capitalized_name}",el)
		end
	else
		model.send(:"#{ref.name}=",value)
	end
end

def self.assign_ref_value(model,prop_name,value,code)
	if value.is_a?(Java::JavaUtil::Collection)
		capitalized_name = prop_name.proper_capitalize	
		value.each do |el|
			#begin
				model.send(:"add#{capitalized_name}",node_to_model(el,code))
			#rescue Object=>e
			#	raise "Assigning prop #{prop_name} to #{model}: #{e}"
			#end
		end
	else
		model.send(:"#{ref.name}=",node_to_model(value,code))
	end
end

def self.newlines(code,start_pos,end_pos)
	piece = code[start_pos..end_pos]
	piece.lines.count
end

def self.column_last_char(code,start_pos,end_pos)
	piece = code[start_pos..end_pos]
	last_line = nil
	piece.lines.each{|l| last_line=l}
	last_line.length
end

def self.node_to_model(node,code)
	metaclass = get_corresponding_metaclass(node)
	instance = metaclass.new

	instance.language = LANGUAGE
	instance.source = LightModels::SourceInfo.new
	instance.source.begin_pos = LightModels::Position.new
	instance.source.begin_pos.line = node.lineno
	instance.source.begin_pos.column = node.position+1
	instance.source.end_pos = LightModels::Position.new	
	bp = node.getAbsolutePosition
	ep = node.getAbsolutePosition+node.length
	instance.source.end_pos.line = node.lineno+newlines(code,bp,ep)-1
	instance.source.end_pos.column = column_last_char(code,bp,ep)

	metaclass.ecore.eAllAttributes.each do |attr|
		unless additional_property?(node.class,attr.name)
			populate_attr(node,attr,instance)
		end
	end
	metaclass.ecore.eAllReferences.each do |ref|
		unless additional_property?(node.class,ref.name)
			populate_ref(node,ref,instance,code)
		end
	end
	# check for added properties
	additional_properties(node.class).each do |prop_name,prop_data|
		value = prop_data[:getter].call(node)
		if Js.get_att_type(prop_data[:prop_type])
			assign_attr_value(instance,prop_name.to_s,value)
		else
			assign_ref_value(instance,prop_name.to_s,value,code)
		end
	end
	instance
end

class Parser < LightModels::Parser

	def parse_code(code)
		LightModels::Js.parse_code(code)
	end

end

end
end