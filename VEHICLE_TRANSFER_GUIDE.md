# Vehicle Transfer System Guide

## Overview
Players can transfer their vehicles to other players using the garage UI. The system includes proper validation, security checks, and notifications.

## Configuration

### Enable/Disable Transfers
In `config/config.lua`:
```lua
Config.AllowVehicleTransfer = true  -- Set to false to disable transfers
```

## How to Transfer a Vehicle

### Step 1: Open Garage
- Go to any garage location
- Open the garage UI

### Step 2: Select Vehicle
- Find the vehicle you want to transfer
- Click on it to expand details
- Click the "Transfer" button

### Step 3: Enter Target Player ID
- A modal will appear showing:
  - Vehicle image
  - Vehicle name
  - Vehicle plate
- Enter the **Server ID** of the target player (e.g., 1, 2, 3...)
- Click "Transfer Vehicle"

### Step 4: Confirmation
- Both players receive notifications
- Vehicle ownership is transferred immediately
- Target player can now access the vehicle from their garage

## Requirements

### For Transfer to Work:
1. ✅ You must own the vehicle
2. ✅ Vehicle must be stored in garage (not out)
3. ✅ Target player must be online
4. ✅ Config must allow transfers
5. ✅ Valid server ID must be entered

## Database Changes

The transfer updates the database:

**ESX:**
```sql
UPDATE owned_vehicles 
SET owner = 'char1:newplayerid' 
WHERE plate = 'ABC123';
```

**QBCore:**
```sql
UPDATE player_vehicles 
SET citizenid = 'newplayerid' 
WHERE plate = 'ABC123';
```

## Security Features

### Validation Checks:
- ✓ Verifies you own the vehicle
- ✓ Checks vehicle is stored (can't transfer if out)
- ✓ Validates target player exists and is online
- ✓ Respects config setting
- ✓ Prevents duplicate transfers

### Logging:
All transfers are logged to server console:
```
[GARAGE TRANSFER] Transferring vehicle
[GARAGE TRANSFER] From Player ID: 1 Char ID: char1:xxxxx
[GARAGE TRANSFER] To Player ID: 2 Char ID: char1:yyyyy
[GARAGE TRANSFER] Plate: ABC123
[GARAGE TRANSFER] Vehicle transferred successfully!
```

## Error Messages

### Common Errors:

**"Vehicle transfer is disabled"**
- Admin has disabled transfers in config
- Set `Config.AllowVehicleTransfer = true`

**"Target player not found"**
- Player with that server ID is not online
- Check server ID is correct (use `/id` or similar command)

**"You do not own this vehicle"**
- Vehicle belongs to someone else
- Check you're transferring the correct vehicle

**"Vehicle must be stored in garage to transfer"**
- Vehicle is currently out or impounded
- Store the vehicle first, then transfer

**"Invalid player ID"**
- Server ID must be a positive number
- Enter only the number (e.g., 1, 2, 3...)

## Finding Player Server ID

Players can find server IDs using:
- `/id` command (if available)
- Admin menu
- Player list (TAB menu in some servers)
- Ask the player directly

## Notifications

### Sender Receives:
```
✓ Vehicle transferred successfully to player [ID]
```

### Receiver Receives:
```
✓ You received a vehicle (Plate: ABC123)
```

## Testing

### Test Transfer:
1. Have two players online
2. Player 1 stores a vehicle in garage
3. Player 1 opens garage and clicks Transfer
4. Player 1 enters Player 2's server ID
5. Player 1 clicks "Transfer Vehicle"
6. Both players should see notifications
7. Player 2 opens garage - vehicle should appear

### Verify in Database:

**ESX:**
```sql
SELECT owner, plate FROM owned_vehicles WHERE plate = 'ABC123';
```

**QBCore:**
```sql
SELECT citizenid, plate FROM player_vehicles WHERE plate = 'ABC123';
```

The `owner`/`citizenid` should now be the target player's character ID.

## Troubleshooting

### Transfer not working?
1. Check config: `Config.AllowVehicleTransfer = true`
2. Verify vehicle is stored (not out)
3. Confirm target player is online
4. Check server console for errors
5. Verify database query is correct

### Vehicle not showing for receiver?
1. Receiver should restart garage UI
2. Check database - owner should be updated
3. Verify vehicle type matches garage type
4. Check if vehicle is marked as stored

### Image not showing in modal?
1. Check vehicle has image (custom or FiveM CDN)
2. Verify `modelName` is correct
3. Check browser console (F8) for errors
4. Try different image format

## Admin Commands

To manually transfer a vehicle in database:

**ESX:**
```sql
UPDATE owned_vehicles 
SET owner = 'char1:targetidentifier' 
WHERE plate = 'ABC123';
```

**QBCore:**
```sql
UPDATE player_vehicles 
SET citizenid = 'targetcitizenid' 
WHERE plate = 'ABC123';
```

## Notes

- Vehicle image is displayed in transfer modal
- Transfer is instant and permanent
- No confirmation dialog (be careful!)
- Both players must be online
- Vehicle properties/mods are preserved
- Plate number stays the same
- Only stored vehicles can be transferred

## Support

If you encounter issues:
1. Check server console for error messages
2. Verify database structure is correct
3. Ensure framework is properly configured
4. Check all players are using same resource version
