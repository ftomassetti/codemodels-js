require 'test/unit'
require 'lightmodels'
require 'js-lightmodels'
require 'test_helper'
 
class TestInfoExtraction < Test::Unit::TestCase

	include TestHelper
	include LightModels

	def test_symbol
		assert Js.const_defined? :Symbol
		c = Js.const_get :Symbol
		assert c.ecore.eAllAttributes.find {|a| a.name=='declType'}
		declType = c.ecore.eAllAttributes.find {|a| a.name=='declType'}
		assert declType.getEType.is_a?(RGen::ECore::EDataType)
		assert_equal 'EString', declType.getEType.name
		assert_equal false, declType.many
	end

end