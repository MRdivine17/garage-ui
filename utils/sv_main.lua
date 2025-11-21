lib.locale()
lib.versionCheck('https://github.com/Lunar-Scripts/lunar_garage')

Utils = {}
local resourceName = GetCurrentResourceName()

---@diagnostic disable-next-line: duplicate-set-field
function Utils.getTableSize(t)
    local count = 0

	for _,_ in pairs(t) do
		count = count + 1
	end

	return count
end

---@generic K, V
---@param t table<K, V>
---@return V, K
---@diagnostic disable-next-line: duplicate-set-field
function Utils.randomFromTable(t)
    local index = math.random(1, #t)
    return t[index], index
end

function Utils.logToDiscord(source, xPlayer, message)
    if SvConfig.Webhook == 'WEBHOOK_HERE' then return end

    local connect = {
        {
            ["color"] = "16768885",
            ["title"] = GetPlayerName(source) .. " (" .. xPlayer:GetIdentifier() .. ")",
            ["description"] = message,
            ["footer"] = {
                ["text"] = os.date('%H:%M - %d. %m. %Y', os.time()),
                ["icon_url"] = 'https://cdn.discordapp.com/attachments/793081015433560075/1048643072952647700/lunar.png',
            },
        }
    }
    PerformHttpRequest(SvConfig.Webhook, function(err, text, headers) end,
        'POST', json.encode({ username = resourceName, embeds = connect }), { ['Content-Type'] = 'application/json' })
end

---Spawns a persistent vehicle with proper OneSync handling
---@param model number
---@param coords vector4
---@param type string
---@param owner number? Optional player source to set as owner
---@return number
function Utils.createVehicle(model, coords, type, owner)
    print("^3[UTILS] Creating vehicle - Model:", model, "Type:", type, "Owner:", owner or "none", "^0")
    
    -- Create vehicle on server
    local vehicle = CreateVehicleServerSetter(model, type, coords.x, coords.y, coords.z - 0.70, coords.w)
    
    if vehicle == 0 or not vehicle then
        print("^1[UTILS] Failed to create vehicle entity^0")
        return 0
    end

    print("^2[UTILS] Vehicle entity created:", vehicle, "^0")

    -- Wait for network ID to be assigned (critical for OneSync)
    local timeout = 0
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    while netId == 0 and timeout < 100 do
        Wait(10)
        netId = NetworkGetNetworkIdFromEntity(vehicle)
        timeout = timeout + 1
    end

    if timeout >= 100 or netId == 0 then
        print("^1[UTILS] Vehicle network timeout - deleting entity^0")
        DeleteEntity(vehicle)
        return 0
    end

    print("^2[UTILS] Vehicle networked - NetID:", netId, "^0")
    
    -- Remove any NPCs from the vehicle (server-side)
    for seatIndex = -1, 6 do
        local ped = GetPedInVehicleSeat(vehicle, seatIndex)
        if ped and ped ~= 0 then
            local pedType = GetEntityPopulationType(ped)
            if pedType and pedType > 0 and pedType < 6 then
                DeleteEntity(ped)
            end
        end
    end

    -- Set entity state for better sync across clients
    Entity(vehicle).state:set('isGarageVehicle', true, true)
    Entity(vehicle).state:set('garageSpawned', true, true)

    print("^2[UTILS] Vehicle created successfully - Entity:", vehicle, "NetID:", netId, "^0")
    
    return vehicle
end