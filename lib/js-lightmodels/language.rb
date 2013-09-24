require 'lightmodels'

module LightModels
module Js

class JsLanguage < Language
	def initialize
		super('Javascript')
		@extensions << 'js'
		@parser = LightModels::Js::Parser.new
	end
end

LANGUAGE = JsLanguage.new
LightModels.register_language LANGUAGE

end
end