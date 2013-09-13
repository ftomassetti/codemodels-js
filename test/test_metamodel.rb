require 'test/unit'
require 'lightmodels'
require 'js-lightmodels'
require 'test_helper'
 
class TestInfoExtraction < Test::Unit::TestCase

	include TestHelper
	include LightModels
	include LightModels::Js
	include RGen::ECore

	def test_symbol
		assert Js.const_defined? :Symbol
		c = Js.const_get :Symbol

		assert_attr c,'declType',EString
	end

	def test_infix_expression
		assert Js.const_defined? :InfixExpression
		c = Js.const_get :InfixExpression

		assert_all_attrs ['operator'],     c
		assert_all_refs  ['left','right'], c
		
		assert_attr c,'operator',EString

		assert_ref c,'left',JsNode
		assert_ref c,'right',JsNode	
	end

	def test_property_get
		assert Js.const_defined? :PropertyGet
		c = Js.const_get :PropertyGet

		assert_equal 0,c.ecore.eAttributes.count
		assert_equal 0,c.ecore.eReferences.count
	end

end