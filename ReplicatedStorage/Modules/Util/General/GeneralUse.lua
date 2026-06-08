-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Instances
local modules = ReplicatedStorage.Modules

local GeneralUse = {}

-- Returns a value using the given ratio.
function GeneralUse.basedValue(baseValue,scaleValue,currentValue) 
	--	print(z,y,x)
	local getBasedValueFuncs = {}

	local function multiplyScaleValue(value)
		return (currentValue*value)/baseValue
	end
	function getBasedValueFuncs.NumberSequence()
		local basedKeypoints = {}
		for i,keypoint in pairs(scaleValue.Keypoints) do
			basedKeypoints[i] = NumberSequenceKeypoint.new(keypoint.Time,multiplyScaleValue(keypoint.Value),multiplyScaleValue(keypoint.Envelope)) 
		end
		return NumberSequence.new(basedKeypoints)
	end

	function getBasedValueFuncs.NumberRange()
		return NumberRange.new(
			multiplyScaleValue(scaleValue.Min),
			multiplyScaleValue(scaleValue.Max)
		)
	end

	function getBasedValueFuncs.Default()
		return multiplyScaleValue(scaleValue)
	end

	return (getBasedValueFuncs[typeof(scaleValue)] or getBasedValueFuncs.Default)()
end

function GeneralUse.Round(number,decimalPlaces)
	local decimalPlaces = (decimalPlaces or 0)
	local newNum = math.round(number * 10^decimalPlaces) * 10^-decimalPlaces

	newNum=tonumber(string.format("%." .. (decimalPlaces) .. "f", newNum))
	return newNum
end

function GeneralUse.CalcWeldC0(cf0,cf1)
	return cf0:ToObjectSpace(cf1)
end

local function joinParts(name,p0,p1,c0,c1,parent)
	local joinObject = Instance.new(name)
	joinObject.Part0 = p0
	joinObject.Part1 = p1
	if name~="WeldConstraint" then
	
		joinObject.C0 = c0 or GeneralUse.CalcWeldC0(p0.CFrame,p1.CFrame)
		if c1 then
			joinObject.C1 = c1
		end
	end
	joinObject.Parent = parent or p0
	return joinObject
end

function GeneralUse.AddMotor6D(...):Motor6D
	return joinParts("Motor6D",...)
end

function GeneralUse.Weld(...):Weld
	return joinParts("Weld",...)
end

function GeneralUse.AddWeldConstraint(...):WeldConstraint
	return joinParts("WeldConstraint",...)
end
function GeneralUse.GetTargetFromHit(hit)
	local target
	if hit.Parent:FindFirstChild("Humanoid") then
		target = hit.Parent

	elseif hit.Parent.Parent:FindFirstChild("Humanoid") then
		target = hit.Parent.Parent
	end
	return target
end
function GeneralUse.GetFirstCollidable(startPos,angle,ignoreList,includeChars,debugMode):RaycastResult	 -- Raycasts from the startPos using the given angle (or Vector3.new(0,-100,0) if left nil) using the given ignore list. Returns the first collidable hit or nil if it hits nothing. If includeChars is true then it will include parts that are parented to characters
	angle = angle or Vector3.new(0,-1000,0)
	ignoreList = ignoreList or {}
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = ignoreList
	--raycastParams.IgnoreWater = true
	local firstCollide
	while true do
		raycastParams.FilterDescendantsInstances = ignoreList
		local result = workspace:Raycast(startPos,angle, raycastParams)
		if debugMode then
			--print(result)
		end
		if result then
			local hit = result.Instance
			local canContinue = true

			local target = GeneralUse.GetTargetFromHit(hit)
			if target then
				if not includeChars then			
					canContinue = false
					table.insert(ignoreList,1,target)
				end
			else
				if not hit.CanCollide then
					canContinue = false
				end
			end


			if canContinue then
				firstCollide = result
				break
			else
				table.insert(ignoreList,1,hit)
			end
		else
			break
		end
	end
	return firstCollide,ignoreList
end

function GeneralUse.ScaleParticle(baseNum,particle,givenNum,categories,baseParticle)
	categories = categories or {
		"Size";
		"Speed";
		"Acceleration";
	}

	for _,category in pairs(categories) do
		particle[category] = GeneralUse.basedValue(baseNum,(baseParticle or particle)[category],givenNum)
	end
	return particle
end
function GeneralUse:GetShakeOffset(shakeStrength:number,shakeTime:number?,fadeOut:TweenInfo,doShakeFunc,optSettings)
	optSettings=optSettings or {}
	local shakeWait = optSettings.shakeWait or .04
	local fadeIn = optSettings.fadeIn

	local stopShake = false
	local shakeValue = Instance.new("NumberValue")
	shakeValue.Value = shakeStrength


	local shakeMut = Instance.new("NumberValue")
	shakeMut.Value = fadeIn and 0 or 1

	if fadeIn then
		TweenService:Create(shakeMut,fadeIn,{Value = 1}):Play()
	end
	task.spawn(function()
		repeat
			doShakeFunc(function(basePosition,epicenter,shakeDist,noRandomize)
				local strength = shakeValue.Value
				local newStrength

				if basePosition and epicenter and shakeDist then
					local distFromCenter = (basePosition - epicenter).Magnitude
					newStrength = math.clamp((shakeDist*strength)/distFromCenter,0,strength)
				else
					newStrength = strength
				end
				if not noRandomize then
					local randomObject = Random.new()
					newStrength = randomObject:NextNumber(-newStrength,newStrength)
				end
				return newStrength*shakeMut.Value
			end,shakeWait)
			task.wait(shakeWait)
		until stopShake
	end)

	task.wait(shakeTime)

	TweenService:Create(shakeValue,fadeOut,{Value = 0}):Play()
	task.wait(fadeOut.Time)
	stopShake = true
end

return GeneralUse