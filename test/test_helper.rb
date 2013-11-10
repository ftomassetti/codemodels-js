# encoding: UTF-8
require 'simplecov'
SimpleCov.start do
	add_filter "/test/"	
end

require 'test/unit'
require 'codemodels'
require 'codemodels/js'

module TestHelper

include CodeModels

def parse_code(code)
	Js.parse_code(code.encode(Parser::DEFAULT_INTERNAL_ENCODING))
end

def assert_metamodel(name,attrs,refs)
	assert Js.const_defined?(name), "Metaclass '#{name}' not found"
	c = Js.const_get name

	assert_all_attrs attrs, c
	assert_all_refs  refs, c	
	c
end

def assert_class(expected_class,node)
	assert node.class==expected_class, "Node expected to have class #{expected_class} instead it has class #{node.class}"
end

def relative_path(path)
	File.join(File.dirname(__FILE__),path)
end

def assert_all_attrs(expected,c)
	actual = c.ecore.eAllAttributes
	assert_equal expected.count,actual.count,"Expected #{expected.count} attrs, found #{actual.count}. They are #{actual.name}"
	expected.each do |e|
		assert actual.find {|a| a.name==e}, "Attribute #{e} not found"	
	end
end

def assert_all_refs(expected,c)
	actual = c.ecore.eAllReferences
	assert_equal expected.count,actual.count,"Expected #{expected.count} refs, found #{actual.count}. They are #{actual.name}"
	expected.each do |e|
		assert actual.find {|a| a.name==e}, "Reference #{e} not found"	
	end
end

def assert_ref(c,name,type,many=false)
	ref = c.ecore.eAllReferences.find {|r| r.name==name}
	assert ref, "Reference '#{name}' not found"	
	assert_equal type.ecore.name,ref.eType.name
	assert_equal many, ref.many
end

def assert_attr(c,name,type,many=false)
	att = c.ecore.eAllAttributes.find {|a| a.name==name}	
	assert_equal type.name,att.eType.name
	assert_equal many, att.many
end

end