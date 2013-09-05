require 'test/unit'
require 'js-lightmodels'
 
class TestParsingTree < Test::Unit::TestCase

	def test_the_root_is_parsed
		code = "for(var i = 0; i < 10; i++) { var x = 5 + 5; }"
		r = JsLightmodels.parse(code)
		assert r.is_a? JsLightmodels::SourceElements
	end

end