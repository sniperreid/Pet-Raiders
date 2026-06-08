-- Services
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ReplicatedModules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(ReplicatedModules:WaitForChild("Services"))

-- Instances
local spawnedObjects = workspace.Terrain

-- Modules
local GeneralUse = Services.get("GeneralUse")
local NumberHelper = Services.get("NumberHelper")
local PartChache = Services.get("PartCache")

-- Variables
local baseRock = Instance.new("Part")
baseRock.Color = Color3.fromRGB(99, 95, 98)
baseRock.Material = Enum.Material.Slate
baseRock.CanCollide = false
baseRock.CanTouch = false
baseRock.CanQuery = false
baseRock.Anchored = true

local rockPartChache = PartChache.new(baseRock,100,workspace.Terrain)
local rockTopPartChache = PartChache.new(baseRock,100,workspace.Terrain)

local BaseEffects = {}

local function doSurfaceRaycast(surfaceCF:CFrame)
    return GeneralUse.GetFirstCollidable(surfaceCF.Position,surfaceCF.UpVector*-100)
end

--[[local function generateDebugPart(cf,size)
    local part = Instance.new("Part")
    part.Size = size
    part.CFrame = cf
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Parent = spawnedObjects
    Debris:AddItem(part,5)
end--]]
local function getSurfaceCF(baseCF:CFrame)
    baseCF = baseCF * CFrame.new(0,2,0)
    local function getRaycastPosition(cfChange:CFrame)
        local startCF = baseCF*cfChange

        local raycastDirecton = baseCF.UpVector*-10
        local result = GeneralUse.GetFirstCollidable(startCF.Position,raycastDirecton)
        local endPos = (result and result.Position) or (startCF*CFrame.new(0,-2,0)).Position

        --[[ local dist = (startCF.Position-endPos).Magnitude
        generateDebugPart(CFrame.new(startCF.Position,endPos)*CFrame.new(0,0,-dist/2),Vector3.new(.2*.1,.2*.1,dist))
        generateDebugPart(startCF,Vector3.new(.3,.3,.3)*.1)
        generateDebugPart(CFrame.new(endPos),Vector3.new(.5,.5,.5)*.1)--]]
        return endPos,result
    end

    local rightPos,leftPos = getRaycastPosition(CFrame.new(.1,0,0)),getRaycastPosition(CFrame.new(-.1,0,0))
    local upPos,downPos = getRaycastPosition(CFrame.new(0,0,-.1)),getRaycastPosition(CFrame.new(0,0,.1))
    local centerPos,centerResult = getRaycastPosition(CFrame.new(0,0,0))
    local rightVector = CFrame.new(leftPos,rightPos).LookVector
    local upVector = CFrame.new(downPos,upPos).LookVector
    
    local surfaceCF = CFrame.fromMatrix(centerPos,rightVector,upVector)
    return surfaceCF*CFrame.Angles(math.pi/2,0,0),centerResult
end
    
function BaseEffects.CreateRockLine(lineStartCF:CFrame,distance:number,totalRocks:number,baseRockSize:number,baseSideDistance:number,baseRotAngle:number,baseExpandTime)
    baseExpandTime = baseExpandTime or .3
    local function createFloorRocks(middleCF:CFrame,sideDistance:number,rotAngle:number,size:Vector3,expandTime)
        local startCF = middleCF - Vector3.new(0,size.Y/2,0)
        local result = GeneralUse.GetFirstCollidable(startCF.Position)
        if result then
            startCF = startCF-startCF.Position+result.Position
        end
        local destroyWait = 4*NumberHelper.Random()
        local destroyTime = .6*NumberHelper.Random()
        for _,mut in {1,-1} do
            
            local endCF:CFrame = startCF*CFrame.new(sideDistance*mut,0,0)*CFrame.Angles(0,0,rotAngle*mut)
            local inGroundCF:CFrame = endCF - Vector3.new(0,size.Magnitude,0)
            
            BaseEffects.CreateRock(result,size,startCF,endCF,inGroundCF,expandTime,destroyWait,destroyTime)
        end
    end

    for rockNum = 1,totalRocks do
        local middleCF = lineStartCF*CFrame.new(0,0,-distance*(rockNum/totalRocks) + distance*.05*NumberHelper.Random(-1,1))

        local rockSize = baseRockSize*Vector3.new(NumberHelper.Random(),NumberHelper.Random(),NumberHelper.Random())
        local sideDistance = baseSideDistance * NumberHelper.Random()
        createFloorRocks(middleCF,sideDistance,baseRotAngle*NumberHelper.Random(),rockSize,baseExpandTime*NumberHelper.Random())
    end
end
function BaseEffects.CreateRock(floorRaycast:RaycastResult,rockSize:Vector3,startCF:CFrame,endCF:CFrame,inGroundCF:CFrame,expandTime:number,destroyWait:number,destroyTime:number)
    local groundRock = rockPartChache:GetPart()
    groundRock.Size = rockSize*.1
    groundRock.CFrame = startCF

    local rockTop = rockTopPartChache:GetPart()
    if floorRaycast then
        local hitPart:BasePart = floorRaycast.Instance
        rockTop.Color = hitPart.Color
        rockTop.Material = hitPart.Material
    end
    
    local function updateRockTop()
        local groundRockSize = groundRock.Size
        rockTop.Size = Vector3.new(groundRockSize.X, groundRockSize.Y*.2, groundRockSize.Z)
        rockTop.CFrame = groundRock.CFrame + groundRock.CFrame.UpVector * (groundRockSize.Y/2 + rockTop.Size.Y/2)
    end
    updateRockTop()
    TweenService:Create(groundRock,TweenInfo.new(expandTime),{Size = rockSize,CFrame = endCF}):Play()
    local changed = groundRock.Changed:Connect(function()
        updateRockTop()
    end)
    task.delay(destroyWait,function()
        TweenService:Create(groundRock,TweenInfo.new(destroyTime,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size = Vector3.new(0,0,0),CFrame = inGroundCF}):Play()
        
		task.wait(destroyTime)
		
		changed:Disconnect()
		
        rockPartChache:ReturnPart(groundRock)
		rockTopPartChache:ReturnPart(rockTop)
    end)
end

type GroundExpandV2Opts = {
    ["baseLength"]:number;
    ["baseHeight"]:number;
    ['expandTime']:number;
    ['baseDestroyWait']:number;
    ['destroyTime']:number;
}
function BaseEffects.GroundExpandV2(circleCenter:CFrame,radius:number,rockCount:number,optSettings:GroundExpandV2Opts)
    optSettings = (optSettings or {})::GroundExpandV2Opts

    local baseWidth = (radius*2*math.pi)/rockCount
    local baseHeight = optSettings.baseHeight or  baseWidth*.4
    local baseLength = optSettings.baseLength or baseWidth
    local expandTime = optSettings.expandTime or .3
    local baseDestroyWait = optSettings.baseDestroyWait or 2
    local destroyTime = optSettings.destroyTime or .6
    
    local function random(min,max)
        return Random.new():NextNumber(min or .8,max or 1.2)
    end
  

    circleCenter = getSurfaceCF(circleCenter)
    for rockNum = 1,rockCount do
        local rotation = (360/rockCount * rockNum) + random(-20,20)
        local rockWidth =  baseWidth * random()
        local rockHeight = baseHeight * random()
        local rockLength = baseLength * random()
        local rockSize = Vector3.new(rockWidth,rockHeight,rockLength)

        local distMut = random(.8,1.5)
        local rotAmount = -random(20,40)

        local floorPos
        local function getRockCF(distFromCenter:number):CFrame
            local rockCF = (circleCenter* CFrame.Angles(0,math.rad(rotation),0) * CFrame.new(distFromCenter*distMut,0,0))
            rockCF = rockCF

            return rockCF* CFrame.Angles(0,math.pi/2,0) * CFrame.Angles(math.rad(rotAmount),0,0)
        end
        local function setToFloorPos(cf:CFrame):CFrame
            if floorPos then
                cf = cf-cf.p + Vector3.new(cf.p.X,floorPos.Y,cf.p.Z) + circleCenter.UpVector*(-rockSize.Y*.3)
            end
            return cf
        end
        local finalCF = getRockCF(rockLength/2 + radius)
        
        local result = GeneralUse.GetFirstCollidable(finalCF.Position,circleCenter.UpVector*-100)
        if result then
            floorPos = result.Position
        end
        finalCF = setToFloorPos(finalCF)

		local startCF = setToFloorPos(getRockCF(.01))
		
        BaseEffects.CreateRock(
            result,
            rockSize,
            startCF,
            finalCF,
            finalCF + circleCenter.UpVector*-rockSize.Y,
            expandTime*random(),
            baseDestroyWait*random(),
            destroyTime
        )
    end
end

type SurfaceImageOpts = {
    colorFadeTime:number,
    expandTime:number,
    stayTime:number,
    fadeTime:number,
    surfaceRaycast:RaycastResult
}
function BaseEffects.CreateSurfaceImage(imageId:(number|string),surfaceCF:CFrame,surfaceEndWidth:Vector3,startColor:Color3,endColor:Color3,optSettings:SurfaceImageOpts)
    optSettings = optSettings or {}

    local surfaceImagePart:Part = ReplicatedStorage.Assets.Misc.BaseEffects.SurfaceImagePart:Clone()
    local image:ImageLabel = surfaceImagePart.SurfaceGui.Image
    image.Image = if type(imageId) == 'string' then imageId else "rbxassetid://" .. imageId

    local centerResult
    surfaceCF,centerResult= getSurfaceCF(surfaceCF)
    surfaceCF*=CFrame.Angles(0,NumberHelper.RandomRotation(),0)
    surfaceImagePart.CFrame = surfaceCF
    surfaceImagePart.Size = optSettings.startSize or Vector3.new(0,0,0)
    image.ImageColor3 = startColor
    TweenService:Create(image,TweenInfo.new(optSettings.colorFadeTime or .4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{ImageColor3 = endColor}):Play()
    TweenService:Create(surfaceImagePart,TweenInfo.new(optSettings.expandTime or .6,Enum.EasingStyle.Quint),{Size = Vector3.new(surfaceEndWidth,0,surfaceEndWidth)}):Play()
    task.delay(optSettings.stayTime or 2,function()
        local fadeTime = optSettings.fadeTime or .6
        TweenService:Create(image,TweenInfo.new(fadeTime),{ImageTransparency = 1}):Play()
        Debris:AddItem(surfaceImagePart,fadeTime)
    end)

    surfaceImagePart.Parent = spawnedObjects

    return surfaceImagePart,centerResult
end

function BaseEffects.GroundScorch(explosionCF:CFrame,explosionSize:number,startColor:Color3,optSettings:SurfaceImageOpts):Part
    optSettings = optSettings or {}

    local scorchPart,result = BaseEffects.CreateSurfaceImage(14753845853,explosionCF,explosionSize*3,startColor,Color3.new(0,0,0),optSettings)
    scorchPart.SurfaceGui.Brightness = 10

    return scorchPart,result
end

function BaseEffects.GroundCrack(crackCF:CFrame,crackSize:number,startColor:Color3,optSettings:SurfaceImageOpts):Part
    optSettings = optSettings or {}
    
    local result = optSettings.surfaceRaycast or doSurfaceRaycast(crackCF)
    local endColor = if result then result.Instance.Color else Color3.new(0,0,0)
   
    optSettings.surfaceRaycast = result
    local scorchPart = BaseEffects.CreateSurfaceImage(14979210924,crackCF,crackSize*3,startColor,endColor,optSettings)
    scorchPart.SurfaceGui.Brightness = 1

    return scorchPart,result
end

return BaseEffects