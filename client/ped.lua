Ped = {}

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end

    RequestModel(hash)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(10) end

    if not HasModelLoaded(hash) then return nil end
    return hash
end

function Ped.isFreemode(ped)
    local model = GetEntityModel(ped)
    return model == `mp_m_freemode_01` or model == `mp_f_freemode_01`
end

function Ped.modelName(ped)
    local hash = GetEntityModel(ped)
    for _, entry in ipairs(Data.Models) do
        if joaat(entry.name) == hash then return entry.name end
    end
    return hash == `mp_f_freemode_01` and 'mp_f_freemode_01' or 'mp_m_freemode_01'
end

function Ped.applyHeadBlend(ped, blend)
    if not blend or not Ped.isFreemode(ped) then return end
    SetPedHeadBlendData(ped,
        blend.shapeFirst or 0, blend.shapeSecond or 0, blend.shapeThird or 0,
        blend.skinFirst or 0, blend.skinSecond or 0, blend.skinThird or 0,
        blend.shapeMix or 0.5, blend.skinMix or 0.5, blend.thirdMix or 0.0,
        false)
end

function Ped.applyFaceFeatures(ped, features)
    if not features or not Ped.isFreemode(ped) then return end
    for _, feature in ipairs(Data.FaceFeatures) do
        SetPedFaceFeature(ped, feature.index, tonumber(features[feature.key]) or 0.0)
    end
end

function Ped.applyHeadOverlays(ped, overlays)
    if not overlays or not Ped.isFreemode(ped) then return end

    for _, overlay in ipairs(Data.HeadOverlays) do
        local value = overlays[overlay.key] or {}
        local style = value.style or 0
        local opacity = value.opacity or 0.0

        SetPedHeadOverlay(ped, overlay.index, style == 0 and 255 or style - 1, opacity + 0.0)

        if overlay.colourType > 0 then
            SetPedHeadOverlayColor(ped, overlay.index, overlay.colourType,
                value.colour or 0, value.secondColour or value.colour or 0)
        end
    end
end

function Ped.applyHair(ped, hair)
    if not hair then return end
    SetPedComponentVariation(ped, 2, hair.style or 0, hair.texture or 0, 0)
    SetPedHairColor(ped, hair.colour or 0, hair.highlight or 0)
end

function Ped.applyComponents(ped, components)
    if not components then return end
    for _, entry in ipairs(components) do
        if entry.component_id ~= 2 then
            SetPedComponentVariation(ped, entry.component_id,
                entry.drawable or 0, entry.texture or 0, 0)
        end
    end
end

function Ped.applyProps(ped, props)
    if not props then return end
    for _, entry in ipairs(props) do
        if (entry.drawable or -1) < 0 then
            ClearPedProp(ped, entry.prop_id)
        else
            SetPedPropIndex(ped, entry.prop_id, entry.drawable, entry.texture or 0, true)
        end
    end
end

function Ped.applyTattoos(ped, tattoos)
    ClearPedDecorations(ped)
    if not tattoos then return end

    for _, list in pairs(tattoos) do
        for _, tattoo in ipairs(list) do
            local collection = tonumber(tattoo.collection) or joaat(tostring(tattoo.collection))
            local name = tonumber(tattoo.name) or joaat(tostring(tattoo.name))
            AddPedDecorationFromHashes(ped, collection, name)
        end
    end
end

function Ped.applyEyeColour(ped, colour)
    if not Ped.isFreemode(ped) then return end
    SetPedEyeColor(ped, colour or 0)
end

function Ped.apply(ped, appearance)
    if not appearance then return end

    Ped.applyHeadBlend(ped, appearance.headBlend)
    Ped.applyFaceFeatures(ped, appearance.faceFeatures)
    Ped.applyHeadOverlays(ped, appearance.headOverlays)
    Ped.applyEyeColour(ped, appearance.eyeColour)
    Ped.applyComponents(ped, appearance.components)
    Ped.applyHair(ped, appearance.hair)
    Ped.applyProps(ped, appearance.props)
    Ped.applyTattoos(ped, appearance.tattoos)
end

function Ped.applyToPlayer(appearance)
    appearance = appearance or Data.default()

    local hash = loadModel(appearance.model or 'mp_m_freemode_01')
    if hash and GetEntityModel(PlayerPedId()) ~= hash then
        SetPlayerModel(PlayerId(), hash)
        SetModelAsNoLongerNeeded(hash)
        SetPedDefaultComponentVariation(PlayerPedId())
    end

    local ped = PlayerPedId()
    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
    Ped.apply(ped, appearance)
    return ped
end

function Ped.applyToPed(ped, appearance)
    if not appearance or not DoesEntityExist(ped) then return ped end

    local hash = loadModel(appearance.model or 'mp_m_freemode_01')
    if hash and GetEntityModel(ped) ~= hash then
        local coords, heading = GetEntityCoords(ped), GetEntityHeading(ped)
        local wasFrozen = IsEntityPositionFrozen(ped)

        DeletePed(ped)
        ped = CreatePed(4, hash, coords.x, coords.y, coords.z, heading, false, false)
        SetModelAsNoLongerNeeded(hash)
        SetPedDefaultComponentVariation(ped)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, wasFrozen)
    end

    Ped.apply(ped, appearance)
    return ped
end

local function readHeadBlend(ped)
    local raw = table.pack(GetPedHeadBlendData(ped))

    if type(raw[1]) == 'table' then return raw[1] end

    local offset = raw.n >= 10 and 1 or 0
    if raw.n - offset < 9 then return nil end

    local function at(index) return tonumber(raw[index + offset]) end

    return {
        shapeFirst = at(1), shapeSecond = at(2), shapeThird = at(3),
        skinFirst = at(4), skinSecond = at(5), skinThird = at(6),
        shapeMix = at(7), skinMix = at(8), thirdMix = at(9),
    }
end

function Ped.getHeadBlend(ped)
    if not Ped.isFreemode(ped) then return Data.default().headBlend end

    local blend = readHeadBlend(ped) or {}
    return {
        shapeFirst = blend.shapeFirst or 0,
        shapeSecond = blend.shapeSecond or 0,
        shapeThird = blend.shapeThird or 0,
        skinFirst = blend.skinFirst or 0,
        skinSecond = blend.skinSecond or 0,
        skinThird = blend.skinThird or 0,
        shapeMix = blend.shapeMix or 0.5,
        skinMix = blend.skinMix or 0.5,
        thirdMix = blend.thirdMix or 0.0,
    }
end

function Ped.getFaceFeatures(ped)
    local out = {}
    local getter = rawget(_G, 'GetPedFaceFeature')

    for _, feature in ipairs(Data.FaceFeatures) do
        if getter then
            local ok, value = pcall(getter, ped, feature.index)
            out[feature.key] = (ok and tonumber(value)) or 0.0
        else
            out[feature.key] = 0.0
        end
    end

    return out
end

function Ped.getHeadOverlays(ped)
    local out = {}
    for _, overlay in ipairs(Data.HeadOverlays) do

        local _, style, _, colour, secondColour, opacity = GetPedHeadOverlayData(ped, overlay.index)

        out[overlay.key] = {
            style = (style == nil or style == 255) and 0 or style + 1,
            opacity = tonumber(opacity) or 0.0,
            colour = tonumber(colour) or 0,
            secondColour = tonumber(secondColour) or 0,
        }
    end
    return out
end

function Ped.getComponents(ped)
    local out = {}
    for i, entry in ipairs(Data.Components) do
        out[i] = {
            component_id = entry.id,
            drawable = GetPedDrawableVariation(ped, entry.id),
            texture = GetPedTextureVariation(ped, entry.id),
        }
    end
    return out
end

function Ped.getProps(ped)
    local out = {}
    for i, entry in ipairs(Data.Props) do
        out[i] = {
            prop_id = entry.id,
            drawable = GetPedPropIndex(ped, entry.id),
            texture = GetPedPropTextureIndex(ped, entry.id),
        }
    end
    return out
end

function Ped.getHair(ped)
    local colour, highlight = GetPedHairColor(ped), GetPedHairHighlightColor(ped)
    return {
        style = GetPedDrawableVariation(ped, 2),
        texture = GetPedTextureVariation(ped, 2),
        colour = colour or 0,
        highlight = highlight or 0,
    }
end

function Ped.get(ped, tattoos)
    return {
        model = Ped.modelName(ped),
        headBlend = Ped.getHeadBlend(ped),
        faceFeatures = Ped.getFaceFeatures(ped),
        headOverlays = Ped.getHeadOverlays(ped),
        hair = Ped.getHair(ped),
        eyeColour = GetPedEyeColor(ped) or 0,
        components = Ped.getComponents(ped),
        props = Ped.getProps(ped),
        tattoos = tattoos or {},
    }
end

function Ped.limits(ped)
    local components = {}
    for _, entry in ipairs(Data.Components) do
        local drawable = GetPedDrawableVariation(ped, entry.id)
        components[tostring(entry.id)] = {
            drawable = math.max(GetNumberOfPedDrawableVariations(ped, entry.id) - 1, 0),
            texture  = math.max(GetNumberOfPedTextureVariations(ped, entry.id, drawable) - 1, 0),
        }
    end

    local props = {}
    for _, entry in ipairs(Data.Props) do
        local drawable = GetPedPropIndex(ped, entry.id)
        props[tostring(entry.id)] = {
            drawable = math.max(GetNumberOfPedPropDrawableVariations(ped, entry.id) - 1, -1),
            texture  = math.max(GetNumberOfPedPropTextureVariations(ped, entry.id, drawable) - 1, 0),
        }
    end

    local overlays = {}
    for _, overlay in ipairs(Data.HeadOverlays) do
        overlays[overlay.key] = {
            style = GetPedHeadOverlayNum(overlay.index) or 0,
            colourType = overlay.colourType,
        }
    end

    return {
        components = components,
        props = props,
        overlays = overlays,
        hair = {
            style = math.max(GetNumberOfPedDrawableVariations(ped, 2) - 1, 0),
            texture = math.max(GetNumberOfPedTextureVariations(ped, 2, GetPedDrawableVariation(ped, 2)) - 1, 0),
        },
        hairColours = math.max((GetNumHairColors() or 64) - 1, 0),
        makeupColours = math.max((GetNumMakeupColors() or 64) - 1, 0),
        eyeColours = 31,
        heritage = Data.Heritage,
    }
end

local palettes

function Ped.palettes()
    if palettes then return palettes end

    local hair, makeup = {}, {}
    for i = 0, (GetNumHairColors() or 64) - 1 do
        local r, g, b = GetPedHairRgbColor(i)
        hair[i + 1] = { r or 0, g or 0, b or 0 }
    end
    for i = 0, (GetNumMakeupColors() or 64) - 1 do
        local r, g, b = GetPedMakeupRgbColor(i)
        makeup[i + 1] = { r or 0, g or 0, b or 0 }
    end

    palettes = { hair = hair, makeup = makeup }
    return palettes
end
