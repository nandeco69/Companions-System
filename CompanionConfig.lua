local Local = {}
local Shared = {}

Shared.MAX_COMPANIONS = 4

function Shared.GetCompanionPosition(index, total)
	if total == 1 then
		if index == 1 then
			return Vector3.new(0, 0, 6)
		end
	elseif total == 2 then
		local Positions = {
			Vector3.new(-5, 0, 5),
			Vector3.new(5, 0, 5),
		}
		return Positions[index]
	elseif total == 3 then
		local Positions = {
			Vector3.new(-6, 0, 6),
			Vector3.new(6, 0, 6),
			Vector3.new(0, 0, 10),
		}
		return Positions[index]
	elseif total == 4 then
		local Positions = {
			Vector3.new(-10, 0, 10),
			Vector3.new(10, 0, 10),
			Vector3.new(-8, 0, 0),
			Vector3.new(8, 0, 0),
		}
		return Positions[index]
	end
	
	return Vector3.zero
end

Shared.Companions = {
	Default = {
		Name = "Default",
		Damage = 5,
		AttackCooldown = 2
	}
}

Shared.ATTACK_RADIUS = 7

function Shared.GetCompanions(name)
	return Shared.Companions[name]
end

return Shared
