require 'test/unit'
require 'lightmodels'
require 'js-lightmodels'
require 'test_helper'
 
class TestParseLargeFile < Test::Unit::TestCase

	include TestHelper
	include LightModels

	# def test_parse_angular
	# 	#Js.parse_file(File.dirname(__FILE__)+'/angular.js')
	# end

	def test_parse_puzzle_app
		path = "/Users/federico/repos/cross_language_analysis/projects/angular-puzzle/angular-puzzle/app/js/app.js"
		#Js.parse_file(path)
	end

	def test_parse_angular_mocks
		#path = "/Users/federico/repos/cross_language_analysis/projects/angular-puzzle/angular-puzzle/app/js/lib/angular/angular-mocks.js"
		path = File.dirname(__FILE__)+'/angular-mocks-1.js'
		#Js.parse_file(path)
		path = File.dirname(__FILE__)+'/angular-mocks-2.js'
		#Js.parse_file(path)
		path = File.dirname(__FILE__)+'/angular_if.js'
		Js.parse_file(path)
	end

	# def test_parse_angular_puzzle
	# 	files = Dir['/Users/federico/repos/cross_language_analysis/projects/angular-puzzle/**/*.js']
	# 	ok = 0
	# 	ko = 0

	# 	files.each do |f|
	# 		puts "Parsing #{f}"
	# 		begin
	# 			Js.parse_file(f)
	# 			ok+=1
	# 		rescue
	# 			ko+=1
	# 		end
	# 		puts "Ok: #{ok}, Ko: #{ko}"
	# 	end
	# end

end