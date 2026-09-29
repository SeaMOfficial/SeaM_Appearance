local Core = exports.SeaM_Core:GetCoreObject()

local SeaM = exports.SeaM_Core

local cache = {}

local schemaReady = false

CreateThread(function()
    schemaReady = Core.DB.requireTables('appearance',
        { 'seam_appearance', 'seam_outfits' }, 'install/appearance.sql', 'SeaM_Appearance')
end)

local function load(citizenid)
    if cache[citizenid] then return cache[citizenid] end
    if not schemaReady then return nil end

    local row = Core.DB.single('SELECT appearance FROM seam_appearance WHERE citizenid = ?', { citizenid })
    if not row or not row.appearance then return nil end

    local ok, decoded = pcall(json.decode, row.appearance)
    if not ok or type(decoded) ~= 'table' then return nil end

    cache[citizenid] = decoded
    return decoded
end

-- character select wants the whole crew at once; one IN() beats one round-trip each
local function loadMany(citizenids)
    local out, wanted = {}, {}
    for i = 1, #citizenids do
        local id = citizenids[i]
        if cache[id] then out[id] = cache[id] elseif type(id) == 'string' then wanted[#wanted + 1] = id end
    end
    if #wanted == 0 or not schemaReady then return out end

    local marks = {}
    for i = 1, #wanted do marks[i] = '?' end

    local rows = Core.DB.query(
        ('SELECT citizenid, appearance FROM seam_appearance WHERE citizenid IN (%s)')
            :format(table.concat(marks, ',')), wanted)

    for i = 1, #rows do
        local ok, decoded = pcall(json.decode, rows[i].appearance or '')
        if ok and type(decoded) == 'table' then
            cache[rows[i].citizenid] = decoded
            out[rows[i].citizenid] = decoded
        end
    end
    return out
end

local function store(citizenid, appearance)
    cache[citizenid] = appearance
    if not schemaReady then return end

    Core.DB.enqueue(('appearance:%s'):format(citizenid), [[
        INSERT INTO seam_appearance (citizenid, appearance) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE appearance = VALUES(appearance)
    ]], { citizenid, json.encode(appearance) })
end

local function isValid(appearance)
    if type(appearance) ~= 'table' then return false end
    if type(appearance.model) ~= 'string' then return false end
    if type(appearance.components) ~= 'table' then return false end
    if type(appearance.props) ~= 'table' then return false end
    if appearance.headBlend and type(appearance.headBlend) ~= 'table' then return false end
    if #json.encode(appearance) > 60000 then return false end
    return true
end

AddEventHandler('SeaM_Core:player:loaded', function(source, player)
    local appearance = load(player.citizenid)
    TriggerClientEvent('SeaM_Appearance:client:load', source, appearance)
end)

AddEventHandler('SeaM_Core:player:unloaded', function(_, citizenid)
    cache[citizenid] = nil
end)

-- The core fires player:dropped (not player:unloaded) on disconnect.
AddEventHandler('SeaM_Core:player:dropped', function(_, citizenid)
    cache[citizenid] = nil
end)

Core.Callbacks.register('appearance:get', function(source)
    local citizenid = SeaM:GetCitizenId(source)
    return citizenid and load(citizenid) or nil
end)

Core.Callbacks.register('appearance:canAfford', function(source, price)
    return SeaM:HasMoney(source, Config.PaymentAccount, tonumber(price) or 0)
end)

Core.Callbacks.register('appearance:save', function(source, appearance, kind)
    local citizenid = SeaM:GetCitizenId(source)
    if not citizenid then return false, 'not_loaded' end
    if not isValid(appearance) then return false, 'That appearance was rejected.' end

    local price = Config.Prices[kind] or 0
    if price > 0 then
        local ok = SeaM:RemoveMoney(source, Config.PaymentAccount, price,
            ('appearance: %s'):format(kind or 'shop'))
        if not ok then return false, 'You cannot afford that.' end
    end

    store(citizenid, appearance)
    return true
end)

Core.Callbacks.register('appearance:outfits', function(source)
    local citizenid = SeaM:GetCitizenId(source)
    if not citizenid or not schemaReady then return {} end

    return Core.DB.query(
        'SELECT id, name FROM seam_outfits WHERE citizenid = ? ORDER BY id ASC',
        { citizenid })
end)

Core.Callbacks.register('appearance:getOutfit', function(source, id)
    local citizenid = SeaM:GetCitizenId(source)
    if not citizenid or not schemaReady then return nil end

    local row = Core.DB.single('SELECT outfit FROM seam_outfits WHERE id = ? AND citizenid = ?',
        { tonumber(id) or 0, citizenid })
    if not row then return nil end

    local ok, decoded = pcall(json.decode, row.outfit)
    return ok and decoded or nil
end)

Core.Callbacks.register('appearance:saveOutfit', function(source, name, outfit)
    local citizenid = SeaM:GetCitizenId(source)
    if not citizenid then return false, 'not_loaded' end
    if not schemaReady then return false, 'Outfits are unavailable right now.' end

    name = Core.Util.sanitize(name, 32)
    if not name then return false, 'Give the outfit a name.' end
    if type(outfit) ~= 'table' or type(outfit.components) ~= 'table' then
        return false, 'That outfit was rejected.'
    end

    local count = Core.DB.scalar('SELECT COUNT(*) FROM seam_outfits WHERE citizenid = ?',
        { citizenid }) or 0
    if count >= Config.MaxOutfits then
        return false, ('You can only save %d outfits.'):format(Config.MaxOutfits)
    end

    local price = Config.Prices.outfit or 0
    if price > 0 and not SeaM:RemoveMoney(source, Config.PaymentAccount, price, 'outfit saved') then
        return false, 'You cannot afford that.'
    end

    Core.DB.insert('INSERT INTO seam_outfits (citizenid, name, outfit) VALUES (?, ?, ?)',
        { citizenid, name, json.encode({ components = outfit.components, props = outfit.props }) })
    return true
end)

Core.Callbacks.register('appearance:deleteOutfit', function(source, id)
    local citizenid = SeaM:GetCitizenId(source)
    if not citizenid then return false end

    Core.DB.execute('DELETE FROM seam_outfits WHERE id = ? AND citizenid = ?',
        { tonumber(id) or 0, citizenid })
    return true
end)

exports('GetAppearance', function(citizenid) return load(citizenid) end)
exports('GetAppearances', function(citizenids)
    return type(citizenids) == 'table' and loadMany(citizenids) or {}
end)

exports('SetAppearance', function(source, appearance)
    local citizenid = SeaM:GetCitizenId(source)
    if not citizenid or not isValid(appearance) then return false end

    store(citizenid, appearance)
    TriggerClientEvent('SeaM_Appearance:client:load', source, appearance)
    return true
end)

exports('SetAppearanceOffline', function(citizenid, appearance)
    if not isValid(appearance) then return false end
    store(citizenid, appearance)
    return true
end)

Core.Commands.register('appearance', {
    help = 'Open the full appearance editor',
    permission = 'admin',
    params = {
        { name = 'target', type = 'source', help = 'Server id', optional = true },
    },
    handler = function(source, args)
        local target = args.target or source
        if target == 0 then return end
        TriggerClientEvent('SeaM_Appearance:client:openEditor', target)
    end,
})
