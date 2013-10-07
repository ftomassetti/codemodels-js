require 'test_helper'
 
class TestExpressionParser < Test::Unit::TestCase

	include TestHelper
	include CodeModels
	include CodeModels::Js

	def test_basic_expression_parsing
		r = Js::ExpressionParser.parse_code("i < 10")
		assert_equal CodeModels::Js::LANGUAGE,r.language
		assert_class Js::LessInfixExpression,r
	end	

	def test_name_expression_parsing
		r = Js::ExpressionParser.parse_code("pippo")
		assert_equal CodeModels::Js::LANGUAGE,r.language
		assert_class Js::Name,r
	end	

	def test_basic_expression_position
		r = Js::ExpressionParser.parse_code("i < 10")
		assert_equal CodeModels::Js::LANGUAGE,r.language
		assert_equal SourcePoint.new(1,1),r.source.position.begin_point
		assert_equal SourcePoint.new(1,6),r.source.position.end_point
	end	

end