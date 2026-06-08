local TweenService = game:GetService("TweenService")

local TweenModelService = {}

function TweenModelService:Create(Model: Model, TweenInfo: TweenInfo, TeleportTo: any)
	if not Model.PrimaryPart then
		warn("Model must have a PrimaryPart in order to be tweened properly. The tween returned as nil.")
		return nil
	end
	
	local WeldTable = {}
	local PartAnchoredState = {}
	
	for _, Part in Model:GetDescendants() do
		if Part:IsA("BasePart") then
			local WeldConstraint = Instance.new("WeldConstraint")
			WeldConstraint.Enabled = false
			WeldConstraint.Part0 = Part
			WeldConstraint.Part1 = Model.PrimaryPart
			WeldConstraint.Parent = Part
			table.insert(WeldTable, WeldConstraint)
			PartAnchoredState[Part] = Part.Anchored
		end
	end
	
	local Tween = TweenService:Create(Model.PrimaryPart, TweenInfo, TeleportTo)		
	
	local ModelTween = {}
	
	local function RevertStateOfModel(Message)
		for _, WeldConstraint in WeldTable do
			WeldConstraint.Enabled = false
			if Message == "DestroyWelds" then
				WeldConstraint:Destroy()
			end
		end
		for _, PartsInModel in Model:GetDescendants() do
			if PartsInModel:IsA("BasePart") then
				PartsInModel.Anchored = PartAnchoredState[PartsInModel]
			end
		end
	end
	
	function ModelTween:Play()
		for _, WeldConstraint in WeldTable do
			WeldConstraint.Enabled = true
		end
		for _, PartsInModel in Model:GetDescendants() do
			if PartsInModel:IsA("BasePart") then
				PartsInModel.Anchored = false
			end
		end
		Tween.Completed:Once(function()
			RevertStateOfModel()
		end)
		Model.PrimaryPart.Anchored = true
		Tween:Play()
	end
	
	function ModelTween:Pause()
		Tween:Pause()
	end
		
	function ModelTween:Cancel()
		Tween:Cancel()
		RevertStateOfModel()
	end
	
	function ModelTween:Destroy()
		Tween:Destroy()
		RevertStateOfModel("DestroyWelds")
	end
	
	ModelTween.TweenInfo = Tween.TweenInfo
	ModelTween.Instance = Model
	
	ModelTween.Welds = WeldTable
	ModelTween.PlaybackState = Tween.PlaybackState
	Tween:GetPropertyChangedSignal("PlaybackState"):Connect(function()
		ModelTween.PlaybackState = Tween.PlaybackState
	end)
	
	ModelTween.Completed = Tween.Completed
	
	return ModelTween
end

return TweenModelService