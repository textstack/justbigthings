JBT = JBT or {}
local JBT = JBT

local enable = CreateConVar("jbt_bigsit_enabled", "1", JBT.SHARED_FCVARS, "Whether to enable the big sit module", 0, 1)

if SERVER then return end

local personalEnable = CreateClientConVar("jbt_cl_bigsit", "1", true, false, "Whether player size should affect the camera view while sitting", 0, 2)

hook.Add("CalcVehicleView", "JBT_BigSit", function(veh, ply, view)
    local val = personalEnable:GetInt()
    if val <= 0 or (not enable:GetBool() and val <= 1) then return end

    local scale = JBT.PlyScale(ply)
    local localPos = view.origin - ply:GetPos()

    view.origin = view.origin + localPos * (scale - 1)
end)