function ShowNotification(message, notifyType)
    lib.notify({
        description = message,
        type = notifyType,
        position = 'top-right'
    })
end

RegisterNetEvent('lunar_garage:showNotification')
AddEventHandler('lunar_garage:showNotification', ShowNotification)

function ShowUI(text, icon)
    if icon == 0 then
        lib.showTextUI(text)
    else
        lib.showTextUI(text, {
            icon = icon
        })
    end
end

function HideUI()
    lib.hideTextUI()
end

function GetVehicleFuel(vehicle)
    if GetResourceState('LegacyFuel') == 'started' then
        local fuelLevel = exports['LegacyFuel']:GetFuel(vehicle)
        return math.floor(fuelLevel * 100) / 100
    end

    -- ox_fuel / most modern fuel scripts expose the level via a statebag.
    local state = Entity(vehicle).state.fuel
    if state ~= nil then
        return math.floor(state * 100) / 100
    end

    return GetVehicleFuelLevel(vehicle)
end

function SetVehicleFuel(vehicle, fuelLevel)
    if GetResourceState('LegacyFuel') == 'started' then
        exports['LegacyFuel']:SetFuel(vehicle, fuelLevel)
        return
    end

    -- ox_fuel and similar read the replicated statebag; also set the native
    -- level so scripts reading it directly stay in sync.
    Entity(vehicle).state:set('fuel', fuelLevel + 0.0, true)
    SetVehicleFuelLevel(vehicle, fuelLevel + 0.0)
end

function SetVehicleOwner(plate)
    if not Config.UseKeySystem then return end

    if Framework.name == 'es_extended' then
        -- Not implemented
    elseif Framework.name == 'qb-core' then
        TriggerEvent("vehiclekeys:client:SetOwner", plate)
    end
end