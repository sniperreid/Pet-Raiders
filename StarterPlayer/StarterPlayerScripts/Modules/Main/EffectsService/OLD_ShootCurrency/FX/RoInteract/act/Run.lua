return function(...)
	local Inter_act = script.Parent
	local RoInstance = require(Inter_act.RoInstance)
	
	return RoInstance:readInfo(...)
end