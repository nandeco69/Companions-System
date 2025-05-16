local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local CS = game:GetService("CollectionService")
local PFS = game:GetService("PathfindingService")

local PunchAnimation = ReS:WaitForChild("Animations"):WaitForChild("Animation")

local CompanionAttackRemote = ReS:WaitForChild("Remotes"):WaitForChild("CompanionAttack")

local CompanionConfig = require(ReS:WaitForChild("Config"):WaitForChild("CompanionConfig"))

local Companions = {}
local LastPathUpdate = {}
local CompanionTimers = {}

local Local = {}
local Shared = {}

function Shared.OnStart()
	UIS.InputBegan:Connect(Local.OnInput)
	
	RS.Heartbeat:Connect(Local.FollowPlayer)
	
	ReS.Remotes:WaitForChild("RegisterCompanion").OnClientEvent:Connect(function(companionModel)
		Shared.RegisterCompanion(companionModel)
	end)
end

function Shared.RegisterCompanion(companionmodel)
	table.insert(Companions, companionmodel)
end

function Local.CalculateCompanionPosition(index, total, rootcframe)
	local OffSet = CompanionConfig.GetCompanionPosition(index, total)
	local Back = rootcframe.LookVector * OffSet.Z
	local Right = rootcframe.RightVector * OffSet.X
	return rootcframe.Position - Back + Right
end

function Local.FollowPlayer()
	local Char = Player.Character
	if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end

	local Root = Char.HumanoidRootPart
	local RootCFrame = Root.CFrame
	local Total = #Companions
	local FollowDistance = 5 

	for i, Companion in ipairs(Companions) do
		local HRP = Companion:FindFirstChild("HumanoidRootPart")
		local Human = Companion:FindFirstChildOfClass("Humanoid")
		if not HRP or not Human then continue end

		local TargetPos = Local.CalculateCompanionPosition(i, Total, RootCFrame)

		local RayOrigin = TargetPos + Vector3.new(0, 5, 0)
		local RayDir = Vector3.new(0, -20, 0)
		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude
		Params.FilterDescendantsInstances = {Companion, Char}
		local Result = workspace:Raycast(RayOrigin, RayDir, Params)

		local GroundY = Result and Result.Position.Y + 3 or HRP.Position.Y
		local FinalPosition = Vector3.new(TargetPos.X, GroundY, TargetPos.Z)

		local Distance = (HRP.Position - FinalPosition).Magnitude
		if Distance > 10 then
			if not CompanionTimers[Companion] then
				CompanionTimers[Companion] = tick()
			elseif tick() - CompanionTimers[Companion] > 5 then
				HRP.CFrame = CFrame.new(FinalPosition)
				CompanionTimers[Companion] = nil
				continue
			end
		else
			CompanionTimers[Companion] = nil
		end

		if (HRP.Position - TargetPos).Magnitude > 1 then
			Human:MoveTo(TargetPos)
		end

		local UpperTorso = Companion:FindFirstChild("UpperTorso")
		local Neck = UpperTorso and UpperTorso:FindFirstChild("Neck")
		if Neck then
			local LookVec = (Root.Position - HRP.Position).Unit
			local Yaw = math.atan2(-LookVec.X, -LookVec.Z)
			Neck.Transform = CFrame.Angles(0, Yaw, 0)
		end
		
		local HeightDiff = FinalPosition.Y - HRP.Position.Y
		if HeightDiff > 3 then
			Human:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end

function Local.OnInput(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local Target = Mouse.Target
		if Target then
			local EnemyModel = Target:FindFirstAncestorOfClass("Model")
			if EnemyModel and CS:HasTag(EnemyModel, "Enemy") then
				Local.CommandCompanionsToAttack(EnemyModel)
			end
		end
	end
end

function Local.CommandCompanionsToAttack(enemy)
	if not enemy:FindFirstChild("HumanoidRootPart") then return end
	local Center = enemy.HumanoidRootPart.Position
	local Radius = 4
	
	for i, Companion in ipairs(Companions) do
		local Angle = math.rad((360 / #Companions) * i)
		local X = math.cos(Angle) * Radius
		local Z = math.sin(Angle) * Radius
		local TargetPosition = Center + Vector3.new(X, 0, Z)
		
		local Human = Companion:FindFirstChildOfClass("Humanoid")
		if Human then
			Human:MoveTo(TargetPosition)
		end
		
		task.delay(1, function()
			local Human = Companion:FindFirstChildOfClass("Humanoid")
			if Human and PunchAnimation then
				local Animation = Human:LoadAnimation(PunchAnimation)
				Animation:Play()
			end
			
			local Data = CompanionConfig.GetCompanions("Default")
			if Data then
				CompanionAttackRemote:FireServer(enemy, Data.Damage)
			end
		end)
	end
end

return Shared