# Vehicle Health System & Animated Stats

## Overview
The garage system now saves and displays vehicle health (engine and body) with beautiful animated progress bars that load when you expand vehicle details.

## Database Setup

### Step 1: Add Health Columns
Run the SQL command in `install/add_health_columns.sql`:

```sql
-- ESX
ALTER TABLE `owned_vehicles` 
ADD COLUMN `engine_health` INT(11) DEFAULT 1000 AFTER `vehicle_image`,
ADD COLUMN `body_health` INT(11) DEFAULT 1000 AFTER `engine_health`;

-- QBCore
ALTER TABLE `player_vehicles` 
ADD COLUMN `engine_health` INT(11) DEFAULT 1000 AFTER `vehicle_image`,
ADD COLUMN `body_health` INT(11) DEFAULT 1000 AFTER `engine_health`;
```

### Step 2: Update Existing Vehicles
```sql
UPDATE `owned_vehicles` SET `engine_health` = 1000, `body_health` = 1000 WHERE `engine_health` IS NULL;
UPDATE `player_vehicles` SET `engine_health` = 1000, `body_health` = 1000 WHERE `engine_health` IS NULL;
```

## How It Works

### Saving Health Data
When a player parks their vehicle:
1. System reads current engine health (0-1000)
2. System reads current body health (0-1000)
3. Both values are saved to database
4. Values are stored with vehicle properties

### Loading Health Data
When opening garage:
1. System fetches health from database
2. Converts to percentage (0-100%)
3. Displays with animated progress bars
4. Shows real-time vehicle condition

## Animation Features

### 1. Staggered Loading
Each stat bar animates at different speeds:
- **Fuel**: 1.2 seconds (fastest)
- **Engine**: 1.5 seconds (medium)
- **Body**: 1.8 seconds (slowest)

### 2. Smooth Fill Animation
- Bars start at 0% width
- Smoothly expand to actual percentage
- Uses cubic-bezier easing for natural feel
- Opacity fades in during animation

### 3. Shimmer Effect
- Continuous shimmer animation on all bars
- Light gradient moves across the bar
- Creates premium, polished look
- Runs infinitely while visible

### 4. Number Counter
- Percentage numbers count up from 0%
- Synchronized with bar animation
- Smooth incremental counting
- Stops at exact percentage

### 5. Low Health Warning
When health is below 20%:
- Pulsing glow effect
- Increased brightness
- Red warning color
- Draws attention to damage

## Visual Design

### Color Coding
- **Fuel**: Amber/Orange gradient (#f59e0b → #fbbf24)
- **Engine**: Red gradient (#ef4444 → #f87171)
- **Body**: Cyan gradient (#06b6d4 → #22d3ee)

### Glow Effects
- Each bar has colored shadow
- Intensity matches bar color
- Creates depth and dimension
- Enhanced on low health

### Icons
- Fuel: Gas pump icon
- Engine: Settings/gear icon
- Body: Shield icon

## Health Values

### Engine Health
- **Range**: 0 - 1000
- **100%**: 1000 (perfect condition)
- **50%**: 500 (moderate damage)
- **0%**: 0 (destroyed)

### Body Health
- **Range**: 0 - 1000
- **100%**: 1000 (no damage)
- **50%**: 500 (visible damage)
- **0%**: 0 (heavily damaged)

### Fuel Level
- **Range**: 0 - 100
- **100%**: Full tank
- **50%**: Half tank
- **0%**: Empty

## Animation Triggers

### When Vehicle Details Expand:
1. Click vehicle card header
2. Details section slides down
3. Wait 100ms for smooth transition
4. Trigger stat animations
5. Bars fill from 0% to actual value
6. Numbers count up simultaneously

### Animation Sequence:
```
0.0s - Details expand
0.1s - Animation starts
1.2s - Fuel bar completes
1.5s - Engine bar completes
1.8s - Body bar completes
∞    - Shimmer continues
```

## Technical Details

### CSS Variables
```css
--fill-width: 80%  /* Target width for animation */
```

### Animation Keyframes
- `fillBarFuel`: Fuel bar animation
- `fillBarEngine`: Engine bar animation
- `fillBarBody`: Body bar animation
- `shimmer`: Continuous shimmer effect
- `pulseLow`: Low health warning pulse

### JavaScript Functions
- `animateStats($element)`: Triggers all animations
- Counter animation for percentage numbers
- CSS animation reset for re-triggering

## Database Schema

### ESX (owned_vehicles)
```sql
CREATE TABLE `owned_vehicles` (
  `owner` VARCHAR(60) NOT NULL,
  `plate` VARCHAR(12) NOT NULL,
  `vehicle` LONGTEXT,
  `type` VARCHAR(20) DEFAULT 'car',
  `stored` TINYINT(1) DEFAULT 0,
  `vehicle_image` VARCHAR(255) DEFAULT NULL,
  `engine_health` INT(11) DEFAULT 1000,
  `body_health` INT(11) DEFAULT 1000,
  PRIMARY KEY (`plate`)
);
```

### QBCore (player_vehicles)
```sql
CREATE TABLE `player_vehicles` (
  `citizenid` VARCHAR(50) NOT NULL,
  `plate` VARCHAR(15) NOT NULL,
  `vehicle` VARCHAR(50),
  `mods` LONGTEXT,
  `type` VARCHAR(20) DEFAULT 'car',
  `state` INT(11) DEFAULT 1,
  `vehicle_image` VARCHAR(255) DEFAULT NULL,
  `engine_health` INT(11) DEFAULT 1000,
  `body_health` INT(11) DEFAULT 1000,
  PRIMARY KEY (`plate`)
);
```

## Testing

### Test Health Saving:
1. Spawn a vehicle
2. Damage it (crash, shoot, etc.)
3. Park it in garage
4. Check database - health values updated
5. Retrieve vehicle - damage persists

### Test Animations:
1. Open garage
2. Click on a vehicle to expand
3. Watch bars animate from 0% to actual value
4. Numbers should count up smoothly
5. Shimmer effect should be visible

### Test Low Health Warning:
1. Damage vehicle heavily (below 20%)
2. Park and reopen garage
3. Expand vehicle details
4. Bar should pulse with red glow

## Customization

### Change Animation Speed
In `html/style.css`:
```css
.stat-fill.fuel {
    animation: fillBarFuel 1.2s ...;  /* Change 1.2s */
}
```

### Change Colors
```css
.stat-fill.fuel {
    background: linear-gradient(90deg, #YOUR_COLOR_1, #YOUR_COLOR_2);
}
```

### Disable Shimmer
Remove or comment out:
```css
.stat-fill::after {
    /* animation: shimmer 2.5s infinite; */
}
```

### Change Low Health Threshold
In `html/style.css`, modify:
```css
.stat-fill.fuel[data-percent="20"] {  /* Change threshold */
```

## Performance

- Animations use CSS transforms (GPU accelerated)
- Minimal JavaScript for counting
- No performance impact on gameplay
- Smooth 60fps animations
- Efficient database queries

## Troubleshooting

### Bars not animating?
- Check vehicle details are expanded
- Verify CSS animations are enabled
- Clear browser cache (Ctrl+F5)
- Check console for errors

### Health not saving?
- Verify database columns exist
- Check SQL was run successfully
- Ensure vehicle is being parked properly
- Check server console for errors

### Wrong health values?
- Verify database has correct values
- Check health calculation (0-1000 → 0-100%)
- Ensure props are being saved
- Test with fresh vehicle

## Notes

- Health is saved every time vehicle is parked
- Values persist between sessions
- Damaged vehicles show real condition
- Animations trigger on every expand
- Low health warnings help identify damaged vehicles
- System works with both ESX and QBCore

## Future Enhancements

Possible additions:
- Repair cost estimation based on health
- Visual damage indicators
- Health history tracking
- Maintenance reminders
- Degradation over time
- Repair shop integration
