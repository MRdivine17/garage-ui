# Custom Vehicle Images Folder

## How to Use

Place your custom vehicle images in this folder with the following naming convention:

### Naming Format
`{spawncode}.png` or `{spawncode}.jpg` or `{spawncode}.webp`

### Examples
- `lamborghini.png` - for spawn code "lamborghini"
- `bmwm5.jpg` - for spawn code "bmwm5"
- `ferrarif40.webp` - for spawn code "ferrarif40"

### Rules
1. **Filename must match spawn code exactly** (case-insensitive)
2. **Supported formats**: PNG, JPG, JPEG, WEBP
3. **Recommended size**: 400x250px or similar aspect ratio
4. **File size**: Keep under 500KB for fast loading

### Priority Order
The system checks images in this order:
1. Database `vehicle_image` column (if set)
2. Local folder `html/vehicles/{spawncode}.png/jpg/webp`
3. FiveM CDN `https://docs.fivem.net/vehicles/{spawncode}.webp`
4. Fallback placeholder

### Example Structure
```
html/vehicles/
├── README.md
├── lamborghini.png
├── bmwm5.jpg
├── ferrarif40.webp
└── customcar.png
```

### Tips
- Use lowercase filenames for consistency
- Optimize images before adding (compress them)
- Test in-game to ensure images load correctly
- Keep aspect ratio consistent for better UI appearance
