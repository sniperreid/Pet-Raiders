local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")

local Roblox = {}

Roblox.writeData = function(i, data)
	for k, v in data do	
		i[k] = v
	end

	return i
end

Roblox.Create = function(objInstance)
	local Inst = Instance.new(objInstance)

	return function(...)
		return Roblox.writeData(Inst, ...)
	end
end

Roblox.ShootRay = function(Origin, Direction, Raycast)
	local Position = Raycast and Raycast.Position or (Origin + Direction)
	local Distance = (Origin - Position).Magnitude
	
	local Part = Instance.new("Part")
	Part.Anchored = true
	Part.CanCollide = false
	Part.CanQuery = false
	Part.CanTouch = false
	Part.CastShadow = false
	Part.Material = Enum.Material.Neon
	Part.Size = Vector3.new(0.1, 0.1, (Origin - Position).Magnitude)
	Part.CFrame = CFrame.new(Origin, Position) * CFrame.new(0, 0, -Distance/2)
	Part.Color = Color3.fromRGB(255, 0, 0)
	Part.Parent = workspace.Terrain
	
	return Part
end

Roblox.Raycast = function(Origin, Direction, Params)
	local Instances = Params.Instances or {}
	
	local Filter = RaycastParams.new()
	Filter.FilterType = Params.FilterType or Enum.RaycastFilterType.Exclude
	
	if Filter.FilterType == Enum.RaycastFilterType.Exclude then
		--table.insert(
		--	Instances,
		--	workspace.Terrain
		--)
	end
	
	Filter.FilterDescendantsInstances = Instances
	
	local Raycast = workspace:Raycast(Origin, Direction, Filter)
	local Pos = Raycast and Raycast.Position or Origin + Direction
	
	if not Raycast then
		return {
			Position = Pos
		}
	end

	if Params.DisplayCaster then
		local Part = Roblox.ShootRay(Origin, Direction, Raycast)
		
		Debris:AddItem(Part, Params.CasterDebris or .1)
	end
	
	return Raycast
end

Roblox.ConeRaycast = function(Origin, Direction, Angle, Range, Params)
	local FoundParts = {}
	
	for _, v in Params do
		local _Origin = v:GetPivot().Position
		Origin = Vector3.new(Origin.X, _Origin.Y, Origin.Z)
		
		local distance = Origin - _Origin
		
		if distance.Magnitude > Range then
			continue
		end
		
		local radians = math.atan2(distance.Z, distance.X)
		local degrees = math.deg(radians) + Direction
		
		if degrees > 180 then
			degrees = -(360-degrees)
		elseif degrees < -180 then
			degrees += 360
		end

		degrees = math.abs(degrees)

		if (degrees > Angle/2) then
			continue
		end
		
		table.insert(
			FoundParts,
			v
		)
	end
	
	return FoundParts
end

Roblox.HasObjectUnder = function(Object, Filter)
	local isModel = Object:IsA("Model")
	local isPart = Object:IsA("BasePart")

	local Pos = (isModel and Object:GetPivot() or Object.CFrame).Position
	local Size = isModel and Object:GetExtentsSize() or Object.Size
	
	table.insert(
		Filter, Object
	)

	local Origin = Pos

	local Raycast = Roblox.Raycast(
		Origin + Vector3.new(0, .3, 0),
		Vector3.new(0, -.6, 0),
		{
			Instances = Filter
		}
	)

	return Raycast and Raycast.Instance
end

Roblox.Canvas = {
	GetMiddle = function(canvas, frame)
		local canvasPos = canvas.AbsolutePosition
		local frameSize = frame.AbsoluteSize
		
		return Vector2.new(
			canvasPos.X + (frameSize.X/2),
			canvasPos.Y + (frameSize.Y/2)
		)
	end,
	
	DistanceFromFrame = function(canvas, frame)
		local framePos = frame.AbsolutePosition
		
		local Mid = Roblox.Canvas.GetMiddle(canvas, frame)

		return Vector2.new(
			Mid.X - framePos.X,
			Mid.Y - framePos.Y
		)
	end,
	
	LerpTo = function(canvas, frame, delta)
		local canvasPos = canvas.CanvasPosition
		
		local DistanceFromFrame = Roblox.Canvas.DistanceFromFrame(canvas, frame)
		
		canvas.CanvasPosition = canvasPos:Lerp(
			Vector2.new(
				canvasPos.X - DistanceFromFrame.X,
				canvasPos.Y - DistanceFromFrame.Y
			),
			delta or 1
		)
	end,
}

Roblox.Core = {
	UpdateCoreSettings = function(Core, Value)
		if typeof(Core) == "string" then
			Core = Enum.CoreGuiType[Core]
		end
		
		StarterGui:SetCoreGuiEnabled(Core, Value)
	end,
}

function Roblox:GetDescendantsOfClass(obj, class)
	local List = {}

	for _, nobj in obj:GetDescendants() do
		if not nobj:IsA(class) then
			continue
		end

		table.insert(
			List,
			nobj
		)
	end

	return List
end

function Roblox:GetChildrenOfClass(obj, class)
	local List = {}
	
	for _, nobj in obj:GetChildren() do
		if not nobj:IsA(class) then
			continue
		end
		
		table.insert(
			List,
			nobj
		)
	end
	
	return List
end

function Roblox:ClearChildrenOfClass(obj, class)
	for _, nobj in Roblox:GetChildrenOfClass(obj, (class or "Frame")) do
		nobj:Destroy()
	end
end

function Roblox.readRoot(Descendant, Tree)
	if not Descendant then
		return
	end
	
	if Tree.HasAttribute and not Descendant:GetAttribute(Tree.HasAttribute) then
		return
	end

	if Tree.Class and not Descendant:IsA(Tree.Class) then
		return
	end

	for _, Find in Tree.Has or {} do
		if not Descendant:FindFirstChild(Find) then
			return
		end
	end

	return true
end

function Roblox.filterFromTree(Root, Tree)
	local Descendant = Root
	local Attempt = 0
	local MaxAttempts = 15
	
	while true do
		Attempt += 1

		if Attempt > MaxAttempts then
			break
		end

		if not Descendant or Descendant == workspace or Descendant == game then
			break
		end

		if Roblox.readRoot(Descendant, Tree) then
			break
		end

		-- Walk up the ancestry from the current node (was 'Root.Parent', which never moved)
		Descendant = Descendant.Parent
	end

	return Descendant
end

function Roblox.filterMakeTree(Root, Tree)
	local Tree = Tree or {}
	local Tree = {
		HasAttribute = Tree.HasAttribute or "Health",
		Class = Tree.Class,
		Has = Tree.Has,
		isAlsoIn = Tree.isAlsoIn or Players
	}
	
	if not Root then
		return
	end

	return Roblox.filterFromTree(Root, Tree)
end

return Roblox