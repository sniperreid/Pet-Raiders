local HttpService = game:GetService("HttpService")
local RBXCleanUp = require(script.Parent.RBXCleanUp)

local function destroy(self)
	if self.Maid then
		self.Maid:Clean()
		self.Maid = nil
	end
	
	table.clear(self)
	setmetatable(self, nil)
end

local classes = {}

function classes.insert(class)
	return function (data)
		data.__index = data
		data.class = class
		data.class_id = HttpService:GenerateGUID(false)
		data.Maid = RBXCleanUp.new()

		classes[class] = data
		
		return classes
	end
end

function classes.new(class, init, ...)
	local data = classes[class]
	
	assert(data, "invalid class.")
	
	local _class = setmetatable({Destroy=destroy}, data)
	
	if init and typeof(init) == "function" then
		_class.init = init
	end
	
	if not _class.init then
		return _class
	end
	
	if init and typeof(init) == "function" then
		_class:init(...)
	else
		_class:init(init, ...)
	end
	
	return _class
end

return classes