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
		assert_not_nil r.source.position,"Source of #{r.class} has not the position"
		assert_not_nil r.source.position.begin_point
		assert_not_nil r.source.position.end_point
		assert_equal 1,r.source.position.begin_point.line
		assert_equal 1,r.source.position.begin_point.column
		assert_equal 1,r.source.position.end_point.line
		assert_equal 7,r.source.position.end_point.column
	end	

	def test_node_has_expected_multiline_position
		r = Js.parse_code("{\ni < 10;\n}")
		assert_not_nil r.source
		assert_not_nil r.source.position
		assert_not_nil r.source.position.begin_point
		assert_not_nil r.source.position.end_point
		assert_equal 1,r.source.position.begin_point.line
		assert_equal 1,r.source.position.begin_point.column
		assert_equal 3,r.source.position.end_point.line
		assert_equal 1,r.source.position.end_point.column
	end	

	def test_node_code
		r = Js.parse_code("{\ni < 10;\n}")
		assert_equal "{\ni < 10;\n}",r.source.code
	end	

	def test_artifact_final_host_is_set_correctly_for_all
		r = Js.parse_file('test/data/app.js')
		r.traverse(:also_foreign) do |n|
			assert_equal 'test/data/app.js',n.source.artifact.final_host.filename, "Node with wrong final_host: #{n}"
		end
	end

end