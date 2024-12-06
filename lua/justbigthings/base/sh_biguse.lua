JBT = JBT or {}
local JBT = JBT

local enable = CreateConVar("jbt_biguse_enabled", "1", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the big use module", 0, 1)
local adminOnly = CreateConVar("jbt_biguse_adminonly", "0", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether big usage is for admins only", 0, 1)
local enableMass = CreateConVar("jbt_biguse_mass", "1", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether big players can carry heavier props", 0, 1)
local powerMass = CreateConVar("jbt_biguse_mass_pow", "2", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "The mathematical power of the amount of mass big players can carry", 1, 3)
local smallMode = CreateConVar("jbt_biguse_small", "0", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether smaller players get a smaller range / mass limit for pickup", 0, 1)

JBT.USABLE_ENUMS = 0x00000010 + 0x00000020 + 0x00000040 + 0x00000080
JBT.DEFAULT_MAX_MASS = 35
JBT.USE_TANGENTS = { 0, 1, 0.57735026919, 0.3639702342, 0.267949192431, 0.1763269807, -0.1763269807, -0.267949192431 }
JBT.USE_VECTOR = Vector(16, 16, 16)
JBT.USE_ON_GROUND = 0x00000100
JBT.USE_IN_RADIUS = 0x00000200
JBT.USE_RADIUS = 80
JBT.USE_DROP = 72
JBT.USE_LONG = 2048
JBT.USABLE_CONTENTS = MASK_SOLID + CONTENTS_DEBRIS + CONTENTS_PLAYERCLIP

-- https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/player.cpp#L2766-L2780
function JBT.IsUsable(ent, required, scale, ply)
	if not IsValid(ent) then return false end
	required = required or 0

	local caps = ent:ObjectCaps()
	if bit.band(caps, required) ~= required then return false end
	if bit.band(caps, JBT.USABLE_ENUMS) ~= 0 then return true end

	if not IsValid(ply) then return false end
	if not JBT.HasEnabled(ply, enableMass, "JBT_BigUse_Mass") then return false end
	if ent:IsPlayer() then return false end
	if ent:HasSpawnFlags(SF_PHYSPROP_PREVENT_PICKUP) then return false end

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) or not phys:IsMoveable() then return false end

	scale = scale or 1
	return phys:GetMass() <= JBT.DEFAULT_MAX_MASS * scale ^ powerMass:GetInt() -- any physical thing with the right size can be moved
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/shared/baseplayer_shared.cpp#L1068-L1270
hook.Add("FindUseEntity", "JBT_BigUse", function(ply, defaultEnt)
	if not JBT.HasEnabled(ply, enable, "JBT_BigUse") then return end
	if not JBT.AdminOnlyCheck(ply, adminOnly, "jbt_biguse", "JBT_BigUse") then return end

	local scale = JBT.PlyScale(ply)
	if scale < JBT.UPPER then
		if not smallMode:GetBool() then return end
		if scale > JBT.LOWER then return end
	end

	local ang = ply:EyeAngles()
	local forward, up = ang:Forward(), ang:Up()
	local searchCenter = ply:EyePos()

	local nearestDist = math.huge
	local nearest

	-- standard object discovery
	for k, v in ipairs(JBT.USE_TANGENTS) do
		local tr
		if k == 1 then
			tr = util.TraceLine({
				start = searchCenter,
				endpos = searchCenter + forward * JBT.USE_LONG,
				mask = JBT.USABLE_CONTENTS,
				filter = ply
			})
		else
			local down = forward - v * up
			down:Normalize()

			tr = util.TraceHull({
				start = searchCenter,
				endpos = searchCenter + down * JBT.USE_DROP * scale,
				mask = JBT.USABLE_CONTENTS,
				mins = JBT.USE_VECTOR * -scale,
				maxs = JBT.USE_VECTOR * scale,
				filter = ply
			})
		end

		local object = tr.Entity
		local usable = JBT.IsUsable(object, nil, scale, ply)

		while IsValid(object) and not usable and IsValid(object:GetParent()) do
			object = object:GetParent()
			usable = JBT.IsUsable(object, nil, scale, ply)
		end

		if not usable then continue end

		local delta = tr.HitPos - tr.StartPos
		local centerZ = object:WorldSpaceCenter().z
		delta.z = JBT.IntervalDistance(tr.HitPos.z, centerZ + ply:OBBMins().z, centerZ + ply:OBBMaxs().z)

		local dist = delta:Length()
		if dist >= JBT.USE_RADIUS * scale then continue end

		nearest = object

		if k == 1 then return object end
	end

	-- ground-based object discovery
	local groundEnt = ply:GetGroundEntity()
	if IsValid(groundEnt) and JBT.IsUsable(groundEnt, JBT.USE_ON_GROUND, scale, ply) then
		nearest = groundEnt
	end

	-- prep for below
	if IsValid(nearest) then
		local point = JBT.GetNearestPoint(nearest, searchCenter)
		nearestDist = util.DistanceToLine(point, searchCenter, forward)
	end

	-- radius-based object discovery
	local findEnts = ents.FindInSphere(searchCenter, JBT.USE_RADIUS * scale)
	for _, object in ipairs(findEnts) do
		if not JBT.IsUsable(object, JBT.USE_IN_RADIUS, scale, ply) then continue end

		local point = JBT.GetNearestPoint(object, searchCenter)

		local dir = point - searchCenter
		dir:Normalize()

		local dot = dir:Dot(forward)
		if dot < 0.8 then continue end

		local dist = util.DistanceToLine(point, searchCenter, forward)
		if dist >= nearestDist * scale then continue end

		tr = util.TraceLine({
			start = searchCenter,
			endpos = point,
			mask = JBT.USABLE_CONTENTS,
			filter = ply
		})

		if tr.Fraction == 1 or tr.Entity == object then
			nearest = object
			nearestDist = dist
		end
	end

	if IsValid(nearest) then return nearest end
	if scale < 1 then return defaultEnt end
end)

hook.Add("PlayerUse", "JBT_BigUse", function(ply, ent)
	if not JBT.HasEnabled(ply, enable, "JBT_BigUse") then return end
	if not JBT.HasEnabled(ply, enableMass, "JBT_BigUse_Mass") then return end
	if not JBT.AdminOnlyCheck(ply, adminOnly, "jbt_biguse", "JBT_BigUse") then return end

	local scale = JBT.PlyScale(ply)
	if scale < JBT.UPPER then return end

	timer.Create("JBT_Pickup_" .. ply:UserID(), 0.1, 1, function()
		if not IsValid(ply) or not IsValid(ent) then return end
		if ply.JBT_LastPickedUp then return end
		if ent:IsPlayerHolding() then return end
		if ent:HasSpawnFlags(SF_PHYSPROP_PREVENT_PICKUP) then return end

		local entVec = ent:OBBMaxs() - ent:OBBMins()
		local plyVec = ply:OBBMaxs() - ply:OBBMins()
		local plyLinearSize = plyVec.x + plyVec.y + plyVec.z * (ply:Crouching() and 2 or 1) -- the hitbox is smaller while crouching
		if entVec.x + entVec.y + entVec.z > plyLinearSize then return end

		local phys = ent:GetPhysicsObject()
		if not IsValid(phys) or not phys:IsMoveable() then return end

		local mass = phys:GetMass()
		if mass <= JBT.DEFAULT_MAX_MASS then return end -- just let the default behavior run
		if mass > JBT.DEFAULT_MAX_MASS * scale ^ powerMass:GetInt() then return end

		ent.JBT_OldMass = mass
		phys:SetMass(8)

		if not hook.Run("AllowPlayerPickup", ply, ent) then
			phys:SetMass(ent.JBT_OldMass)
			ent.JBT_OldMass = nil
			return
		end

		ply:PickupObject(ent)
		phys:SetMass(ent.JBT_OldMass) -- won't work if the pickup succeeds

		ply.JBT_LastPickedUp = true
		timer.Create("JBT_Drop_" .. ply:UserID(), 1, 1, function()
			if IsValid(ply) then
				ply.JBT_LastPickedUp = nil
			end
		end)
	end)
end)

-- this hook does not have enabled/adminonly checks to ensure that stuff doesn't break with live updates
hook.Add("OnPlayerPhysicsDrop", "JBT_BigUse", function(ply, ent)
	ply.JBT_LastPickedUp = true
	timer.Create("JBT_Drop_" .. ply:UserID(), 1, 1, function()
		if IsValid(ply) then
			ply.JBT_LastPickedUp = nil
		end
	end)

	if not ent.JBT_OldMass then return end

	timer.Simple(0, function()
		if not IsValid(ent) then return end
		if not ent.JBT_OldMass then return end

		local phys = ent:GetPhysicsObject()
		if not IsValid(phys) then return end

		phys:SetMass(ent.JBT_OldMass)
		ent.JBT_OldMass = nil
	end)
end)

hook.Add("AllowPlayerPickup", "JBT_BigUse", function(ply, ent)
	if not JBT.HasEnabled(ply, enable, "JBT_BigUse") then return end
	if not JBT.HasEnabled(ply, enableMass, "JBT_BigUse_Mass") then return end
	if not JBT.HasEnabled(ply, smallMode, "JBT_BigUse_Small") then return end
	if not JBT.AdminOnlyCheck(ply, adminOnly, "jbt_biguse", "JBT_BigUse") then return end

	local scale = JBT.PlyScale(ply)
	if scale > JBT.LOWER then return end

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then return end
	if phys:GetMass() > JBT.DEFAULT_MAX_MASS * scale ^ powerMass:GetInt() then return false end
end)