-- Qbox (qbx_core) client adapter.
-- Reports as 'qb-core' so cl_edit.lua drives qb-vehiclekeys events, which
-- qbx_vehiclekeys handles through its qb compatibility bridge.
if GetResourceState('qbx_core') ~= 'started' then return end
if GetResourceState('qb-core') == 'started' then return end -- let the real qb adapter win if both exist

Framework = { name = 'qb-core' }

local core = exports.qbx_core
local ox_inventory = GetResourceState('ox_inventory') == 'started'

function Framework.isPlayerLoaded()
    local data = core:GetPlayerData()
    return data ~= nil and data.citizenid ~= nil
end

---@diagnostic disable-next-line: duplicate-set-field
function Framework.getJob()
    if not Framework.isPlayerLoaded() then
        return false
    end
    return core:GetPlayerData().job.name
end

function Framework.hasItem(name)
    if ox_inventory then
        local count = exports.ox_inventory:Search('count', name)
        return type(count) == 'number' and count > 0
    end
    return false
end

local function toHash(model)
    return type(model) == 'string' and joaat(model) or model
end

local function createVehicle(model, coords, heading, networked, cb)
    model = toHash(model)
    lib.requestModel(model, 10000)
    local entity = CreateVehicle(model, coords.x, coords.y, coords.z, heading or 0.0, networked, false)
    SetModelAsNoLongerNeeded(model)
    if cb then cb(entity) end
    return entity
end

function Framework.spawnVehicle(model, coords, heading, cb)
    return createVehicle(model, coords, heading, true, cb)
end

function Framework.spawnLocalVehicle(model, coords, heading, cb)
    return createVehicle(model, coords, heading, false, cb)
end

function Framework.deleteVehicle(vehicle)
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    end
end

function Framework.getPlayersInArea(coords, maxDistance)
    local players = {}
    for _, id in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(id)
        if ped ~= cache.ped and DoesEntityExist(ped) then
            if #(coords - GetEntityCoords(ped)) <= maxDistance then
                players[#players + 1] = GetPlayerServerId(id)
            end
        end
    end
    return players
end

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
