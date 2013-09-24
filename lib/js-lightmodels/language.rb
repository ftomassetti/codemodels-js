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

LightModels.register_language JsLanguage.new

end
end