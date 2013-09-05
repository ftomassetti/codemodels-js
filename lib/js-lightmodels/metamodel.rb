require 'rgen/metamodel_builder'

module JsLightmodels

# value is mapped to body, if the metaclass has it

ParsingAdapters = Hash.new {|h,k| h[k]={}}

class Statement < RGen::MetamodelBuilder::MMBase
end

class Expression < Statement
end

class ExpressionStatement < Statement
	contains_one_uni 'expression', Expression
	ParsingAdapters[self]['expression'] = 'value'
end

class Literal < Expression
end

class SourceElements < RGen::MetamodelBuilder::MMBase
	contains_many_uni 'contents', Statement
	ParsingAdapters[self]['contents'] = 'value'
end

class For < Statement	
	contains_one_uni 'init', Statement
	contains_one_uni 'counter', Statement
	contains_one_uni 'test', Expression
	contains_one_uni 'body', Statement
	ParsingAdapters[self]['body'] = 'value'
end

class Block < Statement
	contains_one_uni 'body', SourceElements
	ParsingAdapters[self]['body'] = 'value'
end

class VarDecl < Statement
	has_attr 'name', String
	contains_one_uni 'value', Expression
end

class AssignExpr < Expression
	contains_one_uni 'value', Expression
end

class BinaryExpression < Expression
	contains_one_uni 'right', Expression
	contains_one_uni 'left', Expression
	ParsingAdapters[self]['right'] = 'value'
end

class Less < BinaryExpression
end

class Resolve < Expression
	has_attr 'id', String
	ParsingAdapters[self]['id'] = 'value'
end

class Number < Literal
	has_attr 'value', Integer
end

class Add < Expression
end

class VarStatement < Statement
	contains_one_uni 'decl', VarDecl
	ParsingAdapters[self]['decl'] = 'value'
end

class Postfix < Expression
	has_attr 'operator', String
	contains_one_uni 'operand', Expression
	ParsingAdapters[self]['operator'] = 'value'
end

end