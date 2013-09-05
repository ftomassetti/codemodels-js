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
	node_to_model(tree)
end

def self.node_to_model(node)
	class_name = node.class.simple_name.remove_postfix('Node')
	if JsLightmodels.const_defined? class_name
		node_class = JsLightmodels.const_get(class_name)
		puts "Node #{node} -> #{node_class}"
		model = node_class.new
		model 
	else
		raise "Unknown node type: #{class_name}"
	end
end

end