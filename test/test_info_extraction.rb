require 'test/unit'
require 'lightmodels'
require 'js-lightmodels'
require 'test_helper'
 
class TestInfoExtraction < Test::Unit::TestCase

	include TestHelper
	include LightModels

	def assert_map(exp,map)
		# ignore boolean values...
		map.delete true
		map.delete false

		assert_equal exp.count,map.count, "Expected to have keys: #{exp.keys}, it has #{map.keys}"
		exp.each do |k,v|
			assert_equal exp[k],v, "Expected #{k} to have #{exp[k]} instances, it has #{map[k]}"
		end
	end

	def assert_code_map_to(code,exp)
		r = Js.parse_code(code)
		ser = LightModels::Serialization.jsonize_obj(r)
		map = LightModels::Query.collect_values_with_count(ser)
		assert_map(exp,map)
	end

	def test_info_the_root_is_parsed
		code = "for(var i = 0; i < 10; i++) { var x = 5 + 5; }"
		assert_code_map_to(code, {'i'=> 3, 0 => 1, 5 => 2, 10 => 1, '++' => 1, 'x' => 1})
	end

	def test_info_var_statement
		code = "var i = 0;"
		assert_code_map_to(code, {'i'=> 1, 0 => 1})
	end

	def test_info_less
		code = "i < 10;"
		assert_code_map_to(code, {'i'=> 1, 10 => 1})
	end

	def test_info_postfix
		code = "i++;"
		assert_code_map_to(code, {'i'=> 1, '++' => 1})
	end

	def test_info_block
		code = "{ var x = 5 + 5; }"
		assert_code_map_to(code, {'x'=> 1, 5 => 2})		
	end

end