require 'test/unit'
require 'js-lightmodels'
require 'test_helper'
 
class TestParsingTree < Test::Unit::TestCase

	include TestHelper
	include LightModels::Js

	def test_the_root_is_parsed
		code = "for(var i = 0; i < 10; i++) { var x = 5 + 5; }"
		r = JsLightmodels.parse(code)
		map = Lightmodels::Serialization.jsonize_obj(r)
		Lightmodels::Query.collect_values_with_count(r)
		assert_equal 4,map.count
		assert_equal 3,map['i']
		assert_equal 1,map[0]
		assert_equal 2,map[5]
		assert_equal 1,map[10]
	end

	def test_for
		code = "for(var i = 0; i < 10; i++) { var x = 5 + 5; }"
		r = JsLightmodels.parse(code)
		
	end

	def test_var_statement
		r = JsLightmodels.parse("var i = 0;")
		
	end

	def test_less
		r = JsLightmodels.parse("i < 10;")
		
	end

	def test_postfix
		r = JsLightmodels.parse("i++;")
		
	end

	def test_block
		r = JsLightmodels.parse("{ var x = 5 + 5; }")
		
	end

end