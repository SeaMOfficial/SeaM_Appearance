local Core = exports.SeaM_Core:GetCoreObject()

local currentAppearance

local function applyStored(appearance)
    currentAppearance = appearance or Data.default()
    Ped.applyToPlayer(currentAppearance)
end

RegisterNetEvent('SeaM_Appearance:client:load', function(appearance)
    applyStored(appearance)
end)

RegisterNetEvent('SeaM_Core:player:unloaded', function()
    currentAppearance = nil
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(200) end
    Wait(1000)

    if not exports.SeaM_Core:IsPlayerLoaded() then return end
    local appearance = Core.Callbacks.await('appearance:get')
    if appearance then applyStored(appearance) end
end)

exports('startPlayerCustomization', function(cb, options)
    Customization.start(options or Config.Permissions.creation, function(appearance)
        if appearance then currentAppearance = appearance end
        if cb then cb(appearance) end
    end)
end)

exports('setPlayerAppearance', function(appearance)
    applyStored(appearance)
end)

exports('setPedAppearance', function(ped, appearance)
    return Ped.applyToPed(ped, appearance)
end)

exports('getPedAppearance', function(ped)
    return Ped.get(ped or PlayerPedId(), currentAppearance and currentAppearance.tattoos or {})
end)

exports('getPlayerAppearance', function() return currentAppearance end)

exports('getPedComponents', function(ped) return Ped.getComponents(ped or PlayerPedId()) end)

exports('getPedProps', function(ped) return Ped.getProps(ped or PlayerPedId()) end)

exports('getPedHeadBlend', function(ped) return Ped.getHeadBlend(ped or PlayerPedId()) end)

exports('getPedModel', function(ped) return Ped.modelName(ped or PlayerPedId()) end)

exports('getAppearanceSettings', function(ped) return Ped.limits(ped or PlayerPedId()) end)

exports('setPlayerOutfit', function(outfit)
    if not outfit then return false end

    local ped = PlayerPedId()
    Ped.applyComponents(ped, outfit.components)
    Ped.applyProps(ped, outfit.props)

    if currentAppearance then
        currentAppearance.components = outfit.components or currentAppearance.components
        currentAppearance.props = outfit.props or currentAppearance.props
    end
    return true
end)

exports('isCustomizationActive', function() return Customization.isActive() end)

exports('resetAppearance', function()
    local appearance = Core.Callbacks.await('appearance:get')
    if appearance then applyStored(appearance) end
end)

RegisterNetEvent('SeaM_Appearance:client:openEditor', function()
    if Customization.isActive() then return end

    Customization.start(Config.Permissions.creation, function(appearance)
        if not appearance then return end
        currentAppearance = appearance
        Core.Callbacks.await('appearance:save', appearance, nil)
    end)
end)
