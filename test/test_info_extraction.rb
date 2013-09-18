require 'test/unit'
require 'lightmodels'
require 'js-lightmodels'
require 'test_helper'
 
class TestInfoExtraction < Test::Unit::TestCase

	include TestHelper
	include LightModels

	def assert_map(exp,map)
		# ignore boolean values...
		#map.delete true
		#map.delete false

		assert_equal exp.count,map.count, "Expected to have keys: #{exp.keys}, it has #{map}"
		exp.each do |k,v|
			assert_equal exp[k],map[k], "Expected #{k} to have #{exp[k]} instances, it has #{map[k.to_s]}. Map: #{map}"
		end
	end

	def assert_code_map_to(code,exp)
		r = Js.parse_code(code)
		ser = LightModels::Serialization.jsonize_obj(r)
		#puts "Code <<<#{code}>>> -> #{JSON.pretty_generate(ser)}"
		map = LightModels::QuerySerialized.collect_values_with_count(ser)
		assert_map(exp,map)
	end

	def test_info_the_root_is_parsed
		code = "for(var i = 0; i < 10; i++) { var x = 5 + 5; }"
		assert_code_map_to(code, {'i'=> 3, 0.0 => 1, 5.0 => 2, 10.0=> 1, 'x' => 1})
	end

	def test_info_var_statement
		code = "var i = 0;"
		assert_code_map_to(code, {'i'=> 1, 0.0 => 1})
	end

	def test_info_less
		code = "i < 10;"
		assert_code_map_to(code, {'i'=> 1, 10.0 => 1})
	end

	def test_info_postfix
		code = "i++;"
		assert_code_map_to(code, {'i'=> 1})
	end

	def test_info_block
		code = "{ var x = 5 + 5; }"
		assert_code_map_to(code, {'x'=> 1, 5.0 => 2})		
	end

	def test_snippet_1
		code = "var lowercase = function(string){return isString(string) ? string.toLowerCase() : string;};"
		assert_code_map_to(code, {'lowercase'=> 1, 'string' => 4, 'isString' => 1, 'toLowerCase' => 1})
	end

	def test_snippet_2
		code = %q{
			var manualLowercase = function(s) {
			  return isString(s)
			      ? s.replace(/[A-Z]/g, function(ch) {return String.fromCharCode(ch.charCodeAt(0) | 32);})
			      : s;
			};
			var manualUppercase = function(s) {
			  return isString(s)
			      ? s.replace(/[a-z]/g, function(ch) {return String.fromCharCode(ch.charCodeAt(0) & ~32);})
			      : s;
			};
		}
		assert_code_map_to(code, {
			'manualLowercase'=> 1, 'manualUppercase'=>1,
			's' => 8, 'isString' => 2, 'replace' => 2, 
			'[A-Z]'=>1, '[a-z]'=>1,
			'g'=>2, # this is the flag, it should be removed from the AST in the future
			'ch'=>4, 'String'=>2,
			'fromCharCode'=>2, 'charCodeAt'=>2, 
			0.0=>2, 32.0=>2})
	end

end