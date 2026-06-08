local MetaKey = "__"
local DefaultMeta = "index"

local _Method = function(a)
	a = a or DefaultMeta
	
	return ("%s%s"):format(MetaKey, a)
end

return {
	getMethod = _Method,
	set = function(a, b, method)
		method = _Method(method)

		b[method] = b

		return setmetatable(a, b)
	end,
}