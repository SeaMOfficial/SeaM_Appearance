Shops = {}

local Core = exports.SeaM_Core:GetCoreObject()

local usingTarget = false
local points = {}

local function shopLabel(kind, def)
    return def.label or kind
end

local function collectPoints()
    points = {}

    for kind, def in pairs(Config.Shops) do
        for _, coords in ipairs(def.locations or {}) do
            points[#points + 1] = { kind = kind, coords = coords, label = shopLabel(kind, def) }
        end
    end

    for _, coords in ipairs(Config.Wardrobes.locations or {}) do
        points[#points + 1] = { kind = 'wardrobe', coords = coords, label = Config.Wardrobes.label }
    end
end

local function createBlips()
    for kind, def in pairs(Config.Shops) do
        if def.blip then
            for _, coords in ipairs(def.locations or {}) do
                local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                SetBlipSprite(blip, def.blip.sprite or 73)
                SetBlipColour(blip, def.blip.colour or 0)
                SetBlipScale(blip, def.blip.scale or 0.7)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(shopLabel(kind, def))
                EndTextCommandSetBlipName(blip)
            end
        end
    end
end

local function priceFor(kind)
    return Config.Prices[kind] or 0
end

function Shops.open(kind)
    if Customization.isActive() then return end

    local permissions = Config.Permissions[kind]
    if not permissions then return end

    local price = priceFor(kind)

    if price > 0 and not Core.Callbacks.await('appearance:canAfford', price) then
        TriggerEvent('SeaM_Core:notify', ('You cannot afford this (%s).')
            :format(Core.Util.formatMoney(price)), 'error')
        return
    end

    local options = {}
    for key, value in pairs(permissions) do options[key] = value end
    options.price = price
    options.title = shopLabel(kind, Config.Shops[kind] or {})

    Customization.start(options, function(appearance)
        if not appearance then return end

        local ok, err = Core.Callbacks.await('appearance:save', appearance, kind)
        if not ok then
            TriggerEvent('SeaM_Core:notify', err or 'That could not be saved.', 'error')
            return
        end

        TriggerEvent('SeaM_Core:notify', price > 0
            and ('Paid %s.'):format(Core.Util.formatMoney(price))
            or 'Looking good.', 'success')
    end)
end

function Shops.openWardrobe()
    local outfits = Core.Callbacks.await('appearance:outfits') or {}

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'wardrobe',
        data = {
            outfits = outfits,
            maxOutfits = Config.MaxOutfits,
            current = Ped.get(PlayerPedId(), nil),
        },
    })
end

RegisterNUICallback('wearOutfit', function(data, cb)
    local outfit = Core.Callbacks.await('appearance:getOutfit', data.id)
    if outfit then
        local ped = PlayerPedId()
        Ped.applyComponents(ped, outfit.components)
        Ped.applyProps(ped, outfit.props)
    end
    cb({ ok = outfit ~= nil })
end)

RegisterNUICallback('saveOutfit', function(data, cb)
    local ped = PlayerPedId()
    local ok, err = Core.Callbacks.await('appearance:saveOutfit', data.name, {
        components = Ped.getComponents(ped),
        props = Ped.getProps(ped),
    })
    cb({ ok = ok, error = err, outfits = Core.Callbacks.await('appearance:outfits') })
end)

RegisterNUICallback('deleteOutfit', function(data, cb)
    Core.Callbacks.await('appearance:deleteOutfit', data.id)
    cb({ ok = true, outfits = Core.Callbacks.await('appearance:outfits') })
end)

RegisterNUICallback('closeWardrobe', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb({ ok = true })
end)

local ICONS = {
    clothing = 'shirt',
    barber   = 'scissors',
    tattoo   = 'needle',
    surgeon  = 'user',
    wardrobe = 'bag',
}

local function targetResource()
    if Config.Interaction == 'marker' then return nil end

    local deadline = GetGameTimer() + 15000

    while GetGameTimer() < deadline do
        local state = GetResourceState('SeaM_Target')

        if state == 'started' then return 'SeaM_Target' end

        if state == 'missing' or state == 'unknown' then return nil end

        Wait(200)
    end

    return nil
end

local function registerTargets(resource)
    for _, point in ipairs(points) do
        exports[resource]:addSphereZone({
            coords = point.coords,
            radius = 1.2,
            options = { {
                name = ('seam_appearance_%s_%s'):format(point.kind, point.coords.x),
                icon = ICONS[point.kind] or 'shirt',
                label = point.kind == 'wardrobe' and 'Open wardrobe' or ('Browse %s'):format(point.label),
                distance = 2.0,
                onSelect = function()
                    if point.kind == 'wardrobe' then Shops.openWardrobe() else Shops.open(point.kind) end
                end,
            } },
        })
    end
end

local function registerPoints()
    for _, point in ipairs(points) do
        exports.SeaM_Core:RegisterPoint({
            id = ('seam_appearance_%s_%.1f_%.1f'):format(point.kind, point.coords.x, point.coords.y),
            coords = point.coords,
            distance = Config.PointDistance,
            label = point.kind == 'wardrobe'
                and 'Open your wardrobe'
                or ('Browse the %s'):format(point.label),
            canInteract = function() return not Customization.isActive() end,
            onSelect = function()
                if point.kind == 'wardrobe' then Shops.openWardrobe() else Shops.open(point.kind) end
            end,
        })
    end
end

CreateThread(function()
    collectPoints()
    createBlips()

    local resource = targetResource()

    if resource then
        usingTarget = true
        registerTargets(resource)
    else
        registerPoints()
    end
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= 'SeaM_Target' or not usingTarget then return end
    registerTargets('SeaM_Target')
end)

exports('OpenShop', Shops.open)
exports('OpenWardrobe', Shops.openWardrobe)
