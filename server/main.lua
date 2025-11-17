-- Used to store vehicles that have been taken out
---@type table<string, number>
local activeVehicles = {}

lib.callback.register('lunar_garage:getOwnedVehicles', function(source, index, society)
    local player = Framework.getPlayerFromId(source)
    if not player then return end
    
    local garage = Config.Garages[index]

    if society then
        local vehicles = MySQL.query.await(Queries.getGarageSociety, {
            player:getJob(), garage.Type
        })

        for _, vehicle in ipairs(vehicles) do
            if vehicle.stored == 1 or vehicle.stored == true then
                vehicle.state = 'in_garage'
            elseif activeVehicles[vehicle.plate] then
                local entity = activeVehicles[vehicle.plate]
                if not DoesEntityExist(entity) then
                    activeVehicles[vehicle.plate] = nil
                    vehicle.state = 'in_impound'
                elseif GetVehiclePetrolTankHealth(entity) <= 0 or GetVehicleBodyHealth(entity) <= 0 then
                    DeleteEntity(entity)
                    activeVehicles[vehicle.plate] = nil
                    vehicle.state = 'in_impound'
                else
                    vehicle.state = 'out_garage'
                end
            else
                vehicle.state = 'in_impound'
            end
        end

        return vehicles
    else
        local vehicles = MySQL.query.await(Queries.getGarage, {
            player:getIdentifier(), garage.Type
        })

        for _, vehicle in ipairs(vehicles) do
            if vehicle.stored == 1 or vehicle.stored == true then
                vehicle.state = 'in_garage'
            elseif activeVehicles[vehicle.plate] then
                local entity = activeVehicles[vehicle.plate]
                if not DoesEntityExist(entity) then
                    activeVehicles[vehicle.plate] = nil
                    vehicle.state = 'in_impound'
                elseif not DoesEntityExist(entity) or GetVehiclePetrolTankHealth(entity) <= 0 or GetVehicleBodyHealth(entity) <= 0 then
                    DeleteEntity(entity)
                    activeVehicles[vehicle.plate] = nil
                    vehicle.state = 'in_impound'
                else
                    vehicle.state = 'out_garage'
                end
            else
                vehicle.state = 'in_impound'
            end
        end

        return vehicles
    end
end)

lib.callback.register('lunar_garage:getImpoundedVehicles', function(source, index, society)
    local player = Framework.getPlayerFromId(source)
    if not player then return end
    
    local impound = Config.Impounds[index]

    if society then
        local vehicles = MySQL.query.await(Queries.getImpoundSociety, {
            player:getJob(), impound.Type
        })

        local filtered = {}

        for _, vehicle in ipairs(vehicles) do
            local entity = activeVehicles[vehicle.plate]

            if not entity then
                table.insert(filtered, vehicle)
            elseif not DoesEntityExist(entity) then
                activeVehicles[vehicle.plate] = nil
                table.insert(filtered, vehicle)
            elseif GetVehiclePetrolTankHealth(entity) <= 0 or GetVehicleBodyHealth(entity) <= 0 then
                DeleteEntity(entity)
                activeVehicles[vehicle.plate] = nil
                table.insert(filtered, vehicle)
            end
        end

        return filtered
    else
        local vehicles = MySQL.query.await(Queries.getImpound, {
            player:getIdentifier(), impound.Type
        })

        local filtered = {}

        for _, vehicle in ipairs(vehicles) do
            local entity = activeVehicles[vehicle.plate]

            if not entity then
                table.insert(filtered, vehicle)
            elseif not DoesEntityExist(entity) then
                activeVehicles[vehicle.plate] = nil
                table.insert(filtered, vehicle)
            elseif GetVehiclePetrolTankHealth(entity) <= 0 or GetVehicleBodyHealth(entity) <= 0 then
                DeleteEntity(entity)
                activeVehicles[vehicle.plate] = nil
                table.insert(filtered, vehicle)
            end
        end

        return filtered
    end
end)

lib.callback.register('lunar_garage:takeOutVehicle', function(source, index, plate, type)
    local player = Framework.getPlayerFromId(source)
    if not player then return end

    local vehicle = MySQL.single.await(Queries.getStoredVehicle, {
        player:getIdentifier(), player:getJob(), plate, 1
    })

    if vehicle then
        MySQL.update.await(Queries.setStoredVehicle, { 0, plate })
        local garage = Config.Garages[index]
        local coords = garage.SpawnPosition
        local props = json.decode(vehicle.mods or vehicle.vehicle)
        local entity = Utils.createVehicle(props.model, coords, type)

        if entity == 0 then return end

        while NetworkGetEntityOwner(entity) == -1 do Wait(0) end

        local netId, owner = NetworkGetNetworkIdFromEntity(entity), NetworkGetEntityOwner(entity)
        
        TriggerClientEvent('lunar_garage:setVehicleProperties', owner, netId, props)

        activeVehicles[plate] = entity

        return netId
    end
end)

lib.callback.register('lunar_garage:saveVehicle', function(source, props, netId)
    local player = Framework.getPlayerFromId(source)
    if not player then 
        print("^1[GARAGE DEBUG] Player not found for source:", source)
        return false 
    end

    -- Get the original plate from the vehicle
    local originalPlate = props.plate
    local playerIdentifier = player:getIdentifier()
    
    print("^3[GARAGE DEBUG] ==========================================")
    print("^3[GARAGE DEBUG] Attempting to save vehicle")
    print("^3[GARAGE DEBUG] Player Identifier:", playerIdentifier)
    print("^3[GARAGE DEBUG] Original Plate:", originalPlate)
    print("^3[GARAGE DEBUG] Plate Length:", string.len(originalPlate))
    print("^3[GARAGE DEBUG] Vehicle Model:", props.model)
    print("^3[GARAGE DEBUG] Query:", Queries.getVehicleStrict)
    
    -- Check if vehicle is owned by player using their identifier with original plate
    local vehicle = MySQL.single.await(Queries.getVehicleStrict, {
        playerIdentifier, originalPlate
    })
    
    print("^3[GARAGE DEBUG] First query result (original plate):", vehicle and "FOUND" or "NOT FOUND")
    
    -- If not found, try with trimmed plate
    if not vehicle then
        local trimmedPlate = originalPlate:gsub("%s+", "")
        print("^3[GARAGE DEBUG] Trying trimmed plate:", trimmedPlate)
        print("^3[GARAGE DEBUG] Trimmed Plate Length:", string.len(trimmedPlate))
        
        vehicle = MySQL.single.await(Queries.getVehicleStrict, {
            playerIdentifier, trimmedPlate
        })
        
        print("^3[GARAGE DEBUG] Second query result (trimmed plate):", vehicle and "FOUND" or "NOT FOUND")
        
        -- If found with trimmed plate, use it for updates
        if vehicle then
            originalPlate = trimmedPlate
        end
    end
    
    if vehicle then
        print("^2[GARAGE DEBUG] Vehicle found in database!")
        print("^2[GARAGE DEBUG] DB Plate:", vehicle.plate)
        print("^2[GARAGE DEBUG] DB Owner:", vehicle.owner or vehicle.citizenid)
        print("^2[GARAGE DEBUG] Ownership verified - Player owns this vehicle!")
        
        -- Use the plate from database to ensure consistency
        local dbPlate = vehicle.plate
        
        -- Get health values from props
        local engineHealth = math.floor(props.engineHealth or 1000)
        local bodyHealth = math.floor(props.bodyHealth or 1000)
        
        print("^2[GARAGE DEBUG] Saving vehicle with plate:", dbPlate)
        print("^2[GARAGE DEBUG] Engine Health:", engineHealth)
        print("^2[GARAGE DEBUG] Body Health:", bodyHealth)
        
        -- Update vehicle as stored and save properties using database plate
        MySQL.update.await(Queries.setStoredVehicle, { 1, dbPlate })
        MySQL.update.await(Queries.setVehicleProps, { json.encode(props), dbPlate })
        
        -- Update health values in database
        local healthQuery = 'UPDATE %s SET engine_health = ?, body_health = ? WHERE plate = ?'
        local table = Framework.name == 'es_extended' and 'owned_vehicles' or 'player_vehicles'
        healthQuery = healthQuery:format(table)
        MySQL.update.await(healthQuery, { engineHealth, bodyHealth, dbPlate })

        -- Delete the vehicle entity after a short delay
        SetTimeout(500, function()
            local vehicleEntity = NetworkGetEntityFromNetworkId(netId)
            
            if DoesEntityExist(vehicleEntity) then
                DeleteEntity(vehicleEntity)
            end
        end)

        -- Remove from active vehicles tracking (try both formats)
        activeVehicles[props.plate] = nil
        activeVehicles[dbPlate] = nil
        activeVehicles[originalPlate] = nil

        print("^2[GARAGE DEBUG] Vehicle saved successfully!")
        print("^3[GARAGE DEBUG] ==========================================^0")
        return true
    end
    
    print("^1[GARAGE DEBUG] Vehicle NOT FOUND in database - ownership check failed!")
    print("^1[GARAGE DEBUG] This means the plate doesn't match any vehicle owned by this player")
    print("^3[GARAGE DEBUG] ==========================================^0")
    return false
end)

lib.callback.register('lunar_garage:retrieveVehicle', function(source, index, plate, type)
    if activeVehicles[plate] then return end

    local player = Framework.getPlayerFromId(source)
    if not player then return end

    local vehicle = MySQL.single.await(Queries.getOwnedVehicle, {
        player:getIdentifier(), player:getJob(), plate
    })

    if vehicle then
        local impoundPrice = Config.ImpoundPrice
        local bankMoney = player:getAccountMoney('bank')
        local cashMoney = player:getAccountMoney('money')
        
        print("^3[GARAGE DEBUG] Retrieve vehicle attempt")
        print("^3[GARAGE DEBUG] Impound Price:", impoundPrice)
        print("^3[GARAGE DEBUG] Bank Money:", bankMoney)
        print("^3[GARAGE DEBUG] Cash Money:", cashMoney)
        
        -- Check if player has enough money in bank or cash
        if bankMoney >= impoundPrice then
            -- Charge from bank
            player:removeAccountMoney('bank', impoundPrice)
            print("^2[GARAGE DEBUG] Charged $" .. impoundPrice .. " from bank^0")
        elseif cashMoney >= impoundPrice then
            -- Charge from cash
            player:removeAccountMoney('money', impoundPrice)
            print("^2[GARAGE DEBUG] Charged $" .. impoundPrice .. " from cash^0")
        else
            -- Not enough money in either account
            print("^1[GARAGE DEBUG] Not enough money! Total: $" .. (bankMoney + cashMoney) .. " Required: $" .. impoundPrice .. "^0")
            return false
        end

        -- Update stored status to 1 (vehicle is now stored/retrieved from impound)
        MySQL.update.await(Queries.setStoredVehicle, { 1, plate })
        print("^2[GARAGE DEBUG] Updated stored status to 1 for plate:", plate, "^0")

        local impound = Config.Impounds[index]
        local coords = impound.SpawnPosition
        local props = json.decode(vehicle.mods or vehicle.vehicle)
        local entity = Utils.createVehicle(props.model, coords, type)

        if entity == 0 then return end

        while NetworkGetEntityOwner(entity) == -1 do Wait(0) end

        local netId, owner = NetworkGetNetworkIdFromEntity(entity), NetworkGetEntityOwner(entity)
        
        TriggerClientEvent('lunar_garage:setVehicleProperties', owner, netId, props)

        activeVehicles[props.plate] = entity

        print("^2[GARAGE DEBUG] Vehicle retrieved successfully!^0")
        return true, netId
    end

    return false
end)

lib.callback.register('lunar_garage:getVehicleCoords', function(source, plate)
    local entity = activeVehicles[plate]

    if not entity then return end

    return GetEntityCoords(entity)
end)

lib.callback.register('lunar_garage:transferVehicle', function(source, plate, targetPlayerId)
    if not Config.AllowVehicleTransfer then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Vehicle transfer is disabled'
        })
        return false
    end

    local player = Framework.getPlayerFromId(source)
    if not player then return false end

    local targetPlayer = Framework.getPlayerFromId(targetPlayerId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Target player not found'
        })
        return false
    end

    -- Check if vehicle is owned by the player
    local vehicle = MySQL.single.await(Queries.getVehicleStrict, {
        player:getIdentifier(), plate
    })

    if not vehicle then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You do not own this vehicle'
        })
        return false
    end

    -- Check if vehicle is stored (can't transfer if it's out)
    if vehicle.stored == 0 or vehicle.stored == false then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Vehicle must be stored in garage to transfer'
        })
        return false
    end

    -- Get identifiers for logging
    local fromIdentifier = player:getIdentifier()
    local toIdentifier = targetPlayer:getIdentifier()
    
    print("^3[GARAGE TRANSFER] ==========================================")
    print("^3[GARAGE TRANSFER] Transferring vehicle")
    print("^3[GARAGE TRANSFER] From Player ID:", source, "Char ID:", fromIdentifier)
    print("^3[GARAGE TRANSFER] To Player ID:", targetPlayerId, "Char ID:", toIdentifier)
    print("^3[GARAGE TRANSFER] Plate:", plate)
    print("^3[GARAGE TRANSFER] Query:", Queries.transferVehiclePlayer)
    
    -- Transfer the vehicle
    local affectedRows = MySQL.update.await(Queries.transferVehiclePlayer, {
        toIdentifier, plate
    })

    print("^2[GARAGE TRANSFER] Vehicle transferred successfully!^0")
    print("^2[GARAGE TRANSFER] Database rows affected:", affectedRows)
    print("^3[GARAGE TRANSFER] ==========================================^0")

    -- Notify both players
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = 'Vehicle transferred successfully to player ' .. targetPlayerId
    })

    TriggerClientEvent('ox_lib:notify', targetPlayerId, {
        type = 'success',
        description = 'You received a vehicle (Plate: ' .. plate .. ')'
    })

    return true
end)