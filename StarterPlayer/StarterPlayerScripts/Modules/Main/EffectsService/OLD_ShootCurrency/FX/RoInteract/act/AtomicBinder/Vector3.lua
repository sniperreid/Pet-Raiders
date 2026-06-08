return function(self, key, value, indentLevel)
	return self:SourceToBinder({value.X, value.Y, value.Z}, indentLevel + 1)
end