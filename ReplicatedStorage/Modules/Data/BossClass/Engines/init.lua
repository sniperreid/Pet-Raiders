local Engines = {}

function Engines.locate(boss_name: string)
	local module = script:FindFirstChild(boss_name)
	
	assert(module, ("Could not retrieve engine for %s"):format(boss_name))
	
	return require(module)
end

return Engines