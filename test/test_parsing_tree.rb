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
		assert_class VarDecl, r.body
		assert_equal 'i', r.body.name
		assert_class AssignExpr, r.body.body
		assert_class Number, r.body.body.body
		assert_equal 0, r.body.body.body.value
	end

	def test_less
		r = JsLightmodels.parse("i < 10;")
		assert_class ExpressionStatement, r
		assert_class Less, r.body
		assert_class Number, r.body.body
		assert_equal 10, r.body.body.value
		assert_class Resolve, r.body.left
		assert_equal 'i', r.body.left.value
	end

end