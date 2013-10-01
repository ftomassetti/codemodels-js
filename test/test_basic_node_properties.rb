require 'test_helper'
 
class TestBasicNodeProperties < Test::Unit::TestCase

	include TestHelper
	include CodeModels
	include CodeModels::Js

	def test_node_has_expected_basic_properties
		r = Js.parse_code("i < 10;")
		assert r.respond_to?(:source)
		assert r.respond_to?(:language)
		assert_equal CodeModels::Js::LANGUAGE,r.language
	end	

	def test_node_has_expected_basic_position
		r = Js.parse_code("i < 10;")
		assert_not_nil r.source
		assert_not_nil r.source.begin_pos
		assert_not_nil r.source.end_pos
		assert_equal 1,r.source.begin_pos.line
		assert_equal 1,r.source.begin_pos.column
		assert_equal 1,r.source.end_pos.line
		assert_equal 7,r.source.end_pos.column
	end	

	def test_node_has_expected_multiline_position
		r = Js.parse_code("{\ni < 10;\n}")
		assert_not_nil r.source
		assert_not_nil r.source.begin_pos
		assert_not_nil r.source.end_pos
		assert_equal 1,r.source.begin_pos.line
		assert_equal 1,r.source.begin_pos.column
		assert_equal 3,r.source.end_pos.line
		assert_equal 1,r.source.end_pos.column
	end	

	def test_node_to_source
		r = Js.parse_code("{\ni < 10;\n}")
		assert_equal "{\ni < 10;\n}",r.source.to_code
	end	

end