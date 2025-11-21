# Impound System - How It Works

## Overview
The impound system automatically detects when a vehicle is lost/destroyed and allows players to retrieve it for a fee.

## Detection Logic (Server)

### When fetching garage vehicles (`lunar_garage:getOwnedVehicles`):

```lua
if vehicle.stored == 1 then
    // Vehicle is safely stored in garage
    state = 'in_garage'
    
else if vehicle.stored == 0 then
    // Vehicle is out - check if it exists in world
    
    if vehicle found in world AND healthy then
        state = 'out_garage'  // Show location
        
    else
        state = 'in_impound'  // Vehicle lost/destroyed
```

## UI Display

- **in_garage**: "✓ Available in Garage" → Button: "Take Out" (Free)
- **out_garage**: "📍 Vehicle is Out" → Button: "Locate" (Sets GPS)
- **in_impound**: "🚫 Vehicle Not Found - Impounded" → Button: "Retrieve" (Costs money)

## Retrieval Flow

### Client Side (`client/main.lua`)
```lua
RegisterNetEvent('lunar_garage:client:takeOutVehicle')
    if state == 'in_impound' then
        retrieveVehicle()  // Paid retrieval
    else
        SpawnVehicle()     // Free take out
```

### Server Side (`server/main.lua`)
```lua
lib.callback.register('lunar_garage:retrieveVehicle')
    1. Check if vehicle already in world → Reject
    2. Check if player has enough money → Reject
    3. Charge Config.ImpoundPrice ($1000)
    4. Set stored = 0 (vehicle is now out)
    5. Spawn vehicle at impound location
    6. Add to activeVehicles cache
    7. Return success + netId
```

## Key Points

1. **stored = 0** means vehicle is OUT (not in garage)
2. **stored = 1** means vehicle is IN garage
3. When **stored = 0** AND vehicle not found in world = **IMPOUNDED**
4. Retrieving from impound costs **$1000** (configurable)
5. After retrieval, vehicle is spawned and **stored = 0** (it's out)

## Configuration

```lua
Config.ImpoundPrice = 1000  -- Cost to retrieve impounded vehicle
```

## Impound Locations

Defined in `Config.Impounds` - vehicles spawn at `SpawnPosition` when retrieved.

## Troubleshooting

If a vehicle shows as impounded but shouldn't be:
1. Check database: `stored` column value
2. Check server console for vehicle search logs
3. Verify vehicle entity exists in world
4. Check `activeVehicles` cache on server

## Recent Improvements

- Added better error handling and notifications
- Added refund if spawn fails
- Added timeout protection for entity spawning
- Added detailed debug logging
- Added validation for impound index
