return function(self, key, value)
	return string.format("%q", tostring(value))
end