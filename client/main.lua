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

-- Taken from ox_lib, but higher timeout value and modified
RegisterNetEvent('lunar_garage:setVehicleProperties', function(netId, data)
    local timeout = 10000

    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout > 0 do
        Wait(0)
        timeout -= 1
    end

    if timeout > 0 then
        local vehicle = NetToVeh(netId)

        if NetworkGetEntityOwner(vehicle) ~= cache.playerId then return end

        lib.setVehicleProperties(vehicle, data)
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
    local vehicles = lib.callback.await('lunar_garage:getOwnedVehicles', false, index, society)
    
    if #vehicles == 0 then
        ShowNotification(society and locale('no_society_vehicles') or locale('no_owned_vehicles'), 'error')
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
            fuelLevel = props.fuelLevel or 100.0,
            engineHealth = vehicle.engine_health or props.engineHealth or 1000,
            bodyHealth = vehicle.body_health or props.bodyHealth or 1000,
            props = props,
            garageIndex = index,
            modelName = GetDisplayNameFromVehicleModel(props.model):lower(),
            customImage = vehicle.vehicle_image
        })
    end

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
    
    lib.requestModel(props.model)
    local type = getVehicleType(props.model)
    local success, netId = lib.callback.await('lunar_garage:retrieveVehicle', false, index, props.plate, type)

    if not success then
        ShowNotification(locale('not_enough_money'), 'error')
        return
    end

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

    SetVehicleFuel(vehicle, props.fuelLevel)
    SetVehicleOwner(props.plate)
end

-- Event handler for taking out vehicle from custom UI
RegisterNetEvent('lunar_garage:client:takeOutVehicle', function(data)
    -- Check if it's an impounded vehicle
    if data.vehicle.isImpound or data.vehicle.state == 'in_impound' then
        retrieveVehicle({
            index = data.garageIndex,
            props = data.vehicle.props
        })
    else
        SpawnVehicle({
            index = data.garageIndex,
            props = data.vehicle.props
        })
    end
    Framework.CloseGarageUI()
end)

local function openImpoundVehicles(args)
    local index, society = args.index, args.society
    local vehicles = lib.callback.await('lunar_garage:getImpoundedVehicles', false, index, society)
    
    if #vehicles == 0 then
        ShowNotification(locale('no_impounded_vehicles'), 'error')
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

    -- Open custom UI
    Framework.OpenGarageUI(vehiclesData, index, society)
end

local function openImpound(index)
    -- Open impound vehicles directly with custom UI
    openImpoundVehicles({ index = index, society = false })
end

-- Event handler for retrieving impounded vehicle from custom UI
RegisterNetEvent('lunar_garage:client:retrieveVehicle', function(data)
    retrieveVehicle({
        index = data.garageIndex,
        props = data.vehicle.props
    })
    Framework.CloseGarageUI()
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