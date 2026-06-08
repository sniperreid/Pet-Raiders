local NumberHelper = {}

-- Returns a random number between min and max (Default: .8 - 1.2)
function NumberHelper.Random(min:number,max:number):number
    return Random.new():NextNumber(min or .8,max or 1.2)
end

-- Returns either 1 or -1 randomly
function NumberHelper.RandomReverseMutlipler():number
    return (math.random(0,1) == 1 and 1 or -1)
end

-- Returns a random rotation from -360 to 360 in radians
function NumberHelper.RandomRotation():number
	local fullRot = 2*math.pi
	return NumberHelper.Random(-fullRot,fullRot)
end

function NumberHelper.Round(number,decimalPlaces)
	decimalPlaces = (decimalPlaces or 0)
	local newNum = math.round(number * 10^decimalPlaces) * 10^-decimalPlaces

	newNum=tonumber(string.format("%." .. (decimalPlaces) .. "f", newNum))
	return newNum
end

function NumberHelper.NumberToVector3(num) -- Returns a Vector3 with the given number in every value
	return Vector3.new(num,num,num)
end

function NumberHelper.ScaleValue(baseValue,scaleValue,currentValue) 
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

function NumberHelper.GetRootScaleValues(rootSize)
	return Vector3.new(2,2,1).Magnitude,rootSize.Magnitude
end

function NumberHelper.GetLargestAxis(vector3:Vector3):(number,string)
	local largestVector = {size=vector3.X,name = 'X'}
	local function checkLargest(axis:string)
		local newSize:number = vector3[axis]
		if largestVector.size <= newSize then
			largestVector.size = newSize
			largestVector.name = axis
		end
	end
	checkLargest("Y")
	checkLargest("Z")
	return largestVector.size,largestVector.name
end

function NumberHelper.SineBetween(t:number,maxNumber:number,minNumber:number, frequency:number,phase:number)
	return ((maxNumber-minNumber)*math.sin(t*frequency +  phase) + maxNumber + minNumber)/2
end
return NumberHelper