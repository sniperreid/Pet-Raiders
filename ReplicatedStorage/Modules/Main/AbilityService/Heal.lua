local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")

return function(Player: Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	
	if not Character then return end

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	
	if not HumanoidRootPart then return end

	local DomePosition = HumanoidRootPart.Position
	local HealAmount = 2
	local TickRate = 0.5
	local Duration = 20
	
	local FloorRayOrigin = HumanoidRootPart.Position + Vector3.new(0, 100, 0)
	local FloorRayDirection = Vector3.new(0, -200, 0)

	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.Assets}
	Params.FilterType = Enum.RaycastFilterType.Include

	local Result = workspace:Raycast(FloorRayOrigin, FloorRayDirection, Params)

	if not Result or not Result.Instance then return end

	if Result.Instance.Name ~= "Grass" then return end

	Network:PostAll("PlayEffectHeal", Result.Position, Duration)

	local EndTime = tick() + Duration
	
	task.spawn(function()
		while tick() < EndTime do
			for _, OtherPlayer in Players:GetPlayers() do
				local OtherCharacter = OtherPlayer.Character

				if OtherCharacter then
					local OtherRootPart = OtherCharacter:FindFirstChild("HumanoidRootPart")
					local Humanoid = OtherCharacter:FindFirstChildOfClass("Humanoid")

					if OtherRootPart and Humanoid and Humanoid.Health > 0 and Humanoid.Health < Humanoid.MaxHealth then
						if (OtherRootPart.Position - DomePosition).Magnitude < 32.5 then
							Humanoid.Health = math.min(Humanoid.MaxHealth, Humanoid.Health + HealAmount)
							
							Network:PostAll("PlayEffectHealPlayer", OtherPlayer)
						end
					end
				end
			end

			task.wait(TickRate)
		end

		Network:PostAll("RemoveStatus", "Healing!")
	end)
	
	return true
end