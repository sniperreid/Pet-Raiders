local garbageCollector = {}
garbageCollector.__index = garbageCollector

function garbageCollector:Destroy(Task)
	local type = typeof(Task)
	local isTable = type == "table"

	local isInstance = type == "Instance" or (isTable and Task.Destroy)

	if not isInstance then
		return
	end

	return Task:Destroy()
end

function garbageCollector:Cancel(Task)
	local type = typeof(Task)
	local isTable = type == "table"

	local isDisconnect = type == "Tween" or (isTable and Task.Cancel)

	if not isDisconnect then
		return
	end

	return Task:Cancel()
end

function garbageCollector:Close(Task)
	local type = typeof(Task)
	local isTable = type == "table"

	local isDisconnect = type == "function" or (isTable and Task.close)

	if not isDisconnect then
		return
	end

	if Task.close then
		return Task.close()
	end

	return coroutine.close(Task)
end

function garbageCollector:Disconnect(Task)
	local type = typeof(Task)
	local isTable = type == "table"

	local isDisconnect = type == "RBXScriptConnection" or (isTable and Task.Disconnect)

	if not isDisconnect then
		return
	end

	return Task:Disconnect()
end

function garbageCollector:onCleanUp(Callback)
	table.insert(self.cleanups, Callback)
	return self
end

function garbageCollector:Clean(_task)
	for i, v in self.cleanups do
		v(self)
	end
	
	if self.Debug then
		warn(
			("x%d tasks being cleaned."):format(#self.Tasks)
		)
	end
	
	for i, v in self.Tasks do
		self:Destroy(v)
		self:Cancel(v)
		self:Disconnect(v)
	end
	
	table.clear(self.Tasks)
end

function garbageCollector:add(_task)
	if self.Debug then warn(("gave 1 new task, %dx tasks now in store."):format(#self.Tasks+1)) end
	table.insert(self.Tasks, _task)
	return _task -- <- doesn't return self, shall return recent task.
end

function garbageCollector.new(Debug)
	return setmetatable({
		Tasks = {},
		cleanups = {},
		Debug = Debug
	}, garbageCollector)
end

return garbageCollector