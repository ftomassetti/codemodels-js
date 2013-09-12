require 'rgen/metamodel_builder'

class String
	def remove_postfix(postfix)
		raise "'#{self}'' have not the right postfix '#{postfix}'" unless end_with?(postfix)
		self[0..-(1+postfix.length)]
	end

	def remove_prefix(prefix)
		raise "'#{self}'' have not the right prefix '#{prefix}'" unless start_with?(prefix)
		self[prefix.length..-1]
	end

	def uncapitalize 
    	self[0, 1].downcase + self[1..-1]
  	end
end	

module LightModels

module Js

	JavaString  = ::Java::JavaClass.for_name("java.lang.String")
	JavaList    = ::Java::JavaClass.for_name("java.util.List")
	JavaBoolean = ::Java::boolean.java_class
	JavaInt = ::Java::int.java_class
	JavaDouble = ::Java::double.java_class
	JavaArray = ::Java::int.java_class

	MappedAstClasses = {}

	def self.add_many_ref_or_att(c,type_name,prop_name,ast_name)
		#puts "type_name: #{type_name}"
		last = type_name.index '>'
		type_name = type_name[0..last-1] if last
		type_ast_class = MappedAstClasses.keys.find{|k| k.name==type_name}
		rgen_class = MappedAstClasses[type_ast_class]
		if type_name=='org.mozilla.javascript.Node' or type_name=='org.mozilla.javascript.ast.AstNode'
			rgen_class = RGen::MetamodelBuilder::MMBase
		end
		if rgen_class
			c.class_eval do
				contains_many_uni prop_name, rgen_class
			end
		else
			if type_name==JavaString.name
				c.class_eval { has_many_attr prop_name, String }
			elsif type_name==JavaBoolean.name
				c.class_eval { has_many_attr prop_name, RGen::MetamodelBuilder::DataTypes::Boolean }
			elsif type_name==JavaInt.name
				c.class_eval { has_many_attr prop_name, Integer }
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
					elsif m.return_type==JavaString
						has_attr prop_name, String
					elsif m.return_type==JavaBoolean
						has_attr prop_name, RGen::MetamodelBuilder::DataTypes::Boolean
					elsif m.return_type==JavaInt
						has_attr prop_name, Integer
					elsif m.return_type==JavaDouble
						has_attr prop_name, Float						
					elsif MappedAstClasses.has_key?(m.return_type)
						contains_one_uni prop_name, MappedAstClasses[m.return_type]
					elsif m.return_type==JavaList
	#					puts "Property #{prop_name} is a list"
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
					#type = nil
					#contains_one_uni prop_name, type
				end
			end
		end
	end

	def self.get_corresponding_metaclass(node_class)
		name = simple_java_class_name(node_class)
		return Js.const_get(name)
	end

	private

	def self.property_name(java_method)
		return java_method.name.remove_prefix('get').uncapitalize if java_method.name.start_with?('get')
		return java_method.name.remove_prefix('is').uncapitalize if java_method.name.start_with?('is')
	end

	def self.simple_java_class_name(java_class)
		name = java_class.name
    	if (i = (r = name).rindex(':')) then r[0..i] = '' end
    	r
  	end

  	def self.get_generic_param(generic_str)
  		return generic_str.remove_prefix('public java.util.List<') if generic_str.start_with?('public java.util.List<')
  		return generic_str.remove_prefix('public final java.util.List<') if generic_str.start_with?('public final java.util.List<')
  		nil
  	end

  	def self.declared_methods(java_class)

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