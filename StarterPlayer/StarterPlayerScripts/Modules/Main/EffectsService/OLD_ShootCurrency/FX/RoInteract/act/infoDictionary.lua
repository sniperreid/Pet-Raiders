local TweenService = game:GetService("TweenService")
local RoInteract = script.Parent
local CallbackLibrary = require(RoInteract.CallbackLibrary)

local function formCFrame(cframe)
	if not cframe then
		return
	end

	local isCFrame = typeof(cframe) == "CFrame"

	if isCFrame then
		return cframe
	end

	return CFrame.new(unpack(cframe))
end

local function formSize(size)
	if not size then
		return
	end

	local isVector = typeof(size) == "Vector3"

	if isVector then
		return size
	end

	return Vector3.new(unpack(size))
end

return {
	Callback = function(self, Info)
		local uInfo = Info.Info
		local Arguments = uInfo.Arguments or {}

		local AccoladeInfo = CallbackLibrary[uInfo.Name]

		return AccoladeInfo.callback(self, unpack(Arguments))
	end,

	Tween = function(self, Info)
		local Object = RoInteract.Parent
		
		warn(Info)

		local uInfo = Info.Info
		local Arguments = uInfo.Arguments

		local cframe = Arguments.CFrame
		local size = Arguments.Size
		
		cframe = formCFrame(cframe)
		size = formSize(size)

		local tInfo = uInfo.Info
		local tInfo = TweenInfo.new(
			tInfo.Time,
			tInfo.EasingStyle,
			tInfo.EasingDirection,
			tInfo.RepeatCount,
			tInfo.Reverses,
			tInfo.DelayTime
		)

		return TweenService:Create(
			Object,
			tInfo,
			{
				CFrame = cframe,
				Size = size
			}
		):Play()
	end,
}