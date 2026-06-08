local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local ImageModule = Services.get("ImageModule")
local Short = Services.get("Short")
local AnimationService = Services.get("AnimationService")
local CurrencyModule = Services.get("CurrencyModule")

local GuiService

local Module = {}

local Prefix = {
	["Clicks"] = "Click %s Times",
	["Eggs Hatched"] = "Hatch %s Eggs",
}

function Module:Create(PlayerData, Data, Grid, ...)
	local Type, _Data = unpack(Data)
	local Amount, Rewards = _Data.Amount, _Data.Rewards
	
	local Template = Grid:FindFirstChild(Amount .. Type)
	
	if not Template then
		Template = script.Template:Clone()
		Template.Parent = Grid
		Template.Name = (Amount .. Type)
		Template.LayoutOrder = Amount
	end
	
	local _Content = Template.Content
	
	local _Bar = _Content.Bar
	local _Title = _Content.Title
	local _Claim  = _Content.Claim
	local _Icon = _Content.Icon
	
	local PlayerAmount = PlayerData and PlayerData[Type] or 0
	
	if CurrencyModule[Type] then
		PlayerAmount = PlayerData and PlayerData["Total" .. Type] or 0
	end
	
	local CanClaim = PlayerAmount >= Amount
	
	local SelectedColor = Color3.fromRGB(123, 253, 87)
	local UnselectedColor = Color3.fromRGB(140, 140, 140)
	
	_Claim.Content.BackgroundColor3 = CanClaim and SelectedColor or UnselectedColor
	
	if PlayerData.Rewards[Amount .. Type] then
		_Claim.Content.BackgroundColor3 = UnselectedColor
		_Claim.Content.Letter.Text = "Claimed"
	end
	
	_Title.Text = Prefix[Type]:format(Short:AddSuffix(Amount))
	_Icon.Image = ImageModule(Type)
	
	_Bar.Color.Size = UDim2.fromScale(math.clamp(PlayerAmount / Amount, 0, 1), 1)
	_Bar.Progress.Text = ("%s / %s  |  %s%%"):format(Short:AddSuffix(math.clamp(PlayerAmount, 0, Amount)), Short:AddSuffix(Amount), math.floor((math.clamp(PlayerAmount / Amount, 0, 1) * 100) + 0.5))
	
	return Template
end

function Module:Give(GS)
	GuiService = GS

	return self
end

return function(Type, GSQ, ...)
	if Type == "Give" then
		return Module:Give(GSQ)
	end

	return Module:Create(Type, GSQ, ...)
end