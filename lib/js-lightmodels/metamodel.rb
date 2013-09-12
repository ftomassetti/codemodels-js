require 'rgen/metamodel_builder'

module LightModels

module Js

# value is mapped to body, if the metaclass has it

ParsingAdapters = Hash.new {|h,k| h[k]={}}

class Statement < RGen::MetamodelBuilder::MMBase
end

# ok
class SourceElements < RGen::MetamodelBuilder::MMBase
	contains_many_uni 'contents', Statement
	ParsingAdapters[self]['contents'] = 'value'
end

class Expression < Statement
end

# ok
class ExpressionStatement < Statement
	contains_one_uni 'expression', Expression
	ParsingAdapters[self]['expression'] = 'value'
end

# checked
class NewExpr < Expression
	contains_one_uni 'type', Expression
	contains_one_uni 'args', Expression
	ParsingAdapters[self]['type'] = 'value'
end

class Literal < Expression
end

# checked
class FunctionExpr < Expression
	has_attr 'name', String
	contains_one_uni 'body', Statement
	contains_many_uni 'arguments', Expression
	ParsingAdapters[self]['name'] = 'value'
end

# checked
class FunctionDecl < FunctionExpr
end

# checked
class FunctionCall < Expression
	contains_one_uni 'function', Expression
	contains_many_uni 'arguments', Expression
	ParsingAdapters[self]['function'] = 'value'
end

# checked
class For < Statement	
	contains_one_uni 'init', Statement
	contains_one_uni 'counter', Statement
	contains_one_uni 'test', Expression
	contains_one_uni 'body', Statement
	ParsingAdapters[self]['body'] = 'value'
end

# checked
class ForIn < Statement	
	contains_one_uni 'left', Expression
	contains_one_uni 'right', Expression
	contains_one_uni 'body', Statement
	ParsingAdapters[self]['body'] = 'value'
end

# checked
class VarDecl < Statement
	has_attr 'name', String
	has_attr 'constant', Boolean
	contains_one_uni 'value', Expression
end

# checked
class Label < Statement
	has_attr 'name', String
	contains_one_uni 'body', Statement
	ParsingAdapters[self]['body'] = 'value'
end

# checked
class IfStatement < Statement
	contains_one_uni 'test', Expression
	contains_one_uni 'then_block', Statement
	contains_one_uni 'else_block', Statement
	ParsingAdapters[self]['test'] = 'conditions'
	ParsingAdapters[self]['then_block'] = 'value'
end

# checked
class Conditional < IfStatement
end

# checked
class Comma < Expression
	contains_one_uni 'right', Expression
	contains_one_uni 'left', Expression
	ParsingAdapters[self]['right'] = 'value'
end

# checked
class BracketAccessor < Expression
	contains_one_uni 'resolve', Expression
	contains_one_uni 'accessor', Expression
	ParsingAdapters[self]['resolve'] = 'value'	
end

# checked
class DotAccessor < Expression
	contains_one_uni 'resolve', Expression
	contains_one_uni 'accessor', Expression
	ParsingAdapters[self]['resolve'] = 'value'	
end

# checked
class Try < Statement
	contains_one_uni 'body', Statement
	contains_one_uni 'catch_var', Expression
	contains_one_uni 'catch_block', Statement
	contains_one_uni 'finally_block', Statement
	ParsingAdapters[self]['body'] = 'value'	
end

# checked
class BinaryExpression < Expression
	contains_one_uni 'right', Expression
	contains_one_uni 'left', Expression
	ParsingAdapters[self]['right'] = 'value'
end

# checked
%w[Subtract LessOrEqual GreaterOrEqual Add Multiply NotEqual
       DoWhile Switch LogicalAnd UnsignedRightShift Modulus While
       NotStrictEqual Less With In Greater BitOr StrictEqual LogicalOr
       BitXOr LeftShift Equal BitAnd InstanceOf Divide RightShift].each do |node|
    const_set "#{node}", Class.new(BinaryExpression)
end

# checked
class OpEqual < Statement
	contains_one_uni 'right', Expression
	contains_one_uni 'left', Expression
	ParsingAdapters[self]['right'] = 'value'	
end

# cheked
%w[Multiply Divide LShift Minus Plus Mod XOr RShift And URShift Or].each do |node|
    const_set "#{node}", Class.new(OpEqual)
end

# checked
class CaseClauseNode < BinaryExpression
end

# checked
class Resolve < Expression
	has_attr 'id', String
	ParsingAdapters[self]['id'] = 'value'
end

# checked
class Property < Expression
	has_attr 'name', String
	contains_one_uni 'body', Statement
	ParsingAdapters[self]['body'] = 'value'	
end

# checked
class Postfix < Expression
	has_attr 'operator', String
	contains_one_uni 'operand', Expression
	ParsingAdapters[self]['operator'] = 'value'
end

# checked
class Prefix < Expression
	has_attr 'operator', String
	contains_one_uni 'operand', Expression
	ParsingAdapters[self]['operator'] = 'value'
end

class ValuedStatement < Statement
	contains_one_uni 'value', Expression
end

%w[Delete Return TypeOf
       LogicalNot FunctionBody
       UnaryMinus Throw BitwiseNot Element
       CaseBlock Null Break Parameter
       Arguments Attr Continue ConstStatement UnaryPlus].each do |node|
      const_set "#{node}", Class.new(ValuedStatement)
end

# ok
class Block < Statement
	contains_one_uni 'body', SourceElements
	ParsingAdapters[self]['body'] = 'value'
end

# ok
class AssignExpr < Expression
	contains_one_uni 'value', Expression
end

# ok
class VarStatement < Statement
	contains_many_uni 'decl', VarDecl
	ParsingAdapters[self]['decl'] = 'value'
end

# intermediate
class UnvaluedLiteral < Literal
end

%w[True False This Void ObjectLiteral].each do |node|
      const_set "#{node}", Class.new(UnvaluedLiteral)		
end

# intermediate
class ValueExpression < Expression 
	contains_one_uni 'value', Expression
end

%w[Parenthetical].each do |node|
      const_set "#{node}", Class.new(ValueExpression)		
end

%w[EmptyStament].each do |node|
      const_set "#{node}", Class.new(Statement)		
end

class StringLiteral < Literal
	has_attr 'value', String
end

class RegExp < Literal
	has_attr 'value', String
end

class Number < Literal
	has_attr 'value', Integer
end

class Array < RGen::MetamodelBuilder::MMBase
	contains_many_uni 'values', Expression
end

end

end