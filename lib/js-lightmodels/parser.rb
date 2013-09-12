require 'rkelly'
require 'js-lightmodels/metamodel'

module LightModels

module Js

class << self
	attr_accessor :skip_unknown_node
end

def self.parse_file(path)
	content = IO.read(path)
	#puts "content size: #{content.length}"
	self.parse_code(content)
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

class RKellyLogger 

	attr_accessor :errors, :debug_msgs

	def initialize
		@errors = []
		@debug_msgs = []
	end

	def error(msg)
		@errors << msg
	end

	def debug(msg)
		@debug_msgs << msg
	end

end

def self.parse_code(code)
	parser = RKelly::Parser.new
	logger = RKellyLogger.new
	parser.logger = logger

	tree = parser.parse(code)
	if logger.errors.count > 0
		raise "Parsing Errors: #{logger.errors}. Debug msgs: #{logger.debug_msgs}"
	end
	#puts "Tree: #{tree.class}"
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

def self.assign_ref_to_model(model,ref,value)
	return unless value # we do not need to assign a nil...
	if ref.many
		adder_method = :"add#{ref.name.capitalize}"
		value.each {|el| model.send(adder_method,node_to_model(el))}
	else
		setter_method = :"#{ref.name}="
		#value=value[0] if value.is_a?(Array)
		raise "Trying to assign an array to a single property. Class #{model.class}, property #{ref.name}" if value.is_a?(::Array)
		model.send(setter_method,node_to_model(value))
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
		#value=value[0] if value.is_a?(Array)
		raise "Trying to assign an array to a single property. Class #{model.class}, property #{att.name}" if value.is_a?(::Array)
		model.send(setter_method,value)
	end
end

def self.node_to_model(node)
	if node.is_a?(String)
		l = StringLiteral.new
		l.value = node
		return l
	end
	return node if node.is_a?(Fixnum)
	raise "Wrong node: #{node.class}" unless node.is_a? RKelly::Nodes::Node
	if node.class.simple_name == 'StringNode'
		class_name = 'StringLiteral'
	elsif node.class.simple_name == 'IfNode'
		class_name = 'IfStatement'		
	elsif node.class.simple_name.end_with?('Node')
		class_name = node.class.simple_name.remove_postfix('Node')
	else
 		class_name = node.class.simple_name
	end
	if LightModels::Js.const_defined? class_name
		model_class = LightModels::Js.const_get(class_name)
		#puts "* model_class: #{model_class}"

		model = model_class.new

		model_class.ecore.eAllReferences.each do |ref|		
			method = reference_to_method(model_class,ref)	
			raise "Node #{node} (#{node.class}) do not have property '#{ref.name}'. It was mapped to #{model_class}" unless node.respond_to?(method)
			node_ref_value = node.send(method)
			#puts "#{ref.name} = #{node_ref_value}"
			assign_ref_to_model(model,ref,node_ref_value)
		end

		model_class.ecore.eAllAttributes.each do |att|			
			method = attribute_to_method(model_class,att)
			unless node.respond_to?(method)
				method_boolean = :"#{method}?"
				if node.respond_to?(method_boolean)
					method = method_boolean
				else
					raise "Node #{node} (#{node.class}) do not have attributey '#{att.name}'. It was mapped to #{model_class}" unless node.respond_to?(method)
				end
			end			
			node_att_value = node.send(method)
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

end