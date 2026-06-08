local TweenService = game:GetService("TweenService")
local Util = script.Parent
local MaidClass = require(Util.MaidClass)

local Tweenv2 = {}
Tweenv2.__index = Tweenv2

function Tweenv2:GetValue(...)
	return TweenService:GetValue(...)
end

function Tweenv2:Repurpose()
	return {
		Play = function(self)
			warn("tween instance returned null")

			return "null"
		end,
	}
end

function Tweenv2:Create(_Instance, ...)
	if not _Instance then
		return self:Repurpose()
	end
	
	local newTween = TweenService:Create(_Instance, ...)
	
	return {
		Destroy = function(self)
			newTween:Destroy()
			
			table.clear(self)
		end,
		
		Completed = newTween.Completed,
		
		Cancel = function(self)
			newTween:Cancel()
		end,
		
		Play = function(self)
			newTween:Play()
			
			self.Completed:Once(function()
				if not self.Destroy then
					return
				end
				
				self:Destroy()
			end)
			
			return self
		end,
	}
end

function Tweenv2:tween(info, props, WaitFactor)
	self:Create(
		self.object,
		info,
		props
	):Play()
	
	if WaitFactor then
		return task.wait(info.Time / WaitFactor)
	end

	return info.Time
end

function Tweenv2:changeValue(new)
	self.Value = new or self.object.Value
	self.object.Value = self.Value
end

function Tweenv2:init()
	if self.ProperConnection then
		return
	end
	
	self.object.Destroying:Once(function()
		self.Maid:Clean()
	end)
	
	if not self.object:IsA("ValueBase") then
		return
	end
	
	self:changeValue()
	
	self.ProperConnection = self.Maid:GiveTask(
		self.object:GetPropertyChangedSignal("Value"):Connect(function()
			self:changeValue()
		end)
	)
end

function Tweenv2.new(v)
	local self = setmetatable({
		object = v or Instance.new("CFrameValue"),
		Maid = MaidClass.new()
	}, Tweenv2)
	
	self:init()

	return self
end

return Tweenv2