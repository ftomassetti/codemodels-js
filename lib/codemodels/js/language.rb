require 'codemodels'

module CodeModels
module Js

class JsLanguage < Language
	def initialize
		super('Javascript')
		@extensions << 'js'
		@parser = CodeModels::Js::Parser.new
	end
end

LANGUAGE = JsLanguage.new
CodeModels.register_language LANGUAGE

end
end