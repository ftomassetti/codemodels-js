require 'test_helper'
 
class TestBasicNodeProperties < Test::Unit::TestCase

	include TestHelper
	include LightModels
	include LightModels::Js

	def test_node_has_expected_basic_properties
		r = Js.parse_code("i < 10;")
		assert r.respond_to?(:source)
		assert r.respond_to?(:language)
		assert_equal LightModels::Js::LANGUAGE,r.language
	end	

end