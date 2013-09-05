require 'test/unit'
require 'js-lightmodels'
require 'test_helper'
 
class TestParsingTree < Test::Unit::TestCase

	include TestHelper
	include JsLightmodels

	def test_the_root_is_parsed
		code = "for(var i = 0; i < 10; i++) { var x = 5 + 5; }"
		r = JsLightmodels.parse(code)
		assert_class For, r
	end

	def test_for
		code = "for(var i = 0; i < 10; i++) { var x = 5 + 5; }"
		r = JsLightmodels.parse(code)
		assert_class For, r
		assert_class VarStatement, r.init
		assert_class Less, r.test
		assert_class Postfix, r.counter
		assert_class Block, r.body
	end

	def test_var_statement
		r = JsLightmodels.parse("var i = 0;")
		assert_class VarStatement, r
		assert_class VarDecl, r.decl
		assert_equal 'i', r.decl.name
		assert_class AssignExpr, r.decl.value
		assert_class Number, r.decl.value.value
		assert_equal 0, r.decl.value.value.value
	end

	def test_less
		r = JsLightmodels.parse("i < 10;")
		assert_class ExpressionStatement, r
		assert_class Less, r.expression
		assert_class Number, r.expression.right
		assert_equal 10, r.expression.right.value
		assert_class Resolve, r.expression.left
		assert_equal 'i', r.expression.left.id
	end

	def test_postfix
		r = JsLightmodels.parse("i++;")
		assert_class ExpressionStatement, r
		assert_class Postfix, r.expression
		assert_class Resolve, r.expression.operand
		assert_equal "++", r.expression.operator
	end

	def test_block
		r = JsLightmodels.parse("{ var x = 5 + 5; }")
		assert_class Block, r
		assert_class SourceElements, r.body
		assert_equal 1, r.body.contents.count
		assert_class VarStatement,r.body.contents[0]
	end

end