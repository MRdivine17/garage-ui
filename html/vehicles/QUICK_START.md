# Quick Start - Custom Vehicle Images

## Simple 3-Step Process

### Step 1: Get Your Image
- Find or create an image of your custom vehicle
- Recommended size: 400x250px
- Format: PNG, JPG, or WEBP

### Step 2: Rename the File
Rename your image file to match the **exact spawn code** of the vehicle.

**Examples:**
- Spawn code: `lamborghini` → Filename: `lamborghini.png`
- Spawn code: `bmwm5` → Filename: `bmwm5.jpg`
- Spawn code: `ferrarif40` → Filename: `ferrarif40.webp`

**Important:** Use lowercase and match the spawn code exactly!

### Step 3: Place in This Folder
Copy your renamed image file into this folder:
```
lunar_garage/html/vehicles/
```

### That's It!
The garage UI will automatically display your custom vehicle image!

## Example Structure
```
html/vehicles/
├── QUICK_START.md (this file)
├── README.md
├── lamborghini.png     ← Your custom vehicle
├── bmwm5.jpg          ← Your custom vehicle
├── ferrarif40.webp    ← Your custom vehicle
└── customcar.png      ← Your custom vehicle
```

## Testing
1. Restart the `lunar_garage` resource
2. Open the garage in-game
3. Your custom vehicle should show the image

## Troubleshooting

**Image not showing?**
- Check filename matches spawn code exactly (case-insensitive)
- Verify file format is PNG, JPG, JPEG, or WEBP
- Make sure file is in `html/vehicles/` folder
- Try restarting the resource

**Still not working?**
- Check F8 console for errors
- Verify the spawn code is correct
- Try using a different image format
- Check file isn't corrupted

## Priority System
If you have multiple image sources, the system uses this priority:

1. **Database URL** (if set in `vehicle_image` column)
2. **Local file** (this folder)
3. **FiveM CDN** (for default vehicles)
4. **Fallback icon** (if nothing works)

## Pro Tips
- Keep images under 500KB for fast loading
- Use consistent aspect ratio (16:10 or 16:9)
- Compress images before adding
- Use descriptive spawn codes for easy management
