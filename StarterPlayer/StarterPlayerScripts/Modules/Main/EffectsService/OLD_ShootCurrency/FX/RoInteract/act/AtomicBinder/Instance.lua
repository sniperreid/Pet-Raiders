return function(self, key, value, indentLevel)
	return string.format("%q", tostring(value:GetFullName()))
end