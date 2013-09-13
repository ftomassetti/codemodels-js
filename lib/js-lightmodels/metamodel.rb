require 'rgen/metamodel_builder'

# TODO move some stuff to the lightmodels module

module LightModels

module Js

	class << self
		attr_accessor :verbose
	end

	verbose = false

	java_import 'org.mozilla.javascript.ast.AstNode'

	JavaString    = ::Java::JavaClass.for_name("java.lang.String")
	JavaList      = ::Java::JavaClass.for_name("java.util.List")
	JavaSortedSet = ::Java::JavaClass.for_name("java.util.SortedSet")
	JavaBoolean   = ::Java::boolean.java_class
	JavaInt 	  = ::Java::int.java_class
	JavaDouble 	  = ::Java::double.java_class
	JavaCollectionTypes = [JavaList,JavaSortedSet]

	MappedAstClasses = {}

	def self.get_metaclass_by_name(name)
		return JsNode if is_base_class?(name)
		k = MappedAstClasses.keys.find{|k| k.name==name}
		MappedAstClasses[k]
	end

	def self.is_base_class?(name)
		# Object is here because of Symbol, which does not extenf Node
		['org.mozilla.javascript.Node','org.mozilla.javascript.ast.AstNode','java.lang.Object'].include? name
	end

	# Works with both Java and Ruby type
	def self.get_att_type(type)
		return type if [String,RGen::MetamodelBuilder::DataTypes::Boolean,Integer,Float].include?(type)
		return String if type.respond_to?(:enum?) and type.enum?		
		case type
		when JavaString
			String
		when JavaBoolean
			RGen::MetamodelBuilder::DataTypes::Boolean
		when JavaInt
			Integer
		when JavaDouble
			Float				
		else
			nil
		end
	end

	def self.add_many_ref_or_att(c,type_name,prop_name,ast_name)
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

	def self.rhino_node_class(name)
		java_class = ::Java::JavaClass.for_name("org.mozilla.javascript.ast.#{name}")
	end

	def self.metasuperclass(java_super_class)
		if is_base_class?(java_super_class.name)				
			JsNode
		else
			raise "Super class #{java_super_class.name} not found, it should be wrapped before the classes extending it!" unless MappedAstClasses[java_super_class]
			MappedAstClasses[java_super_class]
		end
	end

	def self.add_feature(c,name,type,multiplicity)
		return unless type # type nil means to ignore the feature
		method = if Js.get_att_type(type)
			multiplicity==:many ? :has_many_attr : :has_attr
		else
			multiplicity==:many ? :contains_many_uni : :contains_one_uni
		end
		c.send(method,name,type)
	end

	def self.wrap(ast_names)		
		# first create all the classes
		ast_names.each do |ast_name|
			ast_java_class   = rhino_node_class(ast_name)
			meta_super_class = metasuperclass(ast_java_class.superclass)			
			meta_class       = Class.new(meta_super_class)
			
			raise "Already mapped! #{ast_name}" if MappedAstClasses[ast_java_class]
			MappedAstClasses[ast_java_class] = meta_class
			
			Js.const_set ast_java_class.simple_name, meta_class
		end

		# then add all the properties and attributes
		ast_names.each do |ast_name|
			java_class = rhino_node_class(ast_name)
			ast_class  = java_class.ruby_class
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
				ast_class.java_class.declared_instance_methods.select { |m| Js.getter?(m) }.each do |m|
					prop_name = LightModels::Js.property_name(m)
					unless to_ignore.include?(prop_name)
						if PROP_ADAPTERS[ast_class.simple_name.to_sym][prop_name.to_sym]	
							#puts "Adapting #{ast_class.simple_name} #{prop_name}"					
							adapter = PROP_ADAPTERS[ast_class.simple_name.to_sym][prop_name.to_sym]
							#puts "Type of adapter = #{adapter[:type]==nil}"
							Js.add_feature(c,prop_name,adapter[:type],adapter[:multiplicity])
						elsif Js.get_att_type(m.return_type)
							# the type is simple (-> attribute)
							has_attr prop_name, Js.get_att_type(m.return_type)
						elsif MappedAstClasses.has_key?(m.return_type)
							# the type is complex (-> reference)
							contains_one_uni prop_name, MappedAstClasses[m.return_type]
						elsif JavaCollectionTypes.include?(m.return_type)							
							type_name = LightModels::Js.get_generic_param_name(m.to_generic_string)
							LightModels::Js.add_many_ref_or_att(c,type_name,prop_name,ast_name)
						elsif m.return_type.array?
							LightModels::Js.add_many_ref_or_att(c,m.return_type.component_type.name,prop_name,ast_name)
						elsif Js.is_base_class?(m.return_type.name)
							#puts "#{ast_class.simple_name} #{prop_name} is base type"		
							contains_one_uni prop_name, JsNode
						else
							raise "#{ast_name}) Property (single) '#{prop_name}' is else: #{m.return_type}"
						end
					end
				end
			end
		end
	end

	def self.getter?(java_method)
		(java_method.name.start_with?('get')||java_method.name.start_with?('is')) and java_method.argument_types.count==0		
	end

	def self.get_corresponding_metaclass(node_class)
		name = simple_java_class_name(node_class)
		Js.const_get(name)
	end

	class JsNode < RGen::MetamodelBuilder::MMBase
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

  	def self.get_generic_param_name(generic_str)
  		type_name = nil
  		collections = JavaCollectionTypes.select{|ct|ct.name}  		
  		collections.each do |c|
  			prefixes = ["public #{c}<","public final #{c}<"]
  			prefixes.each do |p|
				type_name = generic_str.remove_prefix(p) if generic_str.start_with?(p)  			
				last = type_name.index '>'
				type_name = type_name[0..last-1] if last
			end
  		end
  		raise "I don't know how to get the generic param from '#{generic_str}'" unless type_name
  		type_name
  	end  	

	PROP_ADAPTERS = Hash.new {|h,k| h[k] = {} }

	def self.get_feature_value_through_getter(node,feat_name)
		capitalized_name = feat_name.proper_capitalize
		methods = [:"get#{capitalized_name}",:"is#{capitalized_name}"]

		methods.each do |m|
			if node.respond_to?(m)
				begin
					return node.send(m)
				rescue Object => e
					raise "Problem invoking #{m} on #{node.class}: #{e}"
				end
			end
		end
		raise "how should I get this... #{feat_name} on #{node.class}. It does not respond to #{methods}"
	end

	# If the feature is inherite I need to look among my super classes for
	# adapters
	def self.get_adapter(node_class,feat_name)
		class_name = simple_java_class_name(node_class)
		adapter = PROP_ADAPTERS[class_name.to_sym][feat_name.to_sym]
		return adapter if adapter
		# TODO stop at RGen::MetamodelBuilder::MMBase
		return get_adapter(node_class.superclass,feat_name) if node_class.superclass
		nil
	end

	def self.get_feature_value(node,feat_name)
		adapter = get_adapter(node.class,feat_name)		
		if adapter
			#puts "Using adapter for #{node.class} #{feat_name}"
			adapter[:adapter].call(node)
		else
			get_feature_value_through_getter(node,feat_name)
		end
	end

	def self.record_prop_adapter(node_type,prop_name,prop_type,&adapter)
		PROP_ADAPTERS[node_type][prop_name]   = {type: prop_type, multiplicity: :single, adapter: adapter}
	end

	def self.ignore_prop(node_type,prop_name)
		record_prop_adapter(node_type,prop_name,nil)
	end

	java_import 'org.mozilla.javascript.Token'

	record_prop_adapter(:Symbol,:declType,String) do |node|
		declTypeCode = node.send(:getDeclType)
		%w(FUNCTION LP VAR LET CONST).each do |name|
			return name if (declTypeCode == Token.get_const(name))
		end
		raise "Unexpected value: #{declTypeCode}"
	end

	record_prop_adapter(:InfixExpression,:operator,String) do |node|
		operator_code = node.send(:getType)
		begin
			AstNode::operatorToString(operator_code)		
		rescue
			puts "I can not get the operator for node #{node.class} (value: #{operator_code})" if verbose
			nil
		end
	end

	ignore_prop(:PropertyGet,:target)  # alias for left
	ignore_prop(:PropertyGet,:property) # alias for right	

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