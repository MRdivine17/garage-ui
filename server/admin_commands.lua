if not Config.AdminCommands.Enabled then return end

-- Helper function to check if player is admin
local function isAdmin(source)
    local player = Framework.getPlayerFromId(source)
    if not player then return false end
    
    -- Check if player has admin group
    for _, group in ipairs(Config.AdminCommands.AdminGroups) do
        if player:hasGroup(group) then
            return true
        end
    end
    
    return false
end

-- Helper function to generate random plate
local function generateRandomPlate()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local plate = ""
    
    -- Generate format: ABC1234 (3 letters + 4 numbers)
    for i = 1, 3 do
        local rand = math.random(1, 26)
        plate = plate .. string.sub(charset, rand, rand)
    end
    
    for i = 1, 4 do
        local rand = math.random(27, 36)
        plate = plate .. string.sub(charset, rand, rand)
    end
    
    return plate
end

-- Helper function to check if plate exists
local function plateExists(plate)
    local result = MySQL.single.await(Queries.getVehicle, { '', plate })
    return result ~= nil
end

-- /addveh command - Add vehicle to player
lib.addCommand(Config.AdminCommands.AddVehicle, {
    help = 'Add a vehicle to a player',
    params = {
        { name = 'id', type = 'playerId', help = 'Player server ID' },
        { name = 'vehicle', type = 'string', help = 'Vehicle model name' },
        { name = 'plate', type = 'string', help = 'Vehicle plate (optional)', optional = true }
    },
    restricted = false
}, function(source, args)
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You do not have permission to use this command'
        })
        return
    end

    local targetId = args.id
    local vehicleModel = args.vehicle
    local plate = args.plate

    local targetPlayer = Framework.getPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Player not found'
        })
        return
    end

    -- Generate random plate if not provided
    if not plate or plate == '' then
        repeat
            plate = generateRandomPlate()
        until not plateExists(plate)
    else
        -- Check if plate already exists
        if plateExists(plate) then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = 'Plate already exists: ' .. plate
            })
            return
        end
    end

    -- Get vehicle hash
    local vehicleHash = GetHashKey(vehicleModel)
    
    -- Create vehicle properties
    local vehicleProps = {
        model = vehicleHash,
        plate = plate
    }

    -- Insert into database
    local query
    if Framework.name == 'es_extended' then
        query = 'INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)'
        MySQL.insert.await(query, {
            targetPlayer:getIdentifier(),
            plate,
            json.encode(vehicleProps),
            'car',
            1
        })
    elseif Framework.name == 'qb-core' then
        -- `stored` = 1 so the vehicle immediately shows as parked in the garage
        -- (the garage logic keys off `stored`, not Qbox's native `state`).
        query = 'INSERT INTO player_vehicles (citizenid, plate, vehicle, mods, type, state, stored) VALUES (?, ?, ?, ?, ?, ?, ?)'
        MySQL.insert.await(query, {
            targetPlayer:getIdentifier(),
            plate,
            vehicleModel,
            json.encode(vehicleProps),
            'car',
            1,
            1
        })
    end

    print("^2[GARAGE ADMIN] Vehicle added successfully!^0")
    print("^3[GARAGE ADMIN] Admin:", source)
    print("^3[GARAGE ADMIN] Target Player:", targetId, targetPlayer:getIdentifier())
    print("^3[GARAGE ADMIN] Vehicle:", vehicleModel)
    print("^3[GARAGE ADMIN] Plate:", plate)

    -- Notify admin
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = 'Vehicle added: ' .. vehicleModel .. ' (Plate: ' .. plate .. ')'
    })

    -- Notify target player
    TriggerClientEvent('ox_lib:notify', targetId, {
        type = 'success',
        description = 'You received a vehicle: ' .. vehicleModel .. ' (Plate: ' .. plate .. ')'
    })
end)

-- /changeplate command - Change vehicle plate
lib.addCommand(Config.AdminCommands.ChangePlate, {
    help = 'Change vehicle plate number',
    params = {
        { name = 'oldplate', type = 'string', help = 'Old plate number (optional if in vehicle)', optional = true },
        { name = 'newplate', type = 'string', help = 'New plate number' }
    },
    restricted = false
}, function(source, args)
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You do not have permission to use this command'
        })
        return
    end

    local oldPlate = args.oldplate
    local newPlate = args.newplate

    -- If no old plate provided, try to get from current vehicle
    if not oldPlate or oldPlate == '' then
        local ped = GetPlayerPed(source)
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle == 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = 'You must be in a vehicle or specify the old plate'
            })
            return
        end
        
        oldPlate = GetVehicleNumberPlateText(vehicle)
        if oldPlate then
            oldPlate = oldPlate:gsub("%s+", "") -- Trim spaces
        end
    end

    -- Check if old plate exists
    if not plateExists(oldPlate) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Old plate not found: ' .. oldPlate
        })
        return
    end

    -- Check if new plate already exists
    if plateExists(newPlate) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'New plate already exists: ' .. newPlate
        })
        return
    end

    -- Update plate in database
    local query = 'UPDATE %s SET plate = ? WHERE plate = ?'
    local table = Framework.name == 'es_extended' and 'owned_vehicles' or 'player_vehicles'
    query = query:format(table)
    
    local affectedRows = MySQL.update.await(query, { newPlate, oldPlate })

    if affectedRows > 0 then
        print("^2[GARAGE ADMIN] Plate changed successfully!^0")
        print("^3[GARAGE ADMIN] Admin:", source)
        print("^3[GARAGE ADMIN] Old Plate:", oldPlate)
        print("^3[GARAGE ADMIN] New Plate:", newPlate)

        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = 'Plate changed: ' .. oldPlate .. ' → ' .. newPlate
        })

        -- Update vehicle plate if it exists in world
        local ped = GetPlayerPed(source)
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 then
            SetVehicleNumberPlateText(vehicle, newPlate)
        end
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Failed to change plate'
        })
    end
end)

-- /delveh command - Delete vehicle from database
lib.addCommand(Config.AdminCommands.DeleteVehicle, {
    help = 'Delete a vehicle from database',
    params = {
        { name = 'plate', type = 'string', help = 'Vehicle plate number' }
    },
    restricted = false
}, function(source, args)
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You do not have permission to use this command'
        })
        return
    end

    local plate = args.plate

    -- Check if plate exists
    local vehicle = MySQL.single.await(Queries.getVehicle, { '', plate })
    if not vehicle then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Vehicle not found: ' .. plate
        })
        return
    end

    -- Delete from database
    local query = 'DELETE FROM %s WHERE plate = ?'
    local table = Framework.name == 'es_extended' and 'owned_vehicles' or 'player_vehicles'
    query = query:format(table)
    
    local affectedRows = MySQL.update.await(query, { plate })

    if affectedRows > 0 then
        print("^1[GARAGE ADMIN] Vehicle deleted!^0")
        print("^3[GARAGE ADMIN] Admin:", source)
        print("^3[GARAGE ADMIN] Plate:", plate)
        print("^3[GARAGE ADMIN] Owner:", vehicle.owner or vehicle.citizenid)

        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = 'Vehicle deleted: ' .. plate
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Failed to delete vehicle'
        })
    end
end)

print("^2[GARAGE] Admin commands loaded successfully^0")
