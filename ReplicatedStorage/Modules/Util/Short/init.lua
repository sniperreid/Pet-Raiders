local Short = { }

function Short:RoundDecimal(Number, num)
	local RoundedNumber = math.round(Number * 1e2) / 1e2
	
	if num then
		return RoundedNumber
	end

	if RoundedNumber % 1 == 0 then
		return string.format("%d", RoundedNumber)
	else
		return string.format("%.2f", RoundedNumber)
	end
end

function Short:AddCommas(Number)
	local FormattedNumber = tostring(Number):reverse():gsub("(%d%d%d)", "%1,"):reverse()

	return FormattedNumber:gsub("^,", "")
end

function Short:AddSuffix(Input)
	Input = tonumber(Input)

	local MaxLimit = 1e306

	local Units = require(script.Units)

	if Input >= MaxLimit then
		return "inf"
	end

	for I = 1, #Units do
		local Unit, Limit = Units[I][1], Units[I][2]

		if Input >= Limit then
			continue
		end
		
		if I <= 1 then
			return tostring(Input)
		end
		
		local PrevUnit, PrevLimit = Units[I - 1][1], Units[I - 1][2]

		return self:RoundDecimal(Input / PrevLimit) .. PrevUnit
	end
end

function Short:FormatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local remainder = seconds % 60
	
	return string.format("%02d:%02d", minutes, remainder)
end

function Short:FormatBoost(Time)
	if not Time then
		return 0
	end
	
	if Time < 60 then
		return ("%s%s"):format(Time, "s")
	end

	return ("%s%s"):format((Time // 3600) > 0 and ("%ih "):format(Time // 3600) or "", (Time % 3600) // 60 > 0 and ("%im"):format((Time % 3600) // 60) or "")
end

return Short