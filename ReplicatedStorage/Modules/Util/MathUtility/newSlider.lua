local newSlider = {}
newSlider.__index = newSlider

function newSlider:Destroy()
	table.clear(self)
end

function newSlider:get()
	local Sub = self.Sub
	local MaxSub = self.MaxSub
	local Min = self.Min
	local Max = self.Max
	
	if Sub == MaxSub then
		return Max
	end
	
	if Sub == 1 then
		return Min
	end
	
	local p = (10/3)
	
	local GetSlider = (Max - Min) / (MaxSub^p-1)
	local Slide = Min - GetSlider
	
	return math.clamp(GetSlider * Sub ^ p + Slide, Min, Max)
end

function newSlider:newSub(t, u)
	self.Sub = t or self.Sub
	self.MaxSub = u or self.MaxSub
end

function newSlider.new(Min, Max, t, u)
	return setmetatable({
		Min = Min,
		Max = Max,
		Sub = t,
		MaxSub = u
	}, newSlider)
end

return newSlider.new