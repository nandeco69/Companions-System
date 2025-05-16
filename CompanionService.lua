local Players = game:GetService("Players")
local ReS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local SSS = game:GetService("ServerScriptService")

local CompanionConfig = require(ReS:WaitForChild("Config"):WaitForChild("CompanionConfig"))

local CompanionAttackRemote = ReS:WaitForChild("Remotes"):WaitForChild("CompanionAttack")

local MAX_COMPANIONS = CompanionConfig.MAX_COMPANIONS
local PlayerCompanions = {}

local Local = {}
local Shared = {}

function Shared.OnStart()
	RS.Heartbeat:Connect(Local.UpdateCompanionPositions)

	Players.PlayerRemoving:Connect(function(player: Player)
		local Companions = PlayerCompanions[player]
		if Companions then
			for _, Model in pairs(Companions) do
				if Model then Model:Destroy() end
			end

			PlayerCompanions[player] = nil
		end
	end)

	CompanionAttackRemote.OnServerEvent:Connect(function(player: Player, enemy, damage)
		if typeof(enemy) ~= "Instance" or not enemy:IsA("Model") or not enemy:FindFirstChild("Humanoid") then return end
		if not enemy:FindFirstChild("HumanoidRootPart") then return end
		if not enemy:IsDescendantOf(workspace) then return end
		if not damage or typeof(damage) ~= "number" then return end

		local Companions = PlayerCompanions[player]
		if not Companions then return end

		for _, Companion in ipairs(Companions) do
			if Companion:FindFirstChild("HumanoidRootPart") then
				local Distance = (Companion.HumanoidRootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
				if Distance <= CompanionConfig.ATTACK_RADIUS then
					local Tag = Instance.new("ObjectValue")
					Tag.Name = "Creator"
					Tag.Value = player
					Tag.Parent = enemy.Humanoid
					game.Debris:AddItem(Tag, 10)

					local EnemyService = require(SSS.Services.EnemyService)
					EnemyService.DealDamage(enemy, damage, player)
					break
				end
			end
		end
	end)
end

function Local.SpawnCompanion(player: Player)
	if not player:IsA("Player") then
		warn("[CompanionService] SpawnCompanion: invalid player passed:", player)
		return
	end

	local Companions = PlayerCompanions[player] or {}
	if #Companions >= MAX_COMPANIONS then return end

	local Char = player.Character
	if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end

	local function SetArchivable(model, value)
		model.Archivable = value
		for _, Object in pairs(model:GetDescendants()) do
			if typeof(Object) == "Instance" then
				Object.Archivable = value
			end
		end
	end

	SetArchivable(Char, true)
	local Clone = Char:Clone()
	SetArchivable(Char, false)

	local Safename = (player and player.Name) or "Unknown"
	Clone.Name = Safename .. "_Companion" .. (#Companions + 1)

	for _, Object in ipairs(Clone:GetDescendants()) do
		if Object:IsA("Script") or Object:IsA("LocalScript") then
			Object:Destroy()
		end
	end

	local Human = Clone:FindFirstChildOfClass("Humanoid")
	if Human then
		Human.WalkSpeed = 17
		Human.PlatformStand = false 
		Human:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
		Human:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
		Human:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		Human:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
		Human:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
		Human:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		Human:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
		Human:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		Human:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
	end

	local HRP = Clone:FindFirstChild("HumanoidRootPart")
	if HRP then
		local behind = Char.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
		Clone:PivotTo(behind)
		HRP.Anchored = false
	end

	for _, Part in ipairs(Clone:GetDescendants()) do
		if Part:IsA("BasePart") and (Part.Name == "UpperTorso" or Part.Name == "LowerTorso" or Part.Name == "HumanoidRootPart" or Part:IsDescendantOf(Clone) or Part:IsA("MeshPart")) then
			Part.CanCollide = false
			Part.Massless = true
		elseif Part:IsA("Accessory") then
			local Handle = Part:FindFirstChild("Handle")
			if Handle and Handle:IsA("BasePart") then
				Handle.CanCollide = false
				Handle.Massless = true
			end
		end
	end
	
	Clone:SetAttribute("IsCompanion", true)
	Clone.Parent = workspace
	
	task.spawn(function()
		local Animate = require(ReS:WaitForChild("Animations"):WaitForChild("CompanionAnimate"))
		if Human then Animate.ApplyTo(Human) end
	end)

	local RegisterRemote = ReS.Remotes:WaitForChild("RegisterCompanion")
	RegisterRemote:FireClient(player, Clone)

	table.insert(Companions, Clone)
	PlayerCompanions[player] = Companions
end

function Local.CalculateCompanionPosition(index, total, rootcframe)
	local OffSet = CompanionConfig.GetCompanionPosition(index, total)
	local Back = rootcframe.LookVector * OffSet.Z
	local Right = rootcframe.RightVector * OffSet.X
	return rootcframe.Position - Back + Right
end

function Local.UpdateCompanionPositions()
	for Player, Companions in pairs(PlayerCompanions) do
		local Char = Player.Character
		if not Char or not Char:FindFirstChild("HumanoidRootPart") then continue end

		local Root = Char.HumanoidRootPart
		local RootCFrame = Root.CFrame
		local Total = #Companions

		for Index, Companion in ipairs(Companions) do
			local HRP = Companion:FindFirstChild("HumanoidRootPart")
			local CompanionHumanoid = Companion:FindFirstChildOfClass("Humanoid")
			if not HRP or not CompanionHumanoid then continue end
			
			local TargetPosXZ = Local.CalculateCompanionPosition(Index, Total, RootCFrame)
			local RayOrigin = TargetPosXZ + Vector3.new(0, 5, 0)
			local RayDirection = Vector3.new(0, -20, 0)

			local Params = RaycastParams.new()
			Params.FilterType = Enum.RaycastFilterType.Exclude
			Params.FilterDescendantsInstances = {Companion, Char}

			local Result = workspace:Raycast(RayOrigin, RayDirection, Params)
			if Result then
				local Y = Result.Position.Y + 3
				local TargetPos = Vector3.new(TargetPosXZ.X, Y, TargetPosXZ.Z)
				if (HRP.Position - TargetPos).Magnitude > 1 then
					CompanionHumanoid:MoveTo(TargetPos)
				end
				
				local HeightDiff = TargetPos.Y - HRP.Position.Y
				if HeightDiff > 3 then
					CompanionHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end
	end
end

function Shared.AddCompanion(player: Player)
	if not player then
		warn("[CompanionService] AddCompanion called with NIL player")
		return
	end

	Local.SpawnCompanion(player)
end

return Shared

