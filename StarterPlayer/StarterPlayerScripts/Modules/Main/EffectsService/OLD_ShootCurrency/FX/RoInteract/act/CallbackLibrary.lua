local Library = {}

Library.wait = {
	arguments = {
		[1] = {
			Decription = "duration for wait time.",
			Class = "number"
		}
	},
	
	callback = function(self, ...)
		-- warn(("waiting %d seconds..."):format(...))
		
		wait(...)
		
		-- warn(("ok, %d seconds is up."):format(...))
	end,
}

Library.Destroy = {
	arguments = {},
	
	callback = function(self)
		local Object = self.Object
		
		if not Object then
			return
		end
		
		Object:Destroy()
	end,
}

Library.GiveCurrency = {
	arguments = {
		[2] = {
			Description = "Currency",
			Class = "string"
		},
		
		[3] = {
			Description = "Amount",
			Class = "number"
		}
	},
	
	callback = function(self, Currency, Amount)
		local Player = self.Player

		local leaderstats = Player and Player:FindFirstChild("leaderstats")
		local Value = leaderstats and leaderstats:FindFirstChild(Currency)
		
		if not Value then
			return
		end
		
		Value.Value += Amount
	end,
}

return Library