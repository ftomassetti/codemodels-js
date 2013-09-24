require 'test_helper'
 
class TestInfoExtraction < Test::Unit::TestCase

	include TestHelper
	include LightModels
	include LightModels::Js
	include RGen::ECore

	# TODO ArrayComprehension
	# TODO ArrayComprehensionLoop

	def test_ast_root
		c = assert_metamodel :AstRoot, [], ['statements']

		assert_ref c, 'statements', JsNode, true
	end

	def test_array_literal
		assert Js.const_defined? :ArrayLiteral
		c = Js.const_get :ArrayLiteral

		assert_all_attrs [],              c
		assert_all_refs  ['elements'],    c

		assert_ref c,'elements',JsNode,true
	end

	def test_block
		assert Js.const_defined? :Block
		c = Js.const_get :Block

		assert_all_attrs [],              c
		assert_all_refs  ['contents'],    c

		assert_ref c,'contents',JsNode,true
	end

	def test_break
		assert Js.const_defined? :BreakStatement
		c = Js.const_get :BreakStatement

		# TODO break label and break target maybe should be there
		assert_all_attrs [], c
		assert_all_refs  ['breakLabel'], c		

		assert_ref c,'breakLabel',Name
	end

	def test_catch_clause
		c = assert_metamodel :CatchClause, [], ['varName', 'catchCondition','body']

		assert_ref c,'varName',Name
		assert_ref c,'catchCondition',JsNode
		assert_ref c,'body',Block
	end

	def test_conditional_expression
		c = assert_metamodel :ConditionalExpression, [], ['testExpression','trueExpression','falseExpression']

		assert_ref c,'testExpression',JsNode
		assert_ref c,'trueExpression',JsNode
		assert_ref c,'falseExpression',JsNode
	end

	def test_continue_statement
		c = assert_metamodel :ContinueStatement, [], ['label']

		assert_ref c,'label',Name
	end

	def test_do_loop
		c = assert_metamodel :DoLoop, [], ['body','condition']

		assert_ref c,'body',JsNode
		assert_ref c,'condition',JsNode
	end

	def test_function_call
		c = assert_metamodel :FunctionCall, [], ['target','arguments']

		assert_ref c,'target',JsNode
		assert_ref c,'arguments',JsNode, true
	end

	def test_get_object_property
		c = assert_metamodel :GetObjectProperty, [], ['name','value']

		assert_ref c,'name',JsNode
		assert_ref c,'value',JsNode
	end		

	def test_infix_expression
		assert Js.const_defined? :InfixExpression
		c = Js.const_get :InfixExpression

		assert_all_attrs [],               c
		assert_all_refs  ['left','right'], c

		assert_ref c,'left',JsNode
		assert_ref c,'right',JsNode	
	end

	def test_js_node
		assert Js.const_defined? :JsNode
		c = Js.const_get :JsNode

		assert_all_attrs [], c
		assert_all_refs  [], c
	end

	def test_loop
		c = assert_metamodel :Loop, [], ['body']

		assert_ref c,'body',JsNode
	end	

	def test_new_expression
		c = assert_metamodel :NewExpression, [], ['initializer','target','arguments']

		assert_ref c,'initializer',ObjectLiteral		
		assert_ref c,'target',JsNode
		assert_ref c,'arguments',JsNode, true
	end

	def test_number_literal
		c = assert_metamodel :NumberLiteral, ['number'], []

		assert_attr c,'number',EFloat
	end

	def test_object_literal
		c = assert_metamodel :ObjectLiteral, [], ['elements']

		assert_ref c,'elements',ObjectProperty,true
	end	

	def test_object_property
		c = assert_metamodel :ObjectProperty, [], ['name','value']

		assert_ref c,'name',JsNode
		assert_ref c,'value',JsNode
	end	

	def test_property_get
		assert Js.const_defined? :PropertyGet
		c = Js.const_get :PropertyGet

		assert_all_attrs [],     c
		assert_all_refs  ['left','right'], c

		assert_equal 0,c.ecore.eAttributes.count
		assert_equal 0,c.ecore.eReferences.count
	end

	def test_set_object_property
		c = assert_metamodel :SetObjectProperty, [], ['name','value']

		assert_ref c,'name',JsNode
		assert_ref c,'value',JsNode
	end		

	def test_simple_object_property
		c = assert_metamodel :SimpleObjectProperty, [], ['name','value']

		assert_ref c,'name',JsNode
		assert_ref c,'value',JsNode
	end		

	def test_scope
		c = assert_metamodel :Scope, [], ['statements']

		assert_ref c,'statements',JsNode, true
	end	

	def test_symbol
		assert Js.const_defined? :Symbol
		c = Js.const_get :Symbol

		assert_attr c,'declType',EString
	end

	def test_while_loop
		c = assert_metamodel :WhileLoop, [], ['body','condition']

		assert_ref c,'body',JsNode
		assert_ref c,'condition',JsNode
	end

	def test_switch_statement
		c = assert_metamodel :SwitchStatement, [], ['expression','cases']

		assert_ref c,'expression',JsNode
		assert_ref c,'cases',SwitchCase,true		
	end

	def test_expression_switch_case
		c = assert_metamodel :ExpressionSwitchCase, [], ['expression','statements']

		assert_ref c,'expression',JsNode
		assert_ref c,'statements',JsNode, true
	end

	def test_default_switch_case
		c = assert_metamodel :DefaultSwitchCase, [], ['statements']

		assert_ref c,'statements',JsNode, true
	end	

end