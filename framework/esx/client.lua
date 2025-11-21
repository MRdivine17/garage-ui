if GetResourceState('es_extended') ~= 'started' then return end

Framework = { name = 'es_extended' }
local sharedObject = exports['es_extended']:getSharedObject()

AddEventHandler('esx:setPlayerData', function(key, val, last)
    if GetInvokingResource() == 'es_extended' then
        sharedObject.PlayerData[key] = val
        if OnPlayerData then
            OnPlayerData(key, val, last)
        end
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    sharedObject.PlayerData = xPlayer
    sharedObject.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    sharedObject.PlayerLoaded = false
    sharedObject.PlayerData = {}
end)

Framework.isPlayerLoaded = sharedObject.IsPlayerLoaded

---@diagnostic disable-next-line: duplicate-set-field
Framework.getJob = function()
    if not Framework.isPlayerLoaded() then
        return false
    end

    return sharedObject.playerData.job.name
end

Framework.hasItem = function(name)
    local playerData = sharedObject.GetPlayerData()
    for k,v in ipairs(playerData.inventory) do
        if v.name == name then
            return true
        end
    end
    return false
end

Framework.spawnVehicle = sharedObject.Game.SpawnVehicle

Framework.spawnLocalVehicle = sharedObject.Game.SpawnLocalVehicle

Framework.deleteVehicle = sharedObject.Game.DeleteVehicle

Framework.getPlayersInArea = sharedObject.Game.GetPlayersInArea

-- Custom Garage UI Functions
local isUIOpen = false

function Framework.OpenGarageUI(vehicles, garageIndex, society)
    if isUIOpen then return end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = 'openGarage',
        vehicles = vehicles,
        garageIndex = garageIndex,
        society = society or false,
        allowTransfer = Config.AllowVehicleTransfer
    })
end

function Framework.CloseGarageUI()
    if not isUIOpen then return end
    
    isUIOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = 'closeGarage'
    })
    
    -- Notify main script that UI is closed
    TriggerEvent('lunar_garage:client:uiClosed')
end

-- NUI Callbacks for Garage UI
RegisterNUICallback('closeUI', function(data, cb)
    Framework.CloseGarageUI()
    cb('ok')
end)

RegisterNUICallback('enableCursor', function(data, cb)
    SetNuiFocus(true, true)
    cb('ok')
end)

RegisterNUICallback('takeOutVehicle', function(data, cb)
    cb('ok')
    TriggerEvent('lunar_garage:client:takeOutVehicle', data)
end)

RegisterNUICallback('transferVehicle', function(data, cb)
    if not Config.AllowVehicleTransfer then
        ShowNotification('Vehicle transfer is disabled', 'error')
        cb('ok')
        return
    end
    
    local vehicle = data.vehicle
    local targetPlayerId = data.targetPlayerId
    
    if not targetPlayerId or targetPlayerId < 1 then
        ShowNotification('Invalid player ID', 'error')
        cb('ok')
        return
    end
    
    -- Call server to transfer vehicle
    lib.callback.await('lunar_garage:transferVehicle', false, vehicle.plate, targetPlayerId)
    cb('ok')
end)

RegisterNUICallback('showNotification', function(data, cb)
    ShowNotification(data.message, data.type or 'info')
    cb('ok')
end)



RegisterNUICallback('locateVehicle', function(data, cb)
    local vehicle = data.vehicle
    
    -- Try to get fresh coordinates from server
    local coords = lib.callback.await('lunar_garage:getVehicleCoords', false, vehicle.plate)
    
    -- If server doesn't have it, use cached location from vehicle data
    if not coords and vehicle.location then
        coords = vehicle.location
    end
    
    if coords then
        SetNewWaypoint(coords.x, coords.y)
        lib.notify({
            title = 'Vehicle Located',
            description = 'GPS waypoint set to your vehicle location',
            type = 'success',
            icon = 'map-pin',
            iconColor = '#00ff00'
        })
    else
        lib.notify({
            title = 'Vehicle Not Found',
            description = 'Unable to locate your vehicle. It may have been destroyed.',
            type = 'error',
            icon = 'triangle-exclamation',
            iconColor = '#ff0000'
        })
    end
    Framework.CloseGarageUI()
    cb('ok')
end)