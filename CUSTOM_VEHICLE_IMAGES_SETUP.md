# Custom Vehicle Images - Complete Setup Guide

## Overview
This garage system supports automatic vehicle images with three methods:
1. **Local Folder** - Best for custom vehicles (recommended)
2. **Database URL** - For external hosted images
3. **FiveM CDN** - Automatic for default vehicles

## Quick Setup (Local Folder Method)

### For Custom Vehicles:

**Step 1:** Place your vehicle image in `html/vehicles/` folder

**Step 2:** Name it exactly as the spawn code:
```
Spawn code: lamborghini  →  Filename: lamborghini.png
Spawn code: bmwm5       →  Filename: bmwm5.jpg
Spawn code: ferrarif40  →  Filename: ferrarif40.webp
```

**Step 3:** Restart resource - Done!

### Example Folder Structure:
```
lunar_garage/
└── html/
    └── vehicles/
        ├── lamborghini.png      (custom vehicle)
        ├── bmwm5.jpg           (custom vehicle)
        ├── ferrarif40.webp     (custom vehicle)
        ├── README.md
        └── QUICK_START.md
```

## Image Priority System

The system checks images in this order:

1. **Database `vehicle_image` column** (if set)
   - Highest priority
   - Use for external URLs

2. **Local folder `html/vehicles/{spawncode}.png`**
   - Checks: .webp, .png, .jpg, .jpeg
   - Best for custom vehicles

3. **FiveM CDN `https://docs.fivem.net/vehicles/{spawncode}.webp`**
   - Automatic for default GTA vehicles
   - No setup needed

4. **Fallback icon**
   - Shows if all above fail

## Database Method (Optional)

If you prefer using external URLs:

### Step 1: Add database column
```sql
-- ESX
ALTER TABLE `owned_vehicles` ADD COLUMN `vehicle_image` VARCHAR(255) NULL DEFAULT NULL AFTER `stored`;

-- QBCore
ALTER TABLE `player_vehicles` ADD COLUMN `vehicle_image` VARCHAR(255) NULL DEFAULT NULL AFTER `state`;
```

### Step 2: Set image URL
```sql
UPDATE owned_vehicles 
SET vehicle_image = 'https://your-cdn.com/lamborghini.png' 
WHERE plate = 'ABC123';
```

## Image Requirements

- **Formats**: PNG, JPG, JPEG, WEBP
- **Recommended Size**: 400x250px (16:10 ratio)
- **File Size**: Under 500KB recommended
- **Naming**: Lowercase, match spawn code exactly

## Testing

1. Add your image to `html/vehicles/` folder
2. Restart `lunar_garage` resource
3. Open garage in-game
4. Vehicle should display your custom image

## Troubleshooting

### Image not showing?
- ✓ Check filename matches spawn code exactly
- ✓ Verify file is in `html/vehicles/` folder
- ✓ Ensure format is PNG, JPG, JPEG, or WEBP
- ✓ Try restarting the resource
- ✓ Check F8 console for errors

### Wrong image showing?
- ✓ Verify spawn code is correct
- ✓ Check if database has different URL set
- ✓ Clear browser cache (Ctrl+F5)

### Image loads slowly?
- ✓ Compress/optimize image file
- ✓ Reduce image dimensions
- ✓ Use WEBP format for smaller size

## Examples

### Example 1: Single Custom Vehicle
```
Spawn code: "lamborghini"
File: html/vehicles/lamborghini.png
Result: Shows your custom Lamborghini image
```

### Example 2: Multiple Custom Vehicles
```
html/vehicles/
├── lamborghini.png
├── bmwm5.jpg
├── ferrarif40.webp
└── customcar.png
```

### Example 3: Database URL Override
```sql
-- This will override local file
UPDATE owned_vehicles 
SET vehicle_image = 'https://i.imgur.com/custom.png' 
WHERE plate = 'ABC123';
```

## Default Vehicles

Default GTA vehicles work automatically:
- adder, t20, zentorno, turismor, etc.
- No setup needed
- Images from FiveM CDN

## Advanced Tips

1. **Batch Processing**: Use same dimensions for all images
2. **Optimization**: Compress images with tools like TinyPNG
3. **Consistency**: Use same format (WEBP recommended)
4. **Organization**: Keep source images in separate folder
5. **Backup**: Keep original high-res versions

## Support Files

- `html/vehicles/README.md` - Detailed folder guide
- `html/vehicles/QUICK_START.md` - Quick reference
- `html/vehicles/EXAMPLE.txt` - Simple examples
- `VEHICLE_IMAGES.md` - Complete documentation

## Need Help?

Check the documentation files in `html/vehicles/` folder for more details and examples.
