Data = {}

Data.Models = {
    { name = 'mp_m_freemode_01', label = 'Male',   freemode = true,  gender = 0 },
    { name = 'mp_f_freemode_01', label = 'Female', freemode = true,  gender = 1 },
}

Data.Components = {
    { id = 1,  key = 'mask',       label = 'Mask' },
    { id = 3,  key = 'arms',       label = 'Arms' },
    { id = 4,  key = 'pants',      label = 'Legs' },
    { id = 5,  key = 'bag',        label = 'Bag' },
    { id = 6,  key = 'shoes',      label = 'Shoes' },
    { id = 7,  key = 'accessory',  label = 'Neck' },
    { id = 8,  key = 'undershirt', label = 'Undershirt' },
    { id = 9,  key = 'kevlar',     label = 'Body Armour' },
    { id = 10, key = 'badge',      label = 'Decal' },
    { id = 11, key = 'torso',      label = 'Top' },
}

Data.Props = {
    { id = 0, key = 'hat',      label = 'Hat' },
    { id = 1, key = 'glasses',  label = 'Glasses' },
    { id = 2, key = 'earrings', label = 'Earrings' },
    { id = 6, key = 'watch',    label = 'Watch' },
    { id = 7, key = 'bracelet', label = 'Bracelet' },
}

Data.FaceFeatures = {
    { index = 0,  key = 'noseWidth',        label = 'Nose Width' },
    { index = 1,  key = 'nosePeakHigh',     label = 'Nose Height' },
    { index = 2,  key = 'nosePeakSize',     label = 'Nose Length' },
    { index = 3,  key = 'noseBoneHigh',     label = 'Nose Bridge' },
    { index = 4,  key = 'nosePeakLowering', label = 'Nose Tip' },
    { index = 5,  key = 'noseBoneTwist',    label = 'Nose Bridge Shift' },
    { index = 6,  key = 'eyeBrownHigh',     label = 'Brow Height' },
    { index = 7,  key = 'eyeBrownForward',  label = 'Brow Depth' },
    { index = 8,  key = 'cheeksBoneHigh',   label = 'Cheekbone Height' },
    { index = 9,  key = 'cheeksBoneWidth',  label = 'Cheekbone Width' },
    { index = 10, key = 'cheeksWidth',      label = 'Cheek Width' },
    { index = 11, key = 'eyesOpening',      label = 'Eye Opening' },
    { index = 12, key = 'lipsThickness',    label = 'Lip Thickness' },
    { index = 13, key = 'jawBoneWidth',     label = 'Jaw Width' },
    { index = 14, key = 'jawBoneBackSize',  label = 'Jaw Length' },
    { index = 15, key = 'chinBoneLowering', label = 'Chin Height' },
    { index = 16, key = 'chinBoneLength',   label = 'Chin Length' },
    { index = 17, key = 'chinBoneSize',     label = 'Chin Width' },
    { index = 18, key = 'chinHole',         label = 'Chin Dimple' },
    { index = 19, key = 'neckThickness',    label = 'Neck Thickness' },
}

Data.HeadOverlays = {
    { index = 0,  key = 'blemishes',        label = 'Blemishes',     colourType = 0 },
    { index = 1,  key = 'facialHair',       label = 'Facial Hair',   colourType = 1 },
    { index = 2,  key = 'eyebrows',         label = 'Eyebrows',      colourType = 1 },
    { index = 3,  key = 'ageing',           label = 'Ageing',        colourType = 0 },
    { index = 4,  key = 'makeup',           label = 'Makeup',        colourType = 2 },
    { index = 5,  key = 'blush',            label = 'Blush',         colourType = 2 },
    { index = 6,  key = 'complexion',       label = 'Complexion',    colourType = 0 },
    { index = 7,  key = 'sunDamage',        label = 'Sun Damage',    colourType = 0 },
    { index = 8,  key = 'lipstick',         label = 'Lipstick',      colourType = 2 },
    { index = 9,  key = 'moleAndFreckles',  label = 'Freckles',      colourType = 0 },
    { index = 10, key = 'chestHair',        label = 'Body Hair',     colourType = 1 },
    { index = 11, key = 'bodyBlemishes',    label = 'Body Blemishes',colourType = 0 },
    { index = 12, key = 'addBodyBlemishes', label = 'Skin Marks',    colourType = 0 },
}

Data.Heritage = { maxMother = 45, maxFather = 45 }

Data.TattooZones = {
    { id = 0,  key = 'ZONE_TORSO',     label = 'Torso' },
    { id = 1,  key = 'ZONE_HEAD',      label = 'Head' },
    { id = 2,  key = 'ZONE_LEFT_ARM',  label = 'Left Arm' },
    { id = 3,  key = 'ZONE_RIGHT_ARM', label = 'Right Arm' },
    { id = 4,  key = 'ZONE_LEFT_LEG',  label = 'Left Leg' },
    { id = 5,  key = 'ZONE_RIGHT_LEG', label = 'Right Leg' },
    { id = 6,  key = 'ZONE_UNKNOWN',   label = 'Other' },
}

Data.ComponentById = {}
for _, entry in ipairs(Data.Components) do Data.ComponentById[entry.id] = entry end

Data.PropById = {}
for _, entry in ipairs(Data.Props) do Data.PropById[entry.id] = entry end

Data.OverlayByIndex = {}
for _, entry in ipairs(Data.HeadOverlays) do Data.OverlayByIndex[entry.index] = entry end

Data.ModelByName = {}
for _, entry in ipairs(Data.Models) do Data.ModelByName[entry.name] = entry end

function Data.default(model)
    local overlays = {}
    for _, overlay in ipairs(Data.HeadOverlays) do
        overlays[overlay.key] = { style = 0, opacity = 0.0, colour = 0, secondColour = 0 }
    end

    local features = {}
    for _, feature in ipairs(Data.FaceFeatures) do features[feature.key] = 0.0 end

    local components = {}
    for i, entry in ipairs(Data.Components) do
        components[i] = { component_id = entry.id, drawable = 0, texture = 0 }
    end

    local props = {}
    for i, entry in ipairs(Data.Props) do
        props[i] = { prop_id = entry.id, drawable = -1, texture = 0 }
    end

    return {
        model = model or 'mp_m_freemode_01',
        headBlend = {
            shapeFirst = 0, shapeSecond = 0, shapeThird = 0,
            skinFirst = 0, skinSecond = 0, skinThird = 0,
            shapeMix = 0.5, skinMix = 0.5, thirdMix = 0.0,
        },
        faceFeatures = features,
        headOverlays = overlays,
        hair = { style = 0, colour = 0, highlight = 0, texture = 0 },
        eyeColour = 0,
        components = components,
        props = props,
        tattoos = {},
    }
end
