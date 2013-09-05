require 'rgen/metamodel_builder'

module JsLightmodels

# value is mapped to body, if the metaclass has it

class Statement < RGen::MetamodelBuilder::MMBase
end

class Expression < Statement
end

class ExpressionStatement < Statement
	contains_one_uni 'body', Expression
end

class Literal < Expression
end

class SourceElements < RGen::MetamodelBuilder::MMBase
	contains_many_uni 'body', Statement
end

class For < Statement	
	contains_one_uni 'init', Statement
	contains_one_uni 'counter', Statement
	contains_one_uni 'test', Expression
	contains_one_uni 'body', Statement
end

class Block < Statement
end

class VarDecl < Statement
	has_attr 'name', String
	contains_one_uni 'body', Expression
end

class AssignExpr < Expression
	contains_one_uni 'body', Expression
end

class BinaryExpression < Expression
	contains_one_uni 'body', Expression
	contains_one_uni 'left', Expression
end

class Less < BinaryExpression
end

class Resolve < Expression
	has_attr 'value', String
end

class Number < Literal
	has_attr 'value', Integer
end

class Add < Statement
end

class VarStatement < Statement
	contains_one_uni 'body', VarDecl
end

class Postfix < Expression
	has_attr 'value', String
	contains_one_uni 'operand', Expression
end

end