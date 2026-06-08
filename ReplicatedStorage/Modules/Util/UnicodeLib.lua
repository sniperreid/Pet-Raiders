local Unicode = {}
Unicode.utf8 = utf8

function Unicode.valid_utf8(ofString)
	return pcall(function()
		for i = 1, #ofString do
			Unicode.utf8.graphemes(ofString, i, i)()
		end
	end)
end

function Unicode.GetCodePoints(ofString)
	local codepoints = {}
	
	local isValid, Error = Unicode.valid_utf8(ofString)
	
	if not isValid then
		return _G.out(Error)
	end
	
	local isValid, Error = pcall(function()
		for _, point in Unicode.utf8.codes(ofString) do
			table.insert(codepoints, point)
		end
	end)
	
	if not isValid then
		return _G.out("U-GCP: " .. Error)
	end
	
	return codepoints
end

function Unicode.GetUtf8(CodePoints)
	local NewString = ""

	for _, point in ipairs(CodePoints or {}) do
		NewString = NewString .. Unicode.utf8.char(point)
	end

	return NewString
end

return Unicode