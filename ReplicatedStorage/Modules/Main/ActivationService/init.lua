local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Activations = workspace.Activations:GetChildren()
local Callbacks = script:GetChildren()

local ActivationService = { }

ActivationService.Activations = {
	Client = { },
	Server = { }
}

function ActivationService:GetType()
	return RunService:IsClient() and "Client" or "Server"
end

function ActivationService:GetCallback(Activation)
	for _, Callback in Callbacks do
		if not string.match(Activation, Callback.Name) then
			continue
		end

		Callback = require(Callback)
		
		if Callback.Type ~= self:GetType() then
			continue
		end

		return Callback
	end
end

function ActivationService:PendRequest(Activation, Character)
	local Player = Players:GetPlayerFromCharacter(Character)
	
	if RunService:IsClient() and Player ~= Players.LocalPlayer then
		return
	end
	
	if not Player then
		return
	end
	
	local Activations = self.Activations
	local Type = self:GetType()
	local GetType = Activations[Type]
	local GetCallback = GetType[Activation]
	
	return Player, GetCallback
end

function ActivationService:GiveActivation(Activation)
	local Callback = self:GetCallback(Activation.Name)

	if not Callback then
		return
	end
	
	local Activations = self.Activations
	local Type = self:GetType()
	
	Activations[Type][Activation] = Callback
	
	local Collision = Activation.PrimaryPart or Activation:FindFirstChild("Collision")
	
	if not Collision then
		return
	end
	
	Callback.init(
		Activation
	)
	
	Collision.Touched:Connect(function(Hit)
		local Player, GetCallback = self:PendRequest(Activation, Hit.Parent)
		
		if not GetCallback then
			return
		end
		
		GetCallback.Callback(Player, Activation)
	end)
end

for _, Activation in Activations do
	ActivationService:GiveActivation(Activation)
end

return ActivationService