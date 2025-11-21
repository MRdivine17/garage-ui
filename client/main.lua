local function getVehicleType(model)
    if IsThisModelABike(model) then
        return 'bike'
    end

    -- Not really sure if quadbike is considered an automobile or a bike
    if IsThisModelACar(model) or IsThisModelAQuadbike(model) then
        return 'automobile'
    end

    if IsThisModelABoat(model) or IsThisModelAJetski(model) then
        return 'boat'
    end

    if IsThisModelAPlane(model) then
        return 'plane'
    end

    if IsThisModelAHeli(model) then
        return 'heli'
    end
end

-- Enhanced vehicle properties setter with better OneSync handling
RegisterNetEvent('lunar_garage:setVehicleProperties', function(netId, data)
    local timeout = 10000
    local startTime = GetGameTimer()

    -- Wait for entity to exist in network
    while not NetworkDoesEntityExistWithNetworkId(netId) and (GetGameTimer() - startTime) < timeout do
        Wait(0)
    end

    if (GetGameTimer() - startTime) >= timeout then
        print("^1[GARAGE CLIENT] Timeout waiting for network entity:", netId, "^0")
        return
    end

    local vehicle = NetToVeh(netId)
    
    if not vehicle or vehicle == 0 then
        print("^1[GARAGE CLIENT] Invalid vehicle entity from netId:", netId, "^0")
        return
    end

    -- Wait for entity to be fully networked
    local networkTimeout = 0
    while not NetworkGetEntityIsNetworked(vehicle) and networkTimeout < 100 do
        Wait(10)
        networkTimeout = networkTimeout + 1
    end

    if networkTimeout >= 100 then
        print("^1[GARAGE CLIENT] Vehicle not networked:", vehicle, "^0")
        return
    end

    -- Set properties regardless of ownership for better sync
    -- The owner will set it first, then nearby players will sync
    local isOwner = NetworkGetEntityOwner(vehicle) == cache.playerId
    
    if isOwner then
        print("^2[GARAGE CLIENT] Setting properties as owner - Vehicle:", vehicle, "^0")
    else
        print("^3[GARAGE CLIENT] Syncing properties as nearby player - Vehicle:", vehicle, "^0")
    end
    
    -- Use a protected call to prevent errors from breaking sync
    local success, err = pcall(lib.setVehicleProperties, vehicle, data)
    
    if not success then
        print("^1[GARAGE CLIENT] Error setting vehicle properties:", err, "^0")
    else
        print("^2[GARAGE CLIENT] Properties set successfully^0")
    end
end)

function SpawnVehicle(args)
    ---@type integer, VehicleProperties
    local index, props in args
    
    local garage = Config.Garages[index]
    
    if Config.SpawnpointCheck and lib.getClosestVehicle(garage.SpawnPosition.xyz, 3.0, false) then
        ShowNotification(locale('spawn_occupied'), 'error')
        return
    end

    lib.requestModel(props.model)
    local type = getVehicleType(props.model)
    local netId = lib.callback.await('lunar_garage:takeOutVehicle', false, index, props.plate, type)
    
    while not NetworkDoesEntityExistWithNetworkId(netId) do Wait(0) end

    local vehicle = NetworkGetEntityFromNetworkId(netId)

    CreateThread(function()
        while true do
            if NetworkGetEntityOwner(vehicle) == cache.playerId then
                lib.setVehicleProperties(vehicle, props)
                return
            end

            local plate = GetVehicleNumberPlateText(vehicle)

            if plate == props.plate then
                return
            end

            Wait(0)
        end
    end)

    -- The player doesn't get warped in the vehicle sometimes, repeat it and timeout after 2000 attempts
    for _ = 1, 2000 do
        TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
    
        if GetVehiclePedIsIn(cache.ped, false) == vehicle then
            break
        end

        Wait(0)
    end

    SetVehicleFuel(vehicle, props.fuelLevel or 100.0)
    SetVehicleOwner(props.plate)
end

function GetVehicleLabel(model)
    local label = GetLabelText(GetDisplayNameFromVehicleModel(model))
    
    if label == 'NULL' then 
        label = GetDisplayNameFromVehicleModel(model)
    end

    return label
end

local function getClassIcon(class)
    if class == 8 then
        return 'motorcycle'
    elseif class == 13 then
        return 'bicycle'
    elseif class == 15 then
        return 'helicopter'
    else
        return 'car'
    end
end

local function getFuelBarColor(fuel)
    -- fuelLevel not defined in vehicleProps??
    if not fuel then return 'lime' end

    if fuel > 75.0 then
        return 'lime'
    elseif fuel > 50.0 then
        return 'yellow'
    elseif fuel > 25.0 then
        return 'orange'
    else
        return 'red'
    end
end

local function openGarageVehicles(args)
    local index, society = args.index, args.society
    
    print("^3[GARAGE CLIENT] Fetching vehicles for garage index:", index, "^0")
    local vehicles = lib.callback.await('lunar_garage:getOwnedVehicles', false, index, society)
    
    if #vehicles == 0 then
        ShowNotification(society and locale('no_society_vehicles') or locale('no_owned_vehicles'), 'error')
        currentOpenGarage = nil
        currentOpenSociety = false
        return
    end

    -- Prepare vehicles data for custom UI
    local vehiclesData = {}

    for _, vehicle in ipairs(vehicles) do
        ---@type VehicleProperties
        local props = json.decode(vehicle.mods or vehicle.vehicle)

        table.insert(vehiclesData, {
            label = GetVehicleLabel(props.model),
            plate = props.plate,
            state = vehicle.state,
            location = vehicle.location,
            fuelLevel = props.fuelLevel or 100.0,
            engineHealth = vehicle.engine_health or props.engineHealth or 1000,
            bodyHealth = vehicle.body_health or props.bodyHealth or 1000,
            props = props,
            garageIndex = index,
            modelName = GetDisplayNameFromVehicleModel(props.model):lower(),
            customImage = vehicle.vehicle_image
        })
    end

    -- Store current garage for refresh
    currentOpenGarage = index
    currentOpenSociety = society or false
    
    print("^2[GARAGE CLIENT] Opening UI with", #vehiclesData, "vehicles^0")

    -- Open custom UI
    Framework.OpenGarageUI(vehiclesData, index, society)
end

local function openGarage(index)
    -- Open player vehicles directly with custom UI
    openGarageVehicles({ index = index, society = false })
end

---@param vehicle number?
local function saveVehicle(vehicle)
    if not vehicle and cache.seat ~= -1 then
        ShowNotification(locale('not_driver'), 'error')
        return
    end

    local vehicle = cache.vehicle or vehicle
    
    if not DoesEntityExist(vehicle) then
        ShowNotification(locale('not_your_vehicle'), 'error')
        return
    end
    
    local props = lib.getVehicleProperties(vehicle)

    if not props then 
        ShowNotification(locale('not_your_vehicle'), 'error')
        return 
    end

    -- Keep the original plate format, let server handle matching
    props.fuelLevel = GetVehicleFuel(vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    
    print("^3[GARAGE CLIENT DEBUG] ==========================================")
    print("^3[GARAGE CLIENT DEBUG] Attempting to save vehicle")
    print("^3[GARAGE CLIENT DEBUG] Plate from vehicle:", props.plate)
    print("^3[GARAGE CLIENT DEBUG] Plate length:", string.len(props.plate))
    print("^3[GARAGE CLIENT DEBUG] Vehicle model:", props.model)
    print("^3[GARAGE CLIENT DEBUG] Network ID:", netId)
    print("^3[GARAGE CLIENT DEBUG] ==========================================^0")
    
    -- Call server to save vehicle
    local result = lib.callback.await('lunar_garage:saveVehicle', false, props, netId)
    
    if result then
        if cache.vehicle then
            TaskLeaveAnyVehicle(cache.ped, 0, 0)
            Wait(1000)
        end

        ShowNotification(locale('vehicle_saved'), 'success')
    else
        ShowNotification(locale('not_your_vehicle'), 'error')
    end
end

local function retrieveVehicle(args)
    ---@type integer, VehicleProperties
    local index, props in args
    
    print("^3[GARAGE CLIENT] ========== Retrieving Vehicle from Impound ==========")
    print("^3[GARAGE CLIENT] Plate:", props.plate)
    print("^3[GARAGE CLIENT] Model:", props.model)
    print("^3[GARAGE CLIENT] Index:", index)
    
    if not props.model then
        print("^1[GARAGE CLIENT] Invalid vehicle model^0")
        ShowNotification('Invalid vehicle data', 'error')
        return
    end
    
    lib.requestModel(props.model)
    local type = getVehicleType(props.model)
    
    print("^3[GARAGE CLIENT] Calling server to retrieve vehicle...^0")
    local success, netId = lib.callback.await('lunar_garage:retrieveVehicle', false, index, props.plate, type)

    print("^3[GARAGE CLIENT] Server response - Success:", tostring(success), "NetID:", tostring(netId))

    -- Check if retrieval failed
    if not success or success == false then
        print("^1[GARAGE CLIENT] Failed to retrieve vehicle - Server returned false^0")
        -- Server already sends notification with specific error
        return
    end

    -- If no netId, vehicle was retrieved to garage (not spawned)
    if not netId then
        print("^2[GARAGE CLIENT] Vehicle retrieved to garage successfully (not spawned)^0")
        print("^3[GARAGE CLIENT] ========== End Retrieve Vehicle ==========^0")
        return
    end

    print("^2[GARAGE CLIENT] Waiting for vehicle entity with netId:", netId, "^0")
    local timeout = 0
    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout < 5000 do 
        Wait(10)
        timeout = timeout + 10
    end

    if timeout >= 5000 then
        print("^1[GARAGE CLIENT] Timeout waiting for vehicle entity^0")
        ShowNotification('Failed to spawn vehicle - entity timeout', 'error')
        return
    end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if not vehicle or vehicle == 0 then
        print("^1[GARAGE CLIENT] Invalid vehicle entity^0")
        ShowNotification('Failed to spawn vehicle - invalid entity', 'error')
        return
    end
    
    print("^2[GARAGE CLIENT] Vehicle entity found:", vehicle, "^0")

    -- Set properties in a thread
    CreateThread(function()
        local attempts = 0
        while attempts < 100 do
            if NetworkGetEntityOwner(vehicle) == cache.playerId then
                local success, err = pcall(lib.setVehicleProperties, vehicle, props)
                if success then
                    print("^2[GARAGE CLIENT] Properties set by owner^0")
                else
                    print("^1[GARAGE CLIENT] Error setting properties:", err, "^0")
                end
                return
            end

            local plate = GetVehicleNumberPlateText(vehicle)
            if plate == props.plate then
                print("^2[GARAGE CLIENT] Plate matches, properties already set^0")
                return
            end

            Wait(10)
            attempts = attempts + 1
        end
        print("^3[GARAGE CLIENT] Property setting timeout^0")
    end)

    -- Warp player into vehicle
    print("^2[GARAGE CLIENT] Warping player into vehicle...^0")
    for i = 1, 2000 do
        TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
        
        if GetVehiclePedIsIn(cache.ped, false) == vehicle then
            print("^2[GARAGE CLIENT] Player warped successfully^0")
            break
        end

        Wait(0)
    end

    SetVehicleFuel(vehicle, props.fuelLevel or 100.0)
    SetVehicleOwner(props.plate)
    
    print("^2[GARAGE CLIENT] Vehicle retrieved successfully!^0")
    print("^3[GARAGE CLIENT] ========== End Retrieve Vehicle ==========^0")
end

-- Event handler for taking out vehicle from custom UI
RegisterNetEvent('lunar_garage:client:takeOutVehicle', function(data)
    -- Check if it's an impounded vehicle (vehicle not found in world and stored = 0)
    if data.vehicle.state == 'in_impound' then
        -- This is a true impound - vehicle is lost/destroyed, needs to be retrieved with payment
        -- UI will close automatically when server sends 'retrieving' state
        retrieveVehicle({
            index = data.garageIndex,
            props = data.vehicle.props
        })
    else
        -- Normal garage vehicle (stored = 1) - take out for free
        Framework.CloseGarageUI()
        SpawnVehicle({
            index = data.garageIndex,
            props = data.vehicle.props
        })
    end
end)

local function openImpoundVehicles(args)
    local index, society = args.index, args.society
    
    print("^3[GARAGE CLIENT] Fetching impounded vehicles for index:", index, "^0")
    local vehicles = lib.callback.await('lunar_garage:getImpoundedVehicles', false, index, society)
    
    if #vehicles == 0 then
        ShowNotification(locale('no_impounded_vehicles'), 'error')
        currentOpenGarage = nil
        currentOpenSociety = false
        return
    end

    -- Prepare vehicles data for custom UI
    local vehiclesData = {}

    for _, vehicle in ipairs(vehicles) do
        ---@type VehicleProperties
        local props = json.decode(vehicle.mods or vehicle.vehicle)

        table.insert(vehiclesData, {
            label = GetVehicleLabel(props.model),
            plate = props.plate,
            state = 'in_impound',
            fuelLevel = props.fuelLevel or 100.0,
            engineHealth = vehicle.engine_health or props.engineHealth or 1000,
            bodyHealth = vehicle.body_health or props.bodyHealth or 1000,
            props = props,
            garageIndex = index,
            isImpound = true,
            modelName = GetDisplayNameFromVehicleModel(props.model):lower(),
            customImage = vehicle.vehicle_image
        })
    end

    -- Store current garage for refresh (use negative index for impounds to differentiate)
    currentOpenGarage = -index -- Negative to indicate impound
    currentOpenSociety = society or false
    
    print("^2[GARAGE CLIENT] Opening impound UI with", #vehiclesData, "vehicles^0")

    -- Open custom UI
    Framework.OpenGarageUI(vehiclesData, index, society)
end

local function openImpound(index)
    -- Open impound vehicles directly with custom UI
    openImpoundVehicles({ index = index, society = false })
end

-- Store current garage/impound index for refresh
local currentOpenGarage = nil
local currentOpenSociety = false

-- Listen for vehicle state changes to refresh UI
RegisterNetEvent('lunar_garage:vehicleStateChanged', function(plate, newState)
    print("^3[GARAGE CLIENT] Vehicle state changed for plate:", plate, "New state:", newState, "^0")
    
    -- If state is "retrieving", close UI immediately (no refresh needed)
    if newState == 'retrieving' then
        print("^2[GARAGE CLIENT] Vehicle being retrieved - closing UI immediately^0")
        Framework.CloseGarageUI()
        return
    end
    
    -- If a garage UI is currently open, refresh it
    if currentOpenGarage then
        print("^3[GARAGE CLIENT] Refreshing UI...^0")
        
        -- Small delay to ensure database is updated
        Wait(100)
        
        -- Refresh the appropriate UI
        if currentOpenGarage < 0 then
            -- Negative index means impound
            openImpoundVehicles({ index = math.abs(currentOpenGarage), society = currentOpenSociety })
        else
            -- Positive index means garage
            openGarageVehicles({ index = currentOpenGarage, society = currentOpenSociety })
        end
    end
end)

-- Clear current garage when UI is closed
RegisterNetEvent('lunar_garage:client:uiClosed', function()
    print("^3[GARAGE CLIENT] UI closed, clearing current garage^0")
    currentOpenGarage = nil
    currentOpenSociety = false
end)

-- Event handler for retrieving impounded vehicle from custom UI
RegisterNetEvent('lunar_garage:client:retrieveVehicle', function(data)
    Framework.CloseGarageUI()
    
    retrieveVehicle({
        index = data.garageIndex,
        props = data.vehicle.props
    })
end) 

local function garagePrompt(index, data)
    if cache.vehicle then
        ShowUI(('[%s] - %s'):format(Binds.second.currentKey, locale('save_vehicle')), 'floppy-disk')
        Binds.second.addListener('garage', function()
            saveVehicle()
        end)
    else
        local prompt

        if data.Interior then
            prompt = ('[%s] - %s  \n  [%s] - %s'):format(Binds.first.currentKey, locale('open_garage'), Binds.second.currentKey, locale('enter_interior'))
        else
            prompt = (('[%s] - %s'):format(Binds.first.currentKey, locale('open_garage')))
        end

        ShowUI(prompt, 'warehouse')
        Binds.first.addListener('garage', function()
            openGarage(index)
        end)
        Binds.second.addListener('garage', function()
            EnterInterior(index)
        end)
    end
end

local currentGarageIndex

lib.onCache('vehicle', function(vehicle)
    if not currentGarageIndex then return end

    local garage = Config.Garages[currentGarageIndex]

    if not garage then return end
    
    -- Update value manually, because it gets updated after the call of onCache
    cache.vehicle = vehicle
    garagePrompt(currentGarageIndex, garage)
end)

for index, data in ipairs(Config.Garages) do
    if (not Config.Target or not data.PedPosition) and data.Position then
        lib.zones.sphere({
            coords = data.Position,
            radius = Config.MaxDistance,
            onEnter = function()
                if data.Jobs and not Utils.hasJobs(data.Jobs) then return end

                garagePrompt(index, data)
                currentGarageIndex = index
            end,
            onExit = function()
                HideUI()
                Binds.first.removeListener('garage')
                Binds.second.removeListener('garage')
                currentGarageIndex = nil
            end
        })
    elseif (Config.Target or not data.Position) and data.PedPosition then
        if not data.Model then
            warn(('Skipping garage - missing Model, index: %s'):format(index))
            goto continue
        end

        Utils.createPed(data.PedPosition, data.Model, {
            {
                label = locale('open_garage'),
                icon = 'warehouse',
                job = data.Jobs,
                args = index,
                onSelect = openGarage
            },
            {
                label = locale('enter_interior'),
                icon = 'right-to-bracket',
                job = data.Jobs,
                args = index,
                canInteract = function()
                    return data.Interior ~= nil
                end,
                onSelect = EnterInterior
            },
            {
                label = locale('save_vehicle'),
                icon = 'floppy-disk',
                job = data.Jobs,
                onSelect = function()
                    local vehicle = GetVehiclePedIsIn(cache.ped, true)

                    if Utils.distanceCheck(cache.ped, vehicle, 20.0) then
                        saveVehicle(vehicle)
                    end
                end
            }
        })
    else
        warn(('Skipping garage - missing Position or PedPosition, index: %s'):format(index))
    end

    ::continue::
end

for index, data in ipairs(Config.Impounds) do
    if (not Config.Target or not data.PedPosition) and data.Position then
        lib.zones.sphere({
            coords = data.Position,
            radius = Config.MaxDistance,
            onEnter = function()
                if data.Jobs and not Utils.hasJobs(data.Jobs) then return end

                ShowUI(('[%s] - %s'):format(Binds.first.currentKey, locale('open_impound')), 'warehouse')
                Binds.first.addListener('impound', function()
                    openImpound(index)
                end)
            end,
            onExit = function()
                HideUI()
                Binds.first.removeListener('impound')
            end
        })
    elseif (Config.Target or not data.Position) and data.PedPosition then
        if not data.Model then
            warn(('Skipping impound - missing Model, index: %s'):format(index))
            goto continue
        end

        Utils.createPed(data.PedPosition, data.Model, {
            {
                label = locale('open_impound'),
                icon = 'warehouse',
                job = data.Jobs,
                args = index,
                onSelect = openImpound
            }
        })
    else
        warn(('Skipping impound - missing Position or PedPosition, index: %s'):format(index))
    end

    ::continue::
end