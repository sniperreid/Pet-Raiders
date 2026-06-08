local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local States = Services.get("States")

return function(Player: Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	if not Character then return end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end

	local Duration = 10
	
	States.add(Player, "Shield", true)

	Network:PostAll("PlayEffectBubble", Character, Duration)
	
	Network:Post(Player, "DisplayStatus", {
		Status = "Protected!",
		TextColor = Color3.fromRGB(82, 215, 255),
		Duration = Duration
	})

	task.delay(Duration, function()
		if Character and Character.Parent then
			States.set(Player, "Shield", nil)
		end
	end)
	
	return true
end