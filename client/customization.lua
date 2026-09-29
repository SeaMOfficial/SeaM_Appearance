Customization = {}

local session = nil

function SeaM_Copy(value)
    if type(value) ~= 'table' then return value end

    local out = {}
    for k, v in pairs(value) do out[k] = SeaM_Copy(v) end
    return out
end

local tattooCache

local function buildTattooList()
    if tattooCache then return tattooCache end

    local out = {}
    for _, zone in ipairs(Data.TattooZones) do out[zone.key] = {} end

    local ok = pcall(function()
        for characterType = 0, 1 do
            local count = GetNumTattooShopDlcItems(characterType) or 0

            for index = 0, count - 1 do
                local item = GetTattooShopDlcItemData(characterType, index)
                if type(item) == 'table' and item.collection and item.nameHash then
                    local zone = Data.TattooZones[(item.zone or 6) + 1] or Data.TattooZones[7]
                    local list = out[zone.key]

                    list[#list + 1] = {
                        label = item.nameLocalised or item.name or ('Design %d'):format(#list + 1),
                        collection = item.collection,
                        name = item.nameHash,
                        gender = characterType,
                        zone = zone.key,
                    }
                end
            end
        end
    end)

    if not ok then
        print('[SeaM_Appearance] tattoo enumeration is unavailable on this build; the tattoo tab will be empty')
    end

    tattooCache = out
    return out
end

local function tattoosForGender(gender)
    local all = buildTattooList()
    local out = {}

    for zoneKey, list in pairs(all) do
        local filtered = {}
        for _, tattoo in ipairs(list) do
            if tattoo.gender == gender then filtered[#filtered + 1] = tattoo end
        end
        if #filtered > 0 then out[zoneKey] = filtered end
    end

    return out
end

function Customization.isActive() return session ~= nil end

local function payload()
    return {
        appearance = session.appearance,
        limits     = Ped.limits(PlayerPedId()),
    }
end

local function pushUpdate()
    SendNUIMessage({ action = 'refresh', data = payload() })
end

function Customization.start(options, cb)
    if session then return cb(nil) end

    options = options or Config.Permissions.creation

    local ped = PlayerPedId()
    local original = Ped.get(ped, nil)

    session = {
        options = options,
        callback = cb,
        original = original,
        appearance = Ped.get(ped, {}),
    }

    session.original.tattoos = session.appearance.tattoos

    Camera.start()
    FreezeEntityPosition(ped, true)
    SetPlayerControl(PlayerId(), false, 0)
    ClearPedTasksImmediately(ped)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = {
            appearance  = session.appearance,
            limits      = Ped.limits(ped),
            palettes    = Ped.palettes(),
            definitions = {
                models       = Data.Models,
                components   = Data.Components,
                props        = Data.Props,
                faceFeatures = Data.FaceFeatures,
                headOverlays = Data.HeadOverlays,
                tattooZones  = Data.TattooZones,
            },
            tattoos     = tattoosForGender(Ped.modelName(ped) == 'mp_f_freemode_01' and 1 or 0),
            permissions = options,
            price       = options.price or 0,
            title       = options.title or 'Appearance',
            accent      = options.accent or '#4fd1c5',
        },
    })
end

local function finish(appearance)
    local cb = session and session.callback
    session = nil

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    Camera.stop()
    FreezeEntityPosition(PlayerPedId(), false)
    SetPlayerControl(PlayerId(), true, 0)

    if cb then cb(appearance) end
end

local function guard(fn)
    return function(data, cb)
        if not session then return cb({ ok = false }) end
        fn(data or {})
        cb(payload())
    end
end

RegisterNUICallback('setModel', guard(function(data)
    local entry = Data.ModelByName[data.model]
    if not entry or not session.options.ped then return end

    session.appearance = Data.default(entry.name)

    Ped.applyToPlayer(session.appearance)
    Camera.refresh()

    SendNUIMessage({
        action = 'tattoos',
        data = tattoosForGender(entry.gender),
    })
end))

RegisterNUICallback('setHeadBlend', guard(function(data)
    local blend = session.appearance.headBlend
    for key, value in pairs(data) do
        if blend[key] ~= nil then blend[key] = value end
    end
    Ped.applyHeadBlend(PlayerPedId(), blend)
end))

RegisterNUICallback('setFaceFeature', guard(function(data)
    session.appearance.faceFeatures[data.key] = tonumber(data.value) or 0.0
    Ped.applyFaceFeatures(PlayerPedId(), session.appearance.faceFeatures)
end))

RegisterNUICallback('setHeadOverlay', guard(function(data)
    local overlay = session.appearance.headOverlays[data.key]
    if not overlay then return end

    if data.style ~= nil then overlay.style = data.style end
    if data.opacity ~= nil then overlay.opacity = data.opacity end
    if data.colour ~= nil then overlay.colour = data.colour end
    if data.secondColour ~= nil then overlay.secondColour = data.secondColour end

    Ped.applyHeadOverlays(PlayerPedId(), session.appearance.headOverlays)
end))

RegisterNUICallback('setHair', guard(function(data)
    local hair = session.appearance.hair
    for _, key in ipairs({ 'style', 'texture', 'colour', 'highlight' }) do
        if data[key] ~= nil then hair[key] = data[key] end
    end
    Ped.applyHair(PlayerPedId(), hair)
end))

RegisterNUICallback('setEyeColour', guard(function(data)
    session.appearance.eyeColour = data.value or 0
    Ped.applyEyeColour(PlayerPedId(), session.appearance.eyeColour)
end))

RegisterNUICallback('setComponent', guard(function(data)
    local ped = PlayerPedId()
    local id = tonumber(data.component_id)
    if not id then return end

    local drawable = tonumber(data.drawable) or 0
    local texture = tonumber(data.texture) or 0

    local maxTexture = math.max(GetNumberOfPedTextureVariations(ped, id, drawable) - 1, 0)
    if texture > maxTexture then texture = 0 end

    SetPedComponentVariation(ped, id, drawable, texture, 0)

    for _, entry in ipairs(session.appearance.components) do
        if entry.component_id == id then
            entry.drawable, entry.texture = drawable, texture
        end
    end
end))

RegisterNUICallback('setProp', guard(function(data)
    local ped = PlayerPedId()
    local id = tonumber(data.prop_id)
    if not id then return end

    local drawable = tonumber(data.drawable) or -1
    local texture = tonumber(data.texture) or 0

    if drawable < 0 then
        ClearPedProp(ped, id)
        texture = 0
    else
        local maxTexture = math.max(GetNumberOfPedPropTextureVariations(ped, id, drawable) - 1, 0)
        if texture > maxTexture then texture = 0 end
        SetPedPropIndex(ped, id, drawable, texture, true)
    end

    for _, entry in ipairs(session.appearance.props) do
        if entry.prop_id == id then
            entry.drawable, entry.texture = drawable, texture
        end
    end
end))

RegisterNUICallback('toggleTattoo', guard(function(data)
    local zone = data.zone
    if not zone or not data.name then return end

    session.appearance.tattoos[zone] = session.appearance.tattoos[zone] or {}
    local list = session.appearance.tattoos[zone]

    for i = #list, 1, -1 do
        if list[i].name == data.name and list[i].collection == data.collection then
            table.remove(list, i)
            Ped.applyTattoos(PlayerPedId(), session.appearance.tattoos)
            return
        end
    end

    list[#list + 1] = {
        collection = data.collection,
        name = data.name,
        label = data.label,
        zone = zone,
    }
    Ped.applyTattoos(PlayerPedId(), session.appearance.tattoos)
end))

RegisterNUICallback('clearTattoos', guard(function(data)
    if data.zone then
        session.appearance.tattoos[data.zone] = nil
    else
        session.appearance.tattoos = {}
    end
    Ped.applyTattoos(PlayerPedId(), session.appearance.tattoos)
end))

RegisterNUICallback('camera', function(data, cb)
    if session then
        if data.view then Camera.setView(data.view) end
        if data.turn then Camera.turn(data.turn) end
    end
    cb({ ok = true })
end)

RegisterNUICallback('save', function(_, cb)
    if not session then return cb({ ok = false }) end

    local appearance = SeaM_Copy(session.appearance)
    cb({ ok = true })
    finish(appearance)
end)

RegisterNUICallback('cancel', function(_, cb)
    if not session then return cb({ ok = false }) end

    local original = session.original
    cb({ ok = true })

    Ped.applyToPlayer(original)
    finish(nil)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() or not session then return end
    SetNuiFocus(false, false)
    Camera.stop()
    FreezeEntityPosition(PlayerPedId(), false)
    SetPlayerControl(PlayerId(), true, 0)
end)
