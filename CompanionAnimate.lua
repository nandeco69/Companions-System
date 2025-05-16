local Local = {}
local Shared = {}

local Animations = {
	Idle = "rbxassetid://507766666",
	Walk = "rbxassetid://507777826",
}

function Local.LoadAnimations(human)
	local Animator = human:FindFirstChildOfClass("Animator")
	local Loaded = {}

	for State, AnimationId in pairs(Animations) do
		local Animation = Instance.new("Animation")
		Animation.AnimationId = AnimationId

		local Track = Animator:LoadAnimation(Animation)
		Track.Looped = true
		Track.Priority = Enum.AnimationPriority.Movement
		Loaded[State] = Track
	end

	return Loaded
end

function Shared.ApplyTo(human)
	local AnimTracks = Local.LoadAnimations(human)
	local CurrentState = "Idle"

	AnimTracks.Idle:Play()

	human.Running:Connect(function(speed)
		if speed > 0.1 then
			if CurrentState ~= "Walk" then
				AnimTracks.Idle:Stop()
				AnimTracks.Walk:Play()
				CurrentState = "Walk"
			end
		else
			if CurrentState ~= "Idle" then
				AnimTracks.Walk:Stop()
				AnimTracks.Idle:Play()
				CurrentState = "Idle"
			end
		end
	end)
end

return Shared