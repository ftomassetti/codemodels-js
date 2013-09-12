require 'test/unit'
require 'lightmodels'
require 'js-lightmodels'
require 'test_helper'
 
class TestParseLargeFile < Test::Unit::TestCase

	include TestHelper
	include LightModels

	def test_parse_angular
		Js.parse_file(File.dirname(__FILE__)+'/angular.js')
	end

end