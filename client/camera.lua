Camera = {}

local cam
local currentView = 'body'
local heading

local VIEWS = {
    head  = { bone = 31086, offset = vector3(0.0, 0.62, 0.02),  fov = 22.0, point = vector3(0.0, 0.0, 0.0) },
    body  = { bone = 24818, offset = vector3(0.0, 1.9,  0.15),  fov = 34.0, point = vector3(0.0, 0.0, 0.0) },
    legs  = { bone = 51826, offset = vector3(0.0, 1.5,  0.1),   fov = 36.0, point = vector3(0.0, 0.0, 0.0) },
    full  = { bone = 0,     offset = vector3(0.0, 2.6,  0.2),   fov = 38.0, point = vector3(0.0, 0.0, 0.1) },
}

local function bonePosition(ped, bone)
    if bone == 0 then return GetEntityCoords(ped) end
    local index = GetPedBoneIndex(ped, bone)
    if index == -1 then return GetEntityCoords(ped) end
    return GetWorldPositionOfEntityBone(ped, index)
end

function Camera.setView(view)
    if not VIEWS[view] or not cam or not DoesCamExist(cam) then return end

    currentView = view
    local ped = PlayerPedId()
    local def = VIEWS[view]
    local target = bonePosition(ped, def.bone)

    local pos = GetOffsetFromEntityInWorldCoords(ped, def.offset.x, def.offset.y, def.offset.z)
    pos = vector3(pos.x, pos.y, target.z + def.offset.z)

    SetCamCoord(cam, pos.x, pos.y, pos.z)
    PointCamAtCoord(cam, target.x + def.point.x, target.y + def.point.y, target.z + def.point.z)
    SetCamFov(cam, def.fov)
end

function Camera.view() return currentView end

function Camera.turn(direction)
    local ped = PlayerPedId()
    heading = (GetEntityHeading(ped) + (direction * 15.0)) % 360.0
    SetEntityHeading(ped, heading)
    Camera.setView(currentView)
end

function Camera.setHeading(value)
    local ped = PlayerPedId()
    heading = value % 360.0
    SetEntityHeading(ped, heading)
    Camera.setView(currentView)
end

function Camera.isActive() return cam ~= nil and DoesCamExist(cam) end

function Camera.start()
    if Camera.isActive() then return end

    local ped = PlayerPedId()
    heading = GetEntityHeading(ped)

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 34.0, false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 700, true, true)

    Camera.setView('body')
end

function Camera.stop()
    if not Camera.isActive() then return end

    RenderScriptCams(false, true, 700, true, true)
    DestroyCam(cam, false)
    cam = nil
    currentView = 'body'
end

function Camera.refresh()
    if Camera.isActive() then Camera.setView(currentView) end
end
