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

end