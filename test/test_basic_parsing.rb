# encoding: UTF-8
require 'test_helper'
 
class TestBasicParsing < Test::Unit::TestCase

	include TestHelper
	include CodeModels
	include CodeModels::Js

	def test_block
		code = "{ var x = 5 + 5; }"
		model = parse_code(code)
		assert model.is_a?(AstRoot)
		assert_equal 1,model.statements.count
		assert model.statements[0].is_a?(Scope)
	end

	def test_while_statements_empty
		code = "while (true) {  }"
		model = parse_code(code).statements[0]
		assert_class WhileLoop, model
		assert_equal 0,model.body.statements.count
	end

	def test_while_statements_one_element
		code = "while (true) { i++; }"
		model = parse_code(code).statements[0]
		assert_class WhileLoop, model
		assert_equal 1,model.body.statements.count
	end

	def test_bitwise_not_operator
		code = "~1"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class BitwiseNotOperator, model.expression
	end

	def test_not_operator
		code = "!true"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class NotOperator, model.expression
	end	

	def test_equals_infix_expr
		code = "1==1"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class EqualsInfixExpression, model.expression
	end	

	def test_identity_infix_expr
		code = "1===1"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class IdentityInfixExpression, model.expression
	end		

	def test_not_identity_infix_expr
		code = "1!==1"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class NotIdentityInfixExpression, model.expression
	end		

	def test_not_equals_infix_expr
		code = "1!=1"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class NotEqualsInfixExpression, model.expression
	end	

	def test_sub_expression_position
		code = "1!=1"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class NotEqualsInfixExpression, model.expression
		assert_class Js::NumberLiteral, model.expression.left
		assert_class Js::NumberLiteral, model.expression.right
		assert_equal SourcePoint.new(1,1),model.expression.left.source.position.begin_point
		assert_equal SourcePoint.new(1,1),model.expression.left.source.position.end_point
		assert_equal SourcePoint.new(1,4),model.expression.right.source.position.begin_point
		assert_equal SourcePoint.new(1,4),model.expression.right.source.position.end_point
	end		

	def test_logic_and_infix_expr
		code = "1&&1"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class LogicAndInfixExpression, model.expression
	end	

	def test_logic_or_infix_expr
		code = "1||1"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class LogicOrInfixExpression, model.expression
	end		

	def test_unary_plus
		code = "+1"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class UnaryPlusOperator, model.expression
	end				

	def test_unary_minus
		code = "-1"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class UnaryMinusOperator, model.expression
	end	

	def test_comma_infix_expr
		code = "1,2"
		model = parse_code(code).statements[0]
		assert_class ExpressionStatement, model
		assert_class CommaInfixExpression, model.expression
	end		

	def test_empty_stmt
		code = ";"
		model = parse_code(code).statements[0]
		assert_class EmptyStatement, model
	end		

	def test_switch_stmt
		code = %q{
			switch (1) { 
				case 2: 
					3; 
					break;
				case 4: 
					5; 
					break;
				default:
					6;
			}
		}
		model = parse_code(code).statements[0]
		assert_class SwitchStatement, model
		assert_class NumberLiteral, model.expression
		assert_equal 3, model.cases.count
		assert_class ExpressionSwitchCase, model.cases[0]
		assert_class ExpressionSwitchCase, model.cases[1]
		assert_class DefaultSwitchCase, 	  model.cases[2]
	end			

end