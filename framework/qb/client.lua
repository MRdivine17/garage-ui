if GetResourceState('qb-core') ~= 'started' then return end

Framework = { name = 'qb-core' }
local sharedObject = exports['qb-core']:GetCoreObject()

function Framework.isPlayerLoaded()
    return next(sharedObject.Functions.GetPlayerData()) ~= nil
end

---@diagnostic disable-next-line: duplicate-set-field
function Framework.getJob()
    if not Framework.isPlayerLoaded() then
        return false
    end

    return sharedObject.Functions.GetPlayerData().job.name
end

Framework.hasItem = sharedObject.Functions.HasItem

function Framework.spawnVehicle(model, coords, heading, cb)
    sharedObject.Functions.SpawnVehicle(model, cb, vector4(coords.x, coords.y, coords.z, heading), true)
end

function Framework.spawnLocalVehicle(model, coords, heading, cb)
    sharedObject.Functions.SpawnVehicle(model, cb, vector4(coords.x, coords.y, coords.z, heading), false)
end

Framework.deleteVehicle = sharedObject.Functions.DeleteVehicle

Framework.getPlayersInArea = sharedObject.Functions.GetPlayersFromCoords

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
    TriggerEvent('lunar_garage:client:takeOutVehicle', data)
    cb('ok')
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
    local coords = lib.callback.await('lunar_garage:getVehicleCoords', false, vehicle.plate)
    if coords then
        SetNewWaypoint(coords.x, coords.y)
        ShowNotification('Vehicle location marked on GPS', 'success')
    else
        ShowNotification('Unable to locate vehicle', 'error')
    end
    Framework.CloseGarageUI()
    cb('ok')
end)