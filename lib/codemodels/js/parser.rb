# encoding: UTF-8
require 'codemodels'
require 'codemodels/js/metamodel'

module CodeModels
module Js

class Parser < CodeModels::Parser

	attr_accessor :skip_unknown_node

	def internal_parse_artifact(artifact)
		code = artifact.code
		name = artifact.name
		java_import 'java.io.StringReader'
		java_import 'org.mozilla.javascript.CompilerEnvirons'
		rhino_parser = (java_import 'org.mozilla.javascript.Parser')[0]
		env = CompilerEnvirons.new
		parser = rhino_parser.new(env)
		reader = StringReader.new(code)
		tree = parser.parse(reader, name, 1)
		tree_to_model(tree,code,artifact)		
	end

	def tree_to_model(tree,code,artifact,offset=0)
		node_to_model(tree,code,artifact,offset)
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

	def assign_ref_to_model(model,ref,value,code,artifact,offset)
		return unless value!=nil # we do not need to assign a nil...
		if ref.many
			adder_method = :"add#{ref.name.capitalize}"
			value.each {|el| model.send(adder_method,node_to_model(el,code,artifact,offset))}
		else
			setter_method = :"#{ref.name}="
			raise "Trying to assign an array to a single property. Class #{model.class}, property #{ref.name}" if value.is_a?(::Array)
			model.send(setter_method,node_to_model(value,code,artifact,offset))
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

	def populate_ref(node,ref,model,code,artifact,offset)
		value = Js.get_feature_value(node,ref.name,model)
		if value
			if value==node
				puts "avoiding loop... #{ref.name}, class #{node.class}" 
				return
			end
			if value.is_a?(Java::JavaUtil::Collection)
				capitalized_name = ref.name.proper_capitalize	
				value.each do |el|
					model.send(:"add#{capitalized_name}",node_to_model(el,code,artifact,offset))
				end
			else
				model.send(:"#{ref.name}=",node_to_model(value,code,artifact,offset))
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

	def assign_ref_value(model,prop_name,value,code,artifact,offset)
		if value.is_a?(Java::JavaUtil::Collection)
			capitalized_name = prop_name.proper_capitalize	
			value.each do |el|
				#begin
					model.send(:"add#{capitalized_name}",node_to_model(el,code,artifact,offset))
				#rescue Object=>e
				#	raise "Assigning prop #{prop_name} to #{model}: #{e}"
				#end
			end
		else
			model.send(:"#{ref.name}=",node_to_model(value,code,artifact,offset))
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

	def node_to_model(node,code,artifact,offset)
		metaclass = Js.get_corresponding_metaclass(node)
		instance = metaclass.new

		instance.language = LANGUAGE
		instance.source = CodeModels::SourceInfo.new

		bp = node.getAbsolutePosition
		ep = node.getAbsolutePosition+node.length-1

		instance.source.artifact = artifact
		instance.source.position = SourcePosition.from_code_indexes(code,bp,ep)
		instance.source.position.begin_point.column+=offset if instance.source.position.begin_point.line==1
		instance.source.position.end_point.column+=offset if instance.source.position.end_point.line==1

		metaclass.ecore.eAllAttributes.each do |attr|
			unless Js.additional_property?(node.class,attr.name)
				populate_attr(node,attr,instance)
			end
		end
		metaclass.ecore.eAllReferences.each do |ref|
			unless Js.additional_property?(node.class,ref.name)
				populate_ref(node,ref,instance,code,artifact,offset)
			end
		end
		# check for added properties
		Js.additional_properties(node.class).each do |prop_name,prop_data|
			value = prop_data[:getter].call(node)
			if Js.get_att_type(prop_data[:prop_type])
				assign_attr_value(instance,prop_name.to_s,value)
			else
				assign_ref_value(instance,prop_name.to_s,value,code,artifact,offset)
			end
		end
		instance
	end

end # class Parser

DefaultParser = Parser.new

ExpressionParser = Parser.new

class << ExpressionParser

	def parse_code(code,filename='<code>')
		parse_artifact(FileArtifact.new(filename,code))
	end

	def parse_artifact(artifact)
		enc = @internal_encoding || 'UTF-8'
		code = "a=#{artifact.code};".encode(enc)
		java_import 'java.io.StringReader'
		java_import 'org.mozilla.javascript.CompilerEnvirons'
		rhino_parser = (java_import 'org.mozilla.javascript.Parser')[0]
		env = CompilerEnvirons.new
		parser = rhino_parser.new(env)
		reader = StringReader.new(code)
		filename = '<code>'
		filename = artifact.filename if artifact.respond_to?(:filename)
		tree = parser.parse(reader, filename, 1)
		tree_to_model(tree.statements[0].expression.right,code,artifact,-2)		
	end

end

def self.parse_code(code)
	DefaultParser.parse_code(code)
end

def self.parse_file(path,encoding=nil)
	DefaultParser.parse_file(path,encoding)
end

end
end