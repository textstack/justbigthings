JBT = JBT or {}
local JBT = JBT

JBT.DEFAULT_HEIGHT = 72
JBT.DEFAULT_CROUCHING_HEIGHT = 36
JBT.DEFAULT_WIDTH = 32
JBT.UPPER = 1.01
JBT.LOWER = 0.95
JBT.SERVER_FCVARS = FCVAR_NOTIFY + FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE
JBT.SHARED_FCVARS = JBT.SERVER_FCVARS + FCVAR_REPLICATED

-- uses hull height to calculate size with hull width constraining the result
function JBT.PlyScale(ply)
	local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
	local xyDiff, zDiff = (maxs.x + maxs.y - mins.x - mins.y) / 2, maxs.z - mins.z

	local zFrac = zDiff / (ply:Crouching() and JBT.DEFAULT_CROUCHING_HEIGHT or JBT.DEFAULT_HEIGHT)
	local xyFrac = xyDiff / JBT.DEFAULT_WIDTH

	return zFrac * math.min(xyFrac / zFrac, 1)
end

function JBT.HasPermission(ply, permission)
	if ply.HasPermission and ply:HasPermission(permission) then
		return true
	end

	if JBT.GetSettingBool("admin_is_superadmin") then
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

-- converts a value to something storable into settings
function JBT.ToSetting(value)
	local newVal
	if type(value) == "boolean" then
		newVal = value and 1 or 0
	else
		newVal = tonumber(value)
		if not newVal then return end
	end

	return newVal
end

-- if something tries ply:SetMaxHealth(ply:GetMaxHealth() + 1), we need to account for it
function JBT.RelativeStatSetFix(ply, stat)
	return ply["JBT_Get" .. stat]
end
function JBT.RelativeStatGetFix(ply, stat)
	local var = "JBT_Get" .. stat

	ply[var] = true
	timer.Create(var .. "_" .. ply:UserID(), 0, 1, function()
		if not IsValid(ply) then return end

		ply[var] = nil
	end)
end

timer.Create("JBT_CheckSizeChange", 0.5, 0, function()
	for _, ply in player.Iterator() do
		local scale = JBT.PlyScale(ply)
		if not ply.JBT_OldScale then
			ply.JBT_OldScale = scale
			continue
		end

		if ply.JBT_OldScale ~= scale then
			hook.Run("JBT_ScaleChanged", ply, scale, ply.JBT_OldScale)
		end

		ply.JBT_OldScale = scale
	end
end)