local Scaler = {}
Scaler.__index = Scaler

function Scaler:ScaleTo(NewScale, Speed, TweenType)

	local TweenType = TweenType or self.TweenTheme or "Linear"
	local Speed = Speed or 1
	
	local Object = self.Object
	local Current = Object.Scale
	
	local DistanceToScale = math.abs(Current - NewScale)

	self:PlayTween(
		TweenInfo.new(Speed, Enum.EasingStyle[TweenType]),
		{Scale = NewScale}
	)
end

function Scaler.new(Controller, GUI_OBJECT)
	local self = setmetatable({
		Controller = Controller,
		Object = Controller.Object
	}, Scaler)
	
	Controller.ScaleTo = self.ScaleTo

	return self
end

return Scaler