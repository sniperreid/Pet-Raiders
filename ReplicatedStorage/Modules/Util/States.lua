----------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------

local Assets = ReplicatedStorage:WaitForChild("Assets")
local States_Folder = Assets:WaitForChild("LocalStates")

----------------------------------------------------

local States = {}

function States.new(Player)
	local Player_ID = (typeof(Player) == "number") and Player or Player.UserId
	
	if States_Folder:FindFirstChild(Player_ID) then
		return
	end
	
	local State_Holder = Instance.new("Configuration")
	State_Holder.Parent = States_Folder
	State_Holder.Name = Player_ID
end

function States.set(Player, State, Value)
	local Player_ID = (typeof(Player) == "number") and Player or Player.UserId

	local State_Holder = States_Folder:WaitForChild(Player_ID)
	
	State_Holder:SetAttribute(State, Value)
end

function States.add(Player, State, Value)
	local Player_ID = (typeof(Player) == "number") and Player or Player.UserId
	
	local State_Holder = States_Folder:WaitForChild(Player_ID)
	
	if (States.has(Player, State) == Value) then
		return
	end
	
	State_Holder:SetAttribute(State, Value)
end

function States.has(Player, State)
	local Player_ID = (typeof(Player) == "number") and Player or Player.UserId

	local State_Holder = States_Folder:WaitForChild(Player_ID)

	return State_Holder:GetAttribute(State)
end

function States.cleanup(Player)
	local Player_ID = (typeof(Player) == "number") and Player or Player.UserId
	
	local State_Holder = States_Folder:WaitForChild(Player_ID)

	State_Holder:Destroy()
end

return States