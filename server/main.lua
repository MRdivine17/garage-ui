-- Used to store vehicles that have been taken out
---@type table<string, number>
local activeVehicles = {}

-- Function to search for a vehicle in the world by plate
local function FindVehicleByPlate(plate)
    print("^3[GARAGE] Searching for vehicle with plate:", plate, "^0")
    local vehicles = GetAllVehicles()
    print("^3[GARAGE] Total vehicles in world:", #vehicles, "^0")
    
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehiclePlate = GetVehicleNumberPlateText(vehicle)
            if vehiclePlate then
                -- Trim and compare plates
                local trimmedPlate = vehiclePlate:gsub("%s+", "")
                local searchPlate = plate:gsub("%s+", "")
                
                if trimmedPlate == searchPlate then
                    print("^2[GARAGE] Found matching vehicle! Entity:", vehicle, "Plate:", vehiclePlate, "^0")
                    return vehicle
                end
            end
        end
    end
    print("^1[GARAGE] No matching vehicle found in world^0")
    return nil
end

lib.callback.register('lunar_garage:getOwnedVehicles', function(source, index, society)
    local player = Framework.getPlayerFromId(source)
    if not player then return end
    
    local garage = Config.Garages[index]
    print("^3[GARAGE] ========== Getting Owned Vehicles ==========^0")
    print("^3[GARAGE] Player:", source, "Garage Index:", index, "Society:", tostring(society), "^0")

    if society then
        local vehicles = MySQL.query.await(Queries.getGarageSociety, {
            player:getJob(), garage.Type
        })

        for _, vehicle in ipairs(vehicles) do
            print("^3[GARAGE] Checking vehicle - Plate:", vehicle.plate, "Stored:", vehicle.stored, "^0")
            
            if vehicle.stored == 1 or vehicle.stored == true then
                vehicle.state = 'in_garage'
                vehicle.location = nil
                print("^2[GARAGE] → Status: IN_GARAGE^0")
            else
                -- First check activeVehicles cache
                local entity = activeVehicles[vehicle.plate]
                print("^3[GARAGE] Checking cache for plate:", vehicle.plate, "Found:", tostring(entity ~= nil), "^0")
                
                -- If not in cache or entity doesn't exist, search the world
                if not entity or not DoesEntityExist(entity) then
                    entity = FindVehicleByPlate(vehicle.plate)
                    if entity then
                        activeVehicles[vehicle.plate] = entity
                        local trimmedPlate = vehicle.plate:gsub("%s+", "")
                        activeVehicles[trimmedPlate] = entity
                    end
                end
                
                -- Now determine state based on entity
                if entity and DoesEntityExist(entity) then
                    if GetVehiclePetrolTankHealth(entity) <= 0 or GetVehicleBodyHealth(entity) <= 0 then
                        print("^1[GARAGE] → Vehicle destroyed^0")
                        DeleteEntity(entity)
                        activeVehicles[vehicle.plate] = nil
                        vehicle.state = 'in_impound'
                        vehicle.location = nil
                    else
                        print("^2[GARAGE] → Status: OUT_GARAGE^0")
                        vehicle.state = 'out_garage'
                        local coords = GetEntityCoords(entity)
                        vehicle.location = { x = coords.x, y = coords.y, z = coords.z }
                        print("^2[GARAGE] → Location:", coords.x, coords.y, coords.z, "^0")
                    end
                else
                    print("^1[GARAGE] → Status: IN_IMPOUND (not found)^0")
                    activeVehicles[vehicle.plate] = nil
                    vehicle.state = 'in_impound'
                    vehicle.location = nil
                end
            end
        end

        print("^3[GARAGE] ========== End Getting Vehicles ==========^0")
        return vehicles
    else
        local vehicles = MySQL.query.await(Queries.getGarage, {
            player:getIdentifier(), garage.Type
        })

        for _, vehicle in ipairs(vehicles) do
            print("^3[GARAGE] Checking vehicle - Plate:", vehicle.plate, "Stored:", vehicle.stored, "^0")
            
            if vehicle.stored == 1 or vehicle.stored == true then
                vehicle.state = 'in_garage'
                vehicle.location = nil
                print("^2[GARAGE] → Status: IN_GARAGE^0")
            else
                -- First check activeVehicles cache
                local entity = activeVehicles[vehicle.plate]
                print("^3[GARAGE] Checking cache for plate:", vehicle.plate, "Found:", tostring(entity ~= nil), "^0")
                
                -- If not in cache or entity doesn't exist, search the world
                if not entity or not DoesEntityExist(entity) then
                    entity = FindVehicleByPlate(vehicle.plate)
                    if entity then
                        activeVehicles[vehicle.plate] = entity
                        local trimmedPlate = vehicle.plate:gsub("%s+", "")
                        activeVehicles[trimmedPlate] = entity
                    end
                end
                
                -- Now determine state based on entity
                if entity and DoesEntityExist(entity) then
                    if GetVehiclePetrolTankHealth(entity) <= 0 or GetVehicleBodyHealth(entity) <= 0 then
                        print("^1[GARAGE] → Vehicle destroyed^0")
                        DeleteEntity(entity)
                        activeVehicles[vehicle.plate] = nil
                        vehicle.state = 'in_impound'
                        vehicle.location = nil
                    else
                        print("^2[GARAGE] → Status: OUT_GARAGE^0")
                        vehicle.state = 'out_garage'
                        local coords = GetEntityCoords(entity)
                        vehicle.location = { x = coords.x, y = coords.y, z = coords.z }
                        print("^2[GARAGE] → Location:", coords.x, coords.y, coords.z, "^0")
                    end
                else
                    print("^1[GARAGE] → Status: IN_IMPOUND (not found)^0")
                    activeVehicles[vehicle.plate] = nil
                    vehicle.state = 'in_impound'
                    vehicle.location = nil
                end
            end
        end

        print("^3[GARAGE] ========== End Getting Vehicles ==========^0")
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
        print("^3[GARAGE] ========== Taking Out Vehicle ==========^0")
        print("^3[GARAGE] Player:", source, "Plate:", plate, "^0")
        
        -- Update database first
        MySQL.update.await(Queries.setStoredVehicle, { 0, plate })
        
        local garage = Config.Garages[index]
        local coords = garage.SpawnPosition
        local props = json.decode(vehicle.mods or vehicle.vehicle)
        
        -- Create vehicle with owner for better sync
        local entity = Utils.createVehicle(props.model, coords, type, source)

        if entity == 0 then 
            print("^1[GARAGE] Failed to create vehicle entity^0")
            MySQL.update.await(Queries.setStoredVehicle, { 1, plate }) -- Revert
            return 
        end

        -- Wait for network owner to be assigned
        local timeout = 0
        while NetworkGetEntityOwner(entity) == -1 and timeout < 200 do 
            Wait(10)
            timeout = timeout + 1
        end

        if timeout >= 200 then
            print("^1[GARAGE] Network owner timeout^0")
            DeleteEntity(entity)
            MySQL.update.await(Queries.setStoredVehicle, { 1, plate }) -- Revert
            return
        end

        local netId = NetworkGetNetworkIdFromEntity(entity)
        local owner = NetworkGetEntityOwner(entity)
        
        print("^2[GARAGE] Network owner assigned:", owner, "NetID:", netId, "^0")
        
        -- Set vehicle properties on the owner's client
        TriggerClientEvent('lunar_garage:setVehicleProperties', owner, netId, props)
        
        -- Also broadcast to nearby players for better sync
        local playerCoords = GetEntityCoords(GetPlayerPed(source))
        local nearbyPlayers = lib.getNearbyPlayers(playerCoords, 100.0, true)
        
        for _, nearbyPlayer in ipairs(nearbyPlayers) do
            if nearbyPlayer.id ~= owner then
                TriggerClientEvent('lunar_garage:setVehicleProperties', nearbyPlayer.id, netId, props)
            end
        end

        -- Store in activeVehicles with both original and trimmed plate
        local trimmedPlate = plate:gsub("%s+", "")
        activeVehicles[plate] = entity
        activeVehicles[trimmedPlate] = entity
        
        -- Set entity state with plate for tracking
        Entity(entity).state:set('vehiclePlate', plate, true)
        Entity(entity).state:set('vehicleOwner', player:getIdentifier(), true)
        
        print("^2[GARAGE] Vehicle spawned successfully!^0")
        print("^2[GARAGE] Entity:", entity, "NetID:", netId, "Owner:", owner, "^0")
        print("^2[GARAGE] Stored with plates:", plate, "and", trimmedPlate, "^0")
        
        -- Notify nearby players to refresh their UI if open
        TriggerClientEvent('lunar_garage:vehicleStateChanged', -1, plate, 'out_garage')
        
        print("^3[GARAGE] ========== End Taking Out Vehicle ==========^0")

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

        -- Remove from active vehicles tracking (try all formats)
        activeVehicles[props.plate] = nil
        activeVehicles[dbPlate] = nil
        activeVehicles[originalPlate] = nil
        local trimmedPlate = dbPlate:gsub("%s+", "")
        activeVehicles[trimmedPlate] = nil

        -- Notify all clients that vehicle state changed
        TriggerClientEvent('lunar_garage:vehicleStateChanged', -1, dbPlate, 'in_garage')

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
    local player = Framework.getPlayerFromId(source)
    if not player then 
        print("^1[GARAGE DEBUG] Player not found for source:", source, "^0")
        return false, nil 
    end

    print("^3[GARAGE DEBUG] ========== Retrieve Vehicle from Impound ==========")
    print("^3[GARAGE DEBUG] Source:", source)
    print("^3[GARAGE DEBUG] Plate:", plate)
    print("^3[GARAGE DEBUG] Index:", index)
    print("^3[GARAGE DEBUG] Type:", type)

    -- Clean up the trimmed plate format
    local trimmedPlate = plate:gsub("%s+", "")
    
    -- Check if vehicle entity actually exists in the world (not just in cache)
    local existingEntity = activeVehicles[plate] or activeVehicles[trimmedPlate]
    if existingEntity and DoesEntityExist(existingEntity) then
        print("^1[GARAGE DEBUG] Vehicle already spawned and exists in world!^0")
        print("^1[GARAGE DEBUG] Entity ID:", existingEntity, "^0")
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Vehicle is already out in the world'
        })
        return false, nil
    else
        -- Clean up stale cache entries
        if existingEntity then
            print("^3[GARAGE DEBUG] Cleaning up stale cache entry^0")
            activeVehicles[plate] = nil
            activeVehicles[trimmedPlate] = nil
        end
    end

    local vehicle = MySQL.single.await(Queries.getOwnedVehicle, {
        player:getIdentifier(), player:getJob(), plate
    })

    if not vehicle then
        -- Try with trimmed plate
        vehicle = MySQL.single.await(Queries.getOwnedVehicle, {
            player:getIdentifier(), player:getJob(), trimmedPlate
        })
        
        if vehicle then
            print("^2[GARAGE DEBUG] Vehicle found with trimmed plate^0")
            plate = trimmedPlate -- Use trimmed plate for all operations
        end
    end

    if not vehicle then
        print("^1[GARAGE DEBUG] Vehicle not found in database^0")
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Vehicle not found'
        })
        return false, nil
    end

    print("^2[GARAGE DEBUG] Vehicle found in database^0")
    print("^2[GARAGE DEBUG] Current stored status:", vehicle.stored)

    local impoundPrice = Config.ImpoundPrice
    local cashMoney = player:getAccountMoney('money')
    
    print("^3[GARAGE DEBUG] Impound Price:", impoundPrice)
    print("^3[GARAGE DEBUG] Player Cash Money:", cashMoney)
    
    -- Check if player has enough cash
    if cashMoney < impoundPrice then
        print("^1[GARAGE DEBUG] Not enough cash! Has: $" .. cashMoney .. " Required: $" .. impoundPrice .. "^0")
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Not enough money! You need $' .. impoundPrice
        })
        return false, nil
    end
    
    -- Remove money from cash
    local removed = player:removeAccountMoney('money', impoundPrice)
    print("^2[GARAGE DEBUG] Money removal result:", tostring(removed), "^0")
    print("^2[GARAGE DEBUG] Charged $" .. impoundPrice .. " from cash^0")

    -- Set stored to 1 - vehicle is now stored in garage after retrieval
    local updateResult = MySQL.update.await(Queries.setStoredVehicle, { 1, plate })
    print("^2[GARAGE DEBUG] Updated stored status to 1 (vehicle is now in garage) for plate:", plate, "^0")
    print("^2[GARAGE DEBUG] Database update affected rows:", updateResult, "^0")

    -- IMMEDIATELY notify clients that vehicle state changed
    TriggerClientEvent('lunar_garage:vehicleStateChanged', -1, plate, 'in_garage')
    print("^2[GARAGE DEBUG] Sent immediate UI refresh event^0")
    
    print("^3[GARAGE DEBUG] ========== End Retrieve Vehicle ==========^0")
    
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = 'Vehicle retrieved from impound for $' .. impoundPrice .. ' and stored in garage'
    })
    
    -- Return success without netId since we're not spawning
    return true, nil
end)

lib.callback.register('lunar_garage:getVehicleCoords', function(source, plate)
    local entity = activeVehicles[plate]

    if not entity or not DoesEntityExist(entity) then 
        -- Try to find it in the world
        entity = FindVehicleByPlate(plate)
        if entity then
            activeVehicles[plate] = entity
        else
            activeVehicles[plate] = nil
            return nil
        end
    end

    local coords = GetEntityCoords(entity)
    return { x = coords.x, y = coords.y, z = coords.z }
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
