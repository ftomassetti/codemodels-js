require 'rgen/metamodel_builder'

module JsLightmodels

# value is mapped to body, if the metaclass has it

class Statement < RGen::MetamodelBuilder::MMBase
end

class Literal < RGen::MetamodelBuilder::MMBase
end

class SourceElements < RGen::MetamodelBuilder::MMBase
	contains_many_uni 'body', Statement
end

class For < Statement	
	contains_one_uni 'init', Statement
	contains_one_uni 'counter', Statement
	contains_one_uni 'test', Statement
	contains_one_uni 'body', Statement
end

class Block < Statement
end

class VarDecl < Statement
end

class AssignExpr < Statement
end

class Less < Statement
end

class Resolve < Statement
end

class Number < Literal
end

class Add < Statement
end

class VarStatement < Statement
	contains_one_uni 'body', VarDecl
end

class Postfix < Statement
end

end