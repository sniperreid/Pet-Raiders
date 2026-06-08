return function(self, key, value, indentLevel)
	return self:SourceToBinder(value, indentLevel + 1)
end