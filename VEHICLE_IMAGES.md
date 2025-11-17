# Vehicle Images Guide

## Overview
The garage system automatically displays vehicle images from FiveM's official CDN for default vehicles. For custom vehicles, you can set custom image URLs.

## Setup

### 1. Add Database Column
Run the SQL command in `install/add_vehicle_image_column.sql`:

```sql
-- For ESX
ALTER TABLE `owned_vehicles` ADD COLUMN `vehicle_image` VARCHAR(255) NULL DEFAULT NULL AFTER `stored`;

-- For QBCore  
ALTER TABLE `player_vehicles` ADD COLUMN `vehicle_image` VARCHAR(255) NULL DEFAULT NULL AFTER `state`;
```

### 2. How It Works

The system checks for images in this priority order:

1. **Database URL** (`vehicle_image` column) - Highest priority
2. **Local Folder** (`html/vehicles/{spawncode}.png/jpg/webp`) - Custom vehicles
3. **FiveM CDN** (`https://docs.fivem.net/vehicles/{spawncode}.webp`) - Default vehicles
4. **Fallback Icon** - If all above fail

**Default FiveM Vehicles:**
- Images are automatically fetched from FiveM CDN
- No configuration needed
- Examples: adder, t20, zentorno, etc.

**Custom Vehicles - Local Folder Method:**
- Place image in `html/vehicles/` folder
- Name it exactly as spawn code: `{spawncode}.png`
- Supports: PNG, JPG, JPEG, WEBP
- Example: `html/vehicles/lamborghini.png`

**Custom Vehicles:**
- Set the `vehicle_image` column in the database with your image URL
- Supports any image URL (direct link to .png, .jpg, .webp, etc.)

## Setting Custom Vehicle Images

### Method 1: Local Folder (Recommended for Custom Vehicles)

1. Get your vehicle image (PNG, JPG, or WEBP)
2. Rename it to match the spawn code exactly (e.g., `lamborghini.png`)
3. Place it in `html/vehicles/` folder
4. Restart resource or refresh UI

**Example:**
```
html/vehicles/
├── lamborghini.png      (for spawn code: lamborghini)
├── bmwm5.jpg           (for spawn code: bmwm5)
├── ferrarif40.webp     (for spawn code: ferrarif40)
```

### Method 2: Direct Database Update
```sql
UPDATE owned_vehicles 
SET vehicle_image = 'https://your-cdn.com/custom-car.png' 
WHERE plate = 'ABC123';
```

### Method 3: When Adding Vehicle
```sql
INSERT INTO owned_vehicles (owner, plate, vehicle, vehicle_image) 
VALUES ('char1:xxxxx', 'ABC123', '{"model":123456}', 'https://your-cdn.com/custom-car.png');
```

## Image Requirements

- **Format**: PNG, JPG, WEBP recommended
- **Size**: Recommended 400x250px or similar aspect ratio
- **Hosting**: Must be publicly accessible URL
- **HTTPS**: Recommended for security

## Examples

### Default Vehicle (No custom image needed)
```sql
-- Adder will automatically use: https://docs.fivem.net/vehicles/adder.webp
plate: 'ABC123', vehicle_image: NULL
```

### Custom Vehicle
```sql
-- Custom vehicle with image URL
plate: 'XYZ789', vehicle_image: 'https://i.imgur.com/example.png'
```

## Fallback
If an image fails to load, the system will attempt to use the default FiveM image. If that also fails, a placeholder will be shown.

## Tips

1. **Use a CDN**: Host images on a reliable CDN for fast loading
2. **Optimize Images**: Compress images to reduce load times
3. **Consistent Sizing**: Use similar dimensions for all custom images
4. **Test URLs**: Ensure image URLs are accessible before adding to database

## Troubleshooting

**Image not showing:**
- Check if URL is publicly accessible
- Verify URL returns an image (not HTML page)
- Check browser console for CORS errors
- Ensure HTTPS if your server uses HTTPS

**Wrong image showing:**
- Verify the vehicle model name matches FiveM's naming
- Check if custom image URL is set correctly in database
- Clear browser cache
