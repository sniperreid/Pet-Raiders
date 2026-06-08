local Cycles = {}

function Cycles.get(Boss)
	return script:FindFirstChild(Boss)
end

function Cycles:new()
	return setmetatable(self, require(Cycles.get(self.Name)))
end

return Cycles