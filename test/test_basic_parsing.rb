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

end