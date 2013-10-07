require 'codemodels'
require 'codemodels/js/metamodel'

module CodeModels
module Js

class Parser < CodeModels::Parser

	attr_accessor :skip_unknown_node

	def parse_file(path)
		content = IO.read(path)
		self.parse_code(content,path)
	end

	def parse_code(code,filename='<code>')
		java_import 'java.io.StringReader'
		java_import 'org.mozilla.javascript.CompilerEnvirons'
		rhino_parser = (java_import 'org.mozilla.javascript.Parser')[0]
		env = CompilerEnvirons.new
		parser = rhino_parser.new(env)
		reader = StringReader.new(code)

		tree = parser.parse(reader, filename, 1)
		tree_to_model(tree,code)
	end

	def tree_to_model(tree,code)
		node_to_model(tree,code)
	end

	private

	def adapter_specific_class(model_class,ref)
		return nil unless CodeModels::Js::ParsingAdapters[model_class]
		CodeModels::Js::ParsingAdapters[model_class][ref.name]
	end

	# TODO remove code below, moved to CodeModels

	def adapter(model_class,ref)
		if CodeModels::Js::ParsingAdapters[model_class] && CodeModels::Js::ParsingAdapters[model_class][ref.name]
			CodeModels::Js::ParsingAdapters[model_class][ref.name]
		else
			if model_class.superclass!=Object
				adapter(model_class.superclass,ref) 
			else
				nil
			end
		end
	end

	def reference_to_method(model_class,ref)
		s = ref.name
		adapted = adapter(model_class,ref)
		s = adapted if adapted		
		s.to_sym
	end

	def attribute_to_method(model_class,att)
		s = att.name
		adapted = adapter(model_class,att)
		s = adapted if adapted		
		s.to_sym
	end

	def assign_ref_to_model(model,ref,value,code)
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

	def assign_att_to_model(model,att,value)
		if att.many
			adder_method = :"add#{att.name.capitalize}"
			value.each {|el| model.send(adder_method,el)}
		else
			setter_method = :"#{att.name}="
			raise "Trying to assign an array to a single property. Class #{model.class}, property #{att.name}" if value.is_a?(::Array)
			model.send(setter_method,value)
		end
	end

	def populate_attr(node,att,model)	
		raise "Error: the attribute has no name" unless att.name
		value = Js.get_feature_value(node,att.name,model)
		model.send(:"#{att.name}=",value) if value!=nil
	end

	def populate_ref(node,ref,model,code)
		value = Js.get_feature_value(node,ref.name,model)
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

	def assign_attr_value(model,prop_name,value)
		if value.is_a?(Java::JavaUtil::Collection)
			capitalized_name = prop_name.proper_capitalize	
			value.each do |el|
				model.send(:"add#{capitalized_name}",el)
			end
		else
			model.send(:"#{ref.name}=",value)
		end
	end

	def assign_ref_value(model,prop_name,value,code)
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

	def newlines(code,start_pos,end_pos)
		piece = code[start_pos..end_pos]
		piece.lines.count
	end

	def column_last_char(code,start_pos,end_pos)
		piece = code[start_pos..end_pos]
		last_line = nil
		piece.lines.each{|l| last_line=l}
		last_line.length
	end

	def node_to_model(node,code)
		metaclass = Js.get_corresponding_metaclass(node)
		instance = metaclass.new

		instance.language = LANGUAGE
		instance.source = CodeModels::SourceInfo.new

		bp = node.getAbsolutePosition
		ep = node.getAbsolutePosition+node.length

		class << instance.source
			attr_accessor :code
			def to_code
				@code
			end
		end
		instance.source.code = code[bp..ep]

		instance.source.begin_point = { line: node.lineno, column: node.position+1 }
		instance.source.end_point   = { line: node.lineno+newlines(code,bp,ep)-1, column: column_last_char(code,bp,ep) }

		metaclass.ecore.eAllAttributes.each do |attr|
			unless Js.additional_property?(node.class,attr.name)
				populate_attr(node,attr,instance)
			end
		end
		metaclass.ecore.eAllReferences.each do |ref|
			unless Js.additional_property?(node.class,ref.name)
				populate_ref(node,ref,instance,code)
			end
		end
		# check for added properties
		Js.additional_properties(node.class).each do |prop_name,prop_data|
			value = prop_data[:getter].call(node)
			if Js.get_att_type(prop_data[:prop_type])
				assign_attr_value(instance,prop_name.to_s,value)
			else
				assign_ref_value(instance,prop_name.to_s,value,code)
			end
		end
		instance
	end

end # class Parser

DefaultParser = Parser.new

ExpressionParser = Parser.new

class << ExpressionParser
	def parse_code(code)
		res = super("a=#{code};")
		root = res.statements[0].expression.right
		root.eContainer = nil
		root
	end
end

def self.parse_code(code)
	DefaultParser.parse_code(code)
end

def self.parse_file(path)
	DefaultParser.parse_file(path)
end

end
end