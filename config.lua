--- SeaM_Appearance :: configuration

Config = {}

--- Persistence -------------------------------------------------------------
--- Appearance is written to its own table rather than into core metadata, so a
--- character row stays small and a wardrobe query never drags a whole player.
Config.SaveOnChange = true   -- write immediately after a shop session
Config.MaxOutfits   = 12     -- saved outfits per character

--- Interaction -------------------------------------------------------------
--- 'auto' uses SeaM_Target when it is running and walk-in prompts when it is
--- not. 'marker' forces the prompts even with a target script installed.
--- Nothing is ever drawn on the ground either way.
Config.Interaction = 'auto'  -- 'auto' | 'target' | 'marker'
--- How close you have to be for the prompt to appear when there is no target
--- script running. Nothing is drawn on the ground either way.
Config.PointDistance = 1.8

--- What each shop type is allowed to change ---------------------------------
--- These map straight onto the editor's tabs. A barber cannot hand you a new
--- jawline, and a surgeon cannot sell you a hat.
Config.Permissions = {
    clothing = { ped = false, headBlend = false, faceFeatures = false, headOverlays = false, hair = false, components = true,  props = true,  tattoos = false },
    barber   = { ped = false, headBlend = false, faceFeatures = false, headOverlays = true,  hair = true,  components = false, props = false, tattoos = false },
    tattoo   = { ped = false, headBlend = false, faceFeatures = false, headOverlays = false, hair = false, components = false, props = false, tattoos = true  },
    surgeon  = { ped = false, headBlend = true,  faceFeatures = true,  headOverlays = false, hair = false, components = false, props = false, tattoos = false },
    creation = { ped = true,  headBlend = true,  faceFeatures = true,  headOverlays = true,  hair = true,  components = true,  props = true,  tattoos = false },
}

--- Pricing. Set a value to 0 to make that shop free. -----------------------
Config.Prices = {
    clothing = 250,
    barber   = 120,
    tattoo   = 400,
    surgeon  = 5000,
    outfit   = 0,    -- charged when saving an outfit
}
Config.PaymentAccount = 'cash' -- must exist in SeaM_Core Config.Accounts

--- Shop locations ----------------------------------------------------------
--- `blip = false` hides the map marker for that location.
Config.Shops = {
    clothing = {
        label = 'Clothing',
        blip  = { sprite = 73, colour = 47, scale = 0.7 },
        locations = {
            vector3(4512.0107, -4528.8320, 4.2204),
            vector3(-703.78, -152.26, 37.42),
            vector3(-167.86, -298.96, 39.73),
            vector3(428.7, -800.1, 29.49),
            vector3(-829.4, -1073.7, 11.33),
            vector3(-1447.8, -242.5, 49.82),
            vector3(11.63, 6514.22, 31.88),
            vector3(123.64, -219.44, 54.56),
            vector3(1696.29, 4829.31, 42.06),
            vector3(618.09, 2759.63, 42.09),
            vector3(1190.55, 2713.44, 38.22),
            vector3(-1193.43, -768.19, 17.32),
            vector3(-3172.5, 1048.1, 20.86),
        },
    },

    barber = {
        label = 'Barber',
        blip  = { sprite = 71, colour = 0, scale = 0.7 },
        locations = {
            vector3(136.83, -1708.4, 29.29),
            vector3(-32.9, -152.3, 57.08),
            vector3(-278.1, 6228.5, 31.7),
            vector3(1931.5, 3729.7, 32.85),
            vector3(1212.8, -472.9, 66.21),
            vector3(-1282.6, -1116.8, 7.0),
            vector3(-821.7, -184.1, 37.57),
        },
    },

    tattoo = {
        label = 'Tattoo Parlour',
        blip  = { sprite = 75, colour = 4, scale = 0.7 },
        locations = {
            vector3(1322.6, -1651.9, 52.28),
            vector3(-1153.6, -1425.7, 4.95),
            vector3(322.1, 180.5, 103.59),
            vector3(-3170.0, 1075.0, 20.83),
            vector3(1864.6, 3747.7, 33.03),
            vector3(-293.7, 6200.0, 31.49),
        },
    },

    surgeon = {
        label = 'Plastic Surgery',
        blip  = { sprite = 61, colour = 2, scale = 0.7 },
        locations = {
            vector3(-676.98, 311.9, 83.08),
        },
    },
}

--- Wardrobes: change outfits for free, no shop menu, personal storage only.
Config.Wardrobes = {
    label = 'Wardrobe',
    blip = false,
    locations = {
        -- add apartment / house wardrobe points here
    },
}

--- Blocked ped models. Everything else in shared/data.lua is selectable.
Config.BlockedModels = {}

--- Restrict clothing components to on-duty jobs, e.g. the police uniform
--- drawable set. Leave empty to allow everything.
--- Format: [componentId] = { [drawable] = 'jobname' }
Config.RestrictedDrawables = {}
