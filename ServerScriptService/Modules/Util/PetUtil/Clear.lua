return function(t, IDs)
	local t_ = table.clone(t)
	local deleted = {}

	if typeof(IDs) ~= "table" then
		IDs = { IDs }
	end

	local Amount = #IDs
	local Attempts = 0

	repeat
		local MadeProgress = false

		for i = #t, 1, -1 do
			local Pet = t[i]

			for a, ID in IDs do
				if Pet.ID ~= ID then
					continue
				end

				if Pet.Locked then
					table.remove(IDs, a)
					Amount -= 1
					continue
				end

				MadeProgress = true
				Attempts += 1

				table.remove(t, i)
				table.remove(IDs, a)
				table.insert(deleted, Pet)

				break
			end
		end
	until Attempts == Amount or not MadeProgress

	if Attempts ~= Amount then
		return t_
	end

	return deleted
end