local enable = CreateClientConVar("jbt_cl_bigsit", "1", true, false, "Whether player size should affect the camera view while sitting", 0, 1)

hook.Add("CalcVehicleView", "JBT_BigSit", function(veh, ply, view)
    if not enable:GetBool() then return end

    local scale = JBT.PlyScale(ply)
    local localPos = view.origin - ply:GetPos()

    view.origin = view.origin + localPos * (scale - 1)
end)