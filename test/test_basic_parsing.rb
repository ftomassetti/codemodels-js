require 'test/unit'
require 'lightmodels'
require 'js-lightmodels'
require 'test_helper'
 
class TestBasicParsing < Test::Unit::TestCase

	include TestHelper
	include LightModels
	include LightModels::Js

	def test_block
		code = "{ var x = 5 + 5; }"
		model = Js.parse_code(code)
		assert model.is_a?(AstRoot)
		assert_equal 1,model.statements.count
		assert model.statements[0].is_a?(Scope)
	end

	def test_while_statements_empty
		code = "while (true) {  }"
		model = Js.parse_code(code).statements[0]
		assert_class WhileLoop, model
		assert_equal 0,model.body.statements.count
	end

	def test_while_statements_one_element
		code = "while (true) { i++; }"
		model = Js.parse_code(code).statements[0]
		assert_class WhileLoop, model
		assert_equal 1,model.body.statements.count
	end

	def test_bitwise_not_operator
		code = "~1"
		model = Js.parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class BitwiseNotOperator, model.expression
	end

	def test_not_operator
		code = "!true"
		model = Js.parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class NotOperator, model.expression
	end	

	def test_equals_infix_expr
		code = "1==1"
		model = Js.parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class EqualsInfixExpression, model.expression
	end	

	def test_identity_infix_expr
		code = "1===1"
		model = Js.parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class IdentityInfixExpression, model.expression
	end		

	def test_not_identity_infix_expr
		code = "1!==1"
		model = Js.parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class NotIdentityInfixExpression, model.expression
	end		

	def test_logic_and_infix_expr
		code = "1&&1"
		model = Js.parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class LogicAndInfixExpression, model.expression
	end	

	def test_logic_or_infix_expr
		code = "1||1"
		model = Js.parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class LogicOrInfixExpression, model.expression
	end		

	def test_unary_plus
		code = "+1"
		model = Js.parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class UnaryPlusOperator, model.expression
	end				

	def test_unary_minus
		code = "-1"
		model = Js.parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class UnaryMinusOperator, model.expression
	end			

end