# encoding: UTF-8
require 'codemodels'

module CodeModels

module Js

EXTENSION = 'js'

def self.handle_models_in_dir(src,error_handler=nil,model_handler)
	CodeModels::ModelBuilding.handle_models_in_dir(src,EXTENSION,error_handler,model_handler) do |src|
		root = parse_file(src)
		CodeModels::Serialization.rgenobject_to_model(root)
	end
end

def self.generate_models_in_dir(src,dest,model_ext="#{EXTENSION}.lm",max_nesting=500,error_handler=nil)
	CodeModels::ModelBuilding.generate_models_in_dir(src,dest,EXTENSION,model_ext,max_nesting,error_handler) do |src|
		root = parse_file(src)
		CodeModels::Serialization.rgenobject_to_model(root)
	end
end

def self.generate_model_per_file(src,dest,model_ext="#{EXTENSION}.lm",max_nesting=500,error_handler=nil)
	CodeModels::ModelBuilding.generate_model_per_file(src,dest,max_nesting,error_handler) do |src|
		root = parse_file(src)
		CodeModels::Serialization.rgenobject_to_model(root)
	end
end

end

end