--!strict

return function(p0: Vector3, p1: Vector3, p2: Vector3)
	return function(t: number)
		return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
	end
end