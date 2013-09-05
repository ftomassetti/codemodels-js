module TestHelper

def assert_class(expected_class,node)
	assert node.class==expected_class, "Node expected to have class #{expected_class} instead it has class #{node.class}"
end

end