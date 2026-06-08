local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local PetModule = Services.get("PetModule")
local SerialService = Services.get("SerialService")
local DiscordService = Services.get("DiscordService")

local PetsSerial = SerialService.new("Pets", "1")

return function(self, Player, PetData, Notify)
	if typeof(PetData) ~= "table" then
		return
	end

	local PlayerData = self:GetPlayerData(Player)

	if not PlayerData then
		return
	end

	local Pets = PlayerData.Pets

	PetData.ID = PetData.ID or HttpService:GenerateGUID(false)
	PetData.Name = PetData.Name or PetData.Item or "Doggy"
	PetData.Tier = PetData.Tier or "Normal"
	PetData.Exp = PetData.Exp or 0
	PetData.Level = PetData.Level or 1
	PetData.Locked = PetData.Locked or false
	PetData.Equipped = false
	PetData.Egg = PetData.Egg or "Common Egg"
	-- Preserve the supplied Enchant, or nil if none. Do NOT hard-code to "Warrior" anymore.
	PetData.Enchant = PetData.Enchant

	-- Validate the pet name against the catalog — an unknown name would error on PetModule[...]
	local PetCatalogEntry = PetModule[PetData.Name]
	if not PetCatalogEntry then
		warn(("[DataService:GivePet] Unknown pet name %q — request rejected"):format(tostring(PetData.Name)))
		return
	end

	local _name = PetData.Tier == "Normal" and PetData.Name or ("%s%s"):format(PetData.Tier, PetData.Name)
	local NewPet = not table.find(PlayerData.Index, _name)

	if NewPet then
		table.insert(PlayerData.Index, _name)
		self:SendUpdateSignal(Player, "Index")
	end

	if table.find(PlayerData.AutoDelete, PetData.Name) and not PetData.CantAutoDelete then
		return
	end

	local _Rarity = PetCatalogEntry.Rarity
	local _Serial = (PetsSerial:Fetch(_name) or 0) + 1

	table.insert(Pets, PetData)

	if _Rarity == "Secret" or PetData.StockPet then
		PetsSerial:FireGlobal(_name)
	else
		PetsSerial:AddToQueue(_name)
	end

	if PetData.Hatched and _Rarity == "Secret" then
		task.spawn(function()
			DiscordService:SecretHatched(
				Player.Name,
				PetData.Tier,
				_Rarity,
				PetData.Name,
				PetData.Chance,
				PetData.Egg,
				_Serial,
				self
			)
		end)
	end

	PetData.Hatched = nil
	PetData.StockPet = nil
	PetData.CantAutoDelete = nil

	local idx = #Pets

	self:SendUpdateSignal(Player, "Pets")

	if Notify then
		Network:Post(Player, "DisplayNewItem", {
			Type = "Message",
			Message = ("You've received a %s"):format(PetData.Name),
			TextColor = _Rarity
		})
	end

	return Pets[idx], NewPet
end
