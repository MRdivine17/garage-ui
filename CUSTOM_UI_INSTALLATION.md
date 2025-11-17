# Custom Garage UI Installation Guide

This custom UI replaces the ox_lib context menu with a modern, sleek garage interface.

## Installation Steps

1. **The UI is already integrated!**
   - All ox_lib menu calls have been replaced with the custom UI
   - UI functions are integrated into the framework files (QB-Core & ESX)
   - No manual file replacement needed

2. **Just restart the resource**
   - Restart your server or use `/restart lunar_garage`
   - The custom UI will automatically load

## Features

- **Modern UI Design**: Clean, dark-themed interface matching the reference images
- **Search Functionality**: Search vehicles by plate or name
- **Vehicle Stats Display**: Shows fuel, engine health, and body health with progress bars
- **Expandable Vehicle Cards**: Click on any vehicle to see details and actions
- **Action Buttons**: 
  - Take Out: Spawn your vehicle (only available if in garage)
  - Transfer: Transfer vehicle to another player (placeholder)
  - Set Name: Set a custom name for your vehicle (placeholder)

## Customization

### Colors
Edit `html/style.css` to change colors:
- Background colors: Search for `rgba()` values
- Button colors: Look for `.btn-takeout`, `.btn-transfer`, `.btn-setname`
- Progress bar colors: `.stat-fill.fuel`, `.stat-fill.engine`, `.stat-fill.body`

### Layout
Edit `html/style.css`:
- Width: Change `.garage-wrapper { width: 850px; }`
- Height: Change `.vehicles-list { max-height: 70vh; }`

### Functionality
Edit `html/script.js` to modify:
- Search behavior
- Action button handlers
- Vehicle card rendering

## Notes

- The UI automatically closes when pressing ESC
- Transfer and Set Name features are placeholders - implement them as needed
- The UI is fully responsive and works with different screen sizes
- All original functionality (spawning, saving vehicles) is preserved

## Troubleshooting

If the UI doesn't show:
1. Check F8 console for errors
2. Ensure all files are in the correct locations
3. Verify fxmanifest.lua includes the UI files
4. Restart the resource completely

If vehicles don't spawn:
1. Check that the original callbacks are working
2. Verify database connection
3. Check server console for errors
