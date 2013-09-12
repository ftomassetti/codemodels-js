require 'rgen/metamodel_builder'

# TODO move some stuff to the lightmodels module

class String
	def remove_postfix(postfix)
		raise "'#{self}'' have not the right postfix '#{postfix}'" unless end_with?(postfix)
		self[0..-(1+postfix.length)]
	end

	def remove_prefix(prefix)
		raise "'#{self}'' have not the right prefix '#{prefix}'" unless start_with?(prefix)
		self[prefix.length..-1]
	end
	
	def proper_capitalize 
    	self[0, 1].upcase + self[1..-1]
  	end

	def proper_uncapitalize 
    	self[0, 1].downcase + self[1..-1]
  	end

end	

module LightModels

module Js

	JavaString  = ::Java::JavaClass.for_name("java.lang.String")
	JavaList    = ::Java::JavaClass.for_name("java.util.List")
	JavaBoolean = ::Java::boolean.java_class
	JavaInt 	= ::Java::int.java_class
	JavaDouble 	= ::Java::double.java_class
	JavaArray 	= ::Java::int.java_class

	MappedAstClasses = {}

	def self.polish_type_name(type_name)
		last = type_name.index '>'
		type_name = type_name[0..last-1] if last
		type_name
	end

	def self.get_metaclass_by_name(name)
		return RGen::MetamodelBuilder::MMBase if is_base_class?(name)
		k = MappedAstClasses.keys.find{|k| k.name==name}
		MappedAstClasses[k]
	end

	def self.is_base_class?(name)
		['org.mozilla.javascript.Node','org.mozilla.javascript.ast.AstNode'].include? name
	end

	def self.get_att_type(type_name)
		case type_name
		when JavaString.name
			String
		when JavaBoolean.name
			RGen::MetamodelBuilder::DataTypes::Boolean
		when JavaInt.name
			Integer
		when JavaDouble.name
			Float				
		else
			nil
		end
	end

	def self.add_many_ref_or_att(c,type_name,prop_name,ast_name)
		type_name = polish_type_name(type_name)
		rgen_class = get_metaclass_by_name(type_name)
		if rgen_class
			c.class_eval do
				contains_many_uni prop_name, rgen_class
			end
		else
			att_type = get_att_type(type_name)
			if type_name
				c.class_eval { has_many_attr prop_name, att_type } 
			else
				raise "#{ast_name}) Property (many) #{prop_name} is else: #{type_name}"
			end
		end
	end

	def self.wrap(ast_names)		
		# first create all the classes
		ast_names.each do |ast_name|
			if ast_name=='Node'
				java_class = ::Java::JavaClass.for_name("org.mozilla.javascript.#{ast_name}")
			else
				java_class = ::Java::JavaClass.for_name("org.mozilla.javascript.ast.#{ast_name}")
			end
			java_super_class = java_class.superclass
			if java_super_class.name == 'org.mozilla.javascript.ast.AstNode'
				super_class = RGen::MetamodelBuilder::MMBase
			elsif java_super_class.name == 'java.lang.Object'
				super_class = RGen::MetamodelBuilder::MMBase
			else
				raise "Super class #{java_super_class.name} of #{java_class.name}. It should be wrapped before!" unless MappedAstClasses[java_super_class]
				super_class = MappedAstClasses[java_super_class]
			end
			#puts "Java Super Class: #{java_super_class.name}"
			ast_class = java_class.ruby_class
			#puts "Class #{simple_java_class_name(ast_class)} extends #{super_class}"
			c = Class.new(super_class)
			raise "Already mapped! #{ast_name}" if MappedAstClasses[java_class]
			MappedAstClasses[java_class] = c
			Js.const_set simple_java_class_name(ast_class), c
		end

		# then add all the properties and attributes
		ast_names.each do |ast_name|
			java_class = ::Java::JavaClass.for_name("org.mozilla.javascript.ast.#{ast_name}")
			ast_class = java_class.ruby_class
			c = MappedAstClasses[java_class]
				
			to_ignore = %w( symbolTable compilerData comments liveLocals regexpString
				regexpFlags indexForNameNode paramAndVarCount paramAndVarNames
				paramAndVarConst jumpStatement finally loop default continue
				containingTable definingScope parentScope top quoteCharacter
				sourceName inStrictMode encodedSourceStart encodedSourceEnd
				baseLineno endLineno functionCount regexpCount paramCount nextTempName
				functions symbols childScopes encodedSource statement var const let
				destructuring localName scope number operatorPosition
			 )

			c.class_eval do
				ast_class.java_class.declared_instance_methods.select do |m| 
					(m.name.start_with?('get')||m.name.start_with?('is')) and m.argument_types.count==0					
				end.each do |m|

					prop_name = LightModels::Js.property_name(m)
					if to_ignore.include?(prop_name)
					#	puts "Skipping #{prop_name}"
					elsif Js.get_att_type(m.return_type.name)
						has_attr prop_name, Js.get_att_type(m.return_type.name)
					elsif MappedAstClasses.has_key?(m.return_type)
						contains_one_uni prop_name, MappedAstClasses[m.return_type]
					elsif m.return_type==JavaList
						type_name = LightModels::Js.get_generic_param(m.to_generic_string)
						LightModels::Js.add_many_ref_or_att(c,type_name,prop_name,ast_name)
					elsif m.return_type.array?
						LightModels::Js.add_many_ref_or_att(c,m.return_type.component_type.name,prop_name,ast_name)
					elsif m.return_type.enum?
						has_attr prop_name, String
					elsif m.return_type.name=='org.mozilla.javascript.Node' or m.return_type.name=='org.mozilla.javascript.ast.AstNode'
						contains_one_uni prop_name, RGen::MetamodelBuilder::MMBase					
					else
						raise "#{ast_name}) Property (single) '#{prop_name}' is else: #{m.return_type}"
					end
				end
			end
		end
	end

	def self.get_corresponding_metaclass(node_class)
		name = simple_java_class_name(node_class)
		Js.const_get(name)
	end

	private

	def self.property_name(java_method)
		return java_method.name.remove_prefix('get').proper_uncapitalize if java_method.name.start_with?('get')
		return java_method.name.remove_prefix('is').proper_uncapitalize if java_method.name.start_with?('is')
		raise "Error"
	end

	def self.simple_java_class_name(java_class)
		name = java_class.name
    	if (i = (r = name).rindex(':')) then r[0..i] = '' end
    	r
  	end

  	def self.get_generic_param(generic_str)
  		return generic_str.remove_prefix('public java.util.List<') if generic_str.start_with?('public java.util.List<')
  		return generic_str.remove_prefix('public final java.util.List<') if generic_str.start_with?('public final java.util.List<')
  		raise "Error"
  	end

  	wrap %w(
  		Symbol
  		Jump
  		Scope
  		ScriptNode
  		AstRoot
  		Name
  		Block
  		FunctionNode
  		ExpressionStatement
  		FunctionCall
  		ParenthesizedExpression
  		InfixExpression
  		PropertyGet
  		Assignment
  		ObjectLiteral
  		ObjectProperty
  		KeywordLiteral
  		ReturnStatement
  		UnaryExpression
  		ElementGet
  		IfStatement
  		StringLiteral
  		ArrayLiteral
  		Loop
  		ForLoop
  		ForInLoop
  		NumberLiteral
  		VariableInitializer
  		VariableDeclaration
  	)
	 
end

end