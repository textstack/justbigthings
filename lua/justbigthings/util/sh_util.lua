local superadmin = CreateConVar("jbt_adminonly_is_superadminonly", "0", FCVAR_NOTIFY + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Whether 'adminonly' settings should actually be superadmin only", 0, 1)

local defaultHeight = 72
local defaultCrouchingHeight = 36
local defaultWidth = 32

-- uses hull height to calculate size with hull width constraining the result
function JBT.PlyScale(ply)
	local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
	local xyDiff, zDiff = (maxs.x + maxs.y - mins.x - mins.y) / 2, maxs.z - mins.z

	local zFrac = zDiff / (ply:Crouching() and defaultCrouchingHeight or defaultHeight)
	local xyFrac = xyDiff / defaultWidth

	return zFrac * math.min(xyFrac / zFrac, 1)
end

function JBT.HasPermission(ply, permission)
	if ply.HasPermission and ply:HasPermission(permission) then
		return true
	end

	if superadmin:GetBool() then
		if ply:IsSuperAdmin() then return true end
	else
		if ply:IsAdmin() then return true end
	end

	return false
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/shared/baseplayer_shared.cpp#L1051-L1066
function JBT.IntervalDistance(x, x0, x1)
	if x0 > x1 then
		x0, x1 = x1, x0
	end

	if x < x0 then return x0 - x end
	if x > x1 then return x - x1 end
	return 0
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/game/shared/collisionproperty.cpp#L917-L924
function JBT.GetNearestPoint(ent, point)
	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then return ent:GetPos() end

	local newPoint = ent:WorldToLocal(point)

	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	newPoint.x = math.Clamp(newPoint.x, mins.x, maxs.x)
	newPoint.y = math.Clamp(newPoint.y, mins.y, maxs.y)
	newPoint.z = math.Clamp(newPoint.z, mins.z, maxs.z)

	return ent:LocalToWorld(newPoint)
end