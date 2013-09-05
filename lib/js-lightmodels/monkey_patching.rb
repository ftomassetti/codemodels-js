class Module
  def simple_name
    if (i = (r = name).rindex(':')) then r[0..i] = '' end
    r
  end
end

class String
	def remove_postfix(postfix)
		raise "I have not the right prefix" unless end_with?(postfix)
		self[0..-(1+postfix.length)]
	end
end