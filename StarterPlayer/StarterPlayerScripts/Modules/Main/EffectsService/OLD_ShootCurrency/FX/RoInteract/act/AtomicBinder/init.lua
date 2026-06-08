local AtomicBinder = {}
AtomicBinder.FileName = ""

function AtomicBinder.GetSourceFileName()
	local FileName = AtomicBinder.FileName
	
	return ("%s.act"):format(FileName)
end

function AtomicBinder:SourceToBinder(source, indentLevel)
	local indentLevel = indentLevel or 0

	local indent = string.rep("    ", indentLevel)
	local result = "{\n"

	for key, value in source do
		local formattedKey = type(key) == "string" and string.format("[%q]", key) or string.format("[%s]", tostring(key))
		local Basis = script:FindFirstChild(typeof(value))
		local formattedValue = Basis and require(Basis)(self, key, value, indentLevel) or tostring(value)
		
		result = result .. string.format("%s    %s = %s,\n", indent, formattedKey, formattedValue)
	end

	result = result .. indent .. "}"

	return result
end

function AtomicBinder:OverwriteSource(Binder: ModuleScript)
	Binder.Source = "return " .. self:SourceToBinder(require(Binder))
	
	return Binder.Source
end

return AtomicBinder