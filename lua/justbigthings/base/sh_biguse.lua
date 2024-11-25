local enable = CreateConVar("jbt_biguse_enabled", "1", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether to enable the big use module", 0, 1)
local adminOnly = CreateConVar("jbt_biguse_adminonly", "0", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether big usage is for admins only", 0, 1)
local enableMass = CreateConVar("jbt_biguse_mass_enabled", "1", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether big players can carry heavier props", 0, 1)
local powerMass = CreateConVar("jbt_biguse_mass_pow", "2", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "The power of the amount of mass big players can carry", 1, 3)

local usableEnums = 0x00000010 + 0x00000020 + 0x00000040 + 0x00000080
local maxMass = 35
local tangents = { 0, 1, 0.57735026919, 0.3639702342, 0.267949192431, 0.1763269807, -0.1763269807, -0.267949192431 }
local eMinS = Vector(-16, -16, -16)
local eMaxS = Vector(16, 16, 16)
local useOnGroundEnum = 0x00000100
local useInRadiusEnum = 0x00000200
local useRadius = 80
local useDrop = 72
local usableContents = MASK_SOLID + CONTENTS_DEBRIS + CONTENTS_PLAYERCLIP

-- https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/player.cpp#L2766-L2780
local function isUsable(ent, required, scale)
	if not IsValid(ent) then return false end
	if ent:IsPlayer() then return false end

	local caps = ent:ObjectCaps()
	if bit.band(caps, required) ~= required then return false end
	if bit.band(caps, usableEnums) ~= 0 then return true end

	if not enableMass:GetBool() then return false end
	if ent:HasSpawnFlags(SF_PHYSPROP_PREVENT_PICKUP) then return false end

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) or not phys:IsMoveable() then return false end

	return phys:GetMass() <= maxMass * scale ^ powerMass:GetInt() -- any physical thing with the right size can be moved
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/shared/baseplayer_shared.cpp#L1051-L1066
local function intervalDistance(x, x0, x1)
	if x0 > x1 then
		x0, x1 = x1, x0
	end

	if x < x0 then return x0 - x end
	if x > x1 then return x - x1 end
	return 0
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/shared/collisionproperty.cpp#L917-L924
local function getNearestPoint(ent, point)
	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then return ent:GetPos() end

	local newPoint = ent:WorldToLocal(point)

	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	newPoint.x = math.Clamp(newPoint.x, mins.x, maxs.x)
	newPoint.y = math.Clamp(newPoint.y, mins.y, maxs.y)
	newPoint.z = math.Clamp(newPoint.z, mins.z, maxs.z)

	return ent:LocalToWorld(newPoint)
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/shared/baseplayer_shared.cpp#L1068-L1270
hook.Add("FindUseEntity", "JBT_BigUse", function(ply, defaultEnt)
	if not enable:GetBool() then return end
	if adminOnly:GetBool() and not JBT.HasPermission(ply, "jbt_biguse") then return end

	local scale = JBT.PlyScale(ply)
	if scale < 1.01 then return end

	local ang = ply:EyeAngles()
	local forward, up = ang:Forward(), ang:Up()
	local searchCenter = ply:EyePos()

	local nearestDist = math.huge
	local nearest

	-- standard object discovery
	for k, v in ipairs(tangents) do
		local tr
		if k == 1 then
			tr = util.TraceLine({
				start = searchCenter,
				endpos = searchCenter + forward * 1024,
				mask = usableContents,
				filter = ply
			})
		else
			local down = forward - v * up
			down:Normalize()

			tr = util.TraceHull({
				start = searchCenter,
				endpos = searchCenter + down * useDrop * scale,
				mask = usableContents,
				mins = eMinS * scale,
				maxs = eMaxS * scale,
				filter = ply
			})
		end

		local object = tr.Entity
		local usable = isUsable(object, 0, scale)

		while IsValid(object) and not usable and IsValid(object:GetParent()) do
			object = object:GetParent()
			usable = isUsable(object, 0, scale)
		end

		if not usable then continue end

		local delta = tr.HitPos - tr.StartPos
		local centerZ = object:WorldSpaceCenter().z
		delta.z = intervalDistance(tr.HitPos.z, centerZ + ply:OBBMins().z, centerZ + ply:OBBMaxs().z)
		local dist = delta:Length()

		if dist >= useRadius * scale then continue end

		nearest = object

		if k == 1 then return object end
	end

	-- ground-based object discovery
	local groundEnt = ply:GetGroundEntity()
	if IsValid(groundEnt) and isUsable(groundEnt, useOnGroundEnum, scale) then
		nearest = groundEnt
	end

	-- prep for below
	if IsValid(nearest) then
		local point = getNearestPoint(nearest, searchCenter)
		nearestDist = util.DistanceToLine(point, searchCenter, forward)
	end

	-- radius-based object discovery
	local findEnts = ents.FindInSphere(searchCenter, useRadius * scale)
	for _, object in ipairs(findEnts) do
		if not isUsable(object, useInRadiusEnum, scale) then continue end

		local point = getNearestPoint(object, searchCenter)

		local dir = point - searchCenter
		dir:Normalize()

		local dot = dir:Dot(forward)
		if dot < 0.8 then continue end

		local dist = util.DistanceToLine(point, searchCenter, forward)
		if dist >= nearestDist * scale then continue end

		tr = util.TraceLine({
			start = searchCenter,
			endpos = point,
			mask = usableContents,
			filter = ply
		})

		if tr.Fraction == 1 or tr.Entity == object then
			nearest = object
			nearestDist = dist
		end
	end

	if not IsValid(nearest) then return end
	return nearest
end)

hook.Add("PlayerUse", "JBT_BigUse", function(ply, ent)
	if not enableMass:GetBool() or not enable:GetBool() then return end
	if adminOnly:GetBool() and not JBT.HasPermission(ply, "jbt_biguse") then return end

	local scale = JBT.PlyScale(ply)
	if scale < 1.01 then return end

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
		if mass <= maxMass then return end -- just let the default behavior run
		if mass > maxMass * scale ^ 2 then return end

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