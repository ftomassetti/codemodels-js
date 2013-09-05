require 'rkelly'
require 'js-lightmodels/metamodel'

module JsLightmodels

class << self
	attr_accessor :skip_unknown_node
end

def self.parse_file(path)
	content = IO.read(path)
	self.parse(content)
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

def self.parse(code)
	parser = RKelly::Parser.new
	tree = parser.parse(code)
	tree_to_model(tree)
end

def self.tree_to_model(tree)
	return node_to_model(tree.value[0]) if tree.value.count==1
	node_to_model(tree)
end

# def self.properties_of(model)
# 	usa ecore!!!
# 	model.methods.select {|x| x.to_s.end_with?('=') and not([:==,:===,:<=,:>=,:!=].include?(x)) }
# end

def self.node_properties(node)
	node.class.instance_methods(false)
end

def self.adapter(model_class,ref)
	if JsLightmodels::ParsingAdapters[model_class] && JsLightmodels::ParsingAdapters[model_class][ref.name]
		JsLightmodels::ParsingAdapters[model_class][ref.name]
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

def self.assign_ref_to_model(model,ref,value)
	if ref.many
		adder_method = :"add#{ref.name.capitalize}"
		value.each {|el| model.send(adder_method,node_to_model(el))}
	else
		setter_method = :"#{ref.name}="
		value=value[0] if value.is_a?(Array)
		model.send(setter_method,node_to_model(value))
	end
end

def self.assign_att_to_model(model,att,value)
	if att.many
		adder_method = :"add#{att.name.capitalize}"
		value.each {|el| model.send(adder_method,node_to_model(el))}
	else
		setter_method = :"#{att.name}="
		value=value[0] if value.is_a?(Array)
		model.send(setter_method,node_to_model(value))
	end
end

def self.node_to_model(node)
	return node if node.is_a?(String)
	return node if node.is_a?(Fixnum)
	class_name = node.class.simple_name.remove_postfix('Node')
	if JsLightmodels.const_defined? class_name
		model_class = JsLightmodels.const_get(class_name)
		#puts "* model_class: #{model_class}"

		model = model_class.new

		model_class.ecore.eAllReferences.each do |ref|			
			node_ref_value = node.send(reference_to_method(model_class,ref))
			#puts "#{ref.name} = #{node_ref_value}"
			assign_ref_to_model(model,ref,node_ref_value)
		end

		model_class.ecore.eAllAttributes.each do |att|			
			node_att_value = node.send(attribute_to_method(model_class,att))
			#puts "#{ref.name} = #{node_ref_value}"
			assign_att_to_model(model,att,node_att_value)
		end
		
		model 
	else
		raise "Unknown node type: #{class_name}"
	end
rescue Exception => e
	puts "parent is #{node.class}"
	raise e
end

end