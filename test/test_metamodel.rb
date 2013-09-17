require 'test/unit'
require 'lightmodels'
require 'js-lightmodels'
require 'test_helper'
 
class TestInfoExtraction < Test::Unit::TestCase

	include TestHelper
	include LightModels
	include LightModels::Js
	include RGen::ECore

	# TODO ArrayComprehension
	# TODO ArrayComprehensionLoop

	def test_js_node
		assert Js.const_defined? :JsNode
		c = Js.const_get :JsNode

		assert_all_attrs [], c
		assert_all_refs  [], c
	end

	def test_break
		assert Js.const_defined? :BreakStatement
		c = Js.const_get :BreakStatement

		# TODO break label and break target maybe should be there
		assert_all_attrs [], c
		assert_all_refs  ['breakLabel'], c		

		assert_ref c,'breakLabel',Name
	end

	def test_array_literal
		assert Js.const_defined? :ArrayLiteral
		c = Js.const_get :ArrayLiteral

		assert_all_attrs [],              c
		assert_all_refs  ['elements'],    c

		assert_ref c,'elements',JsNode,true
	end

	def test_symbol
		assert Js.const_defined? :Symbol
		c = Js.const_get :Symbol

		assert_attr c,'declType',EString
	end

	def test_block
		assert Js.const_defined? :Block
		c = Js.const_get :Block

		assert_all_attrs [],               c
		assert_all_refs  ['contents'],    c

		assert_ref c,'contents',JsNode,true
	end

	def test_infix_expression
		assert Js.const_defined? :InfixExpression
		c = Js.const_get :InfixExpression

		assert_all_attrs [],               c
		assert_all_refs  ['left','right'], c

		assert_ref c,'left',JsNode
		assert_ref c,'right',JsNode	
	end

	def test_property_get
		assert Js.const_defined? :PropertyGet
		c = Js.const_get :PropertyGet

		assert_all_attrs [],     c
		assert_all_refs  ['left','right'], c

		assert_equal 0,c.ecore.eAttributes.count
		assert_equal 0,c.ecore.eReferences.count
	end

end