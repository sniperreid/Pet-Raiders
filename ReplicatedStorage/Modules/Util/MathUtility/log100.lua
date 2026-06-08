return function(n, x)
	return math.log10(
		math.log10(n) * (x or 1)
	)
end