return function(self, key, value, indentLevel)
	return self:SourceToBinder({value:GetComponents()}, indentLevel + 1)
end