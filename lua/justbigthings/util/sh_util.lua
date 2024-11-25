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