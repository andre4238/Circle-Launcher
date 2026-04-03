# Circle Launcher - Quick Reference

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌥Space | Open radial launcher at cursor |
| Escape | Close radial launcher |
| ⌘, | Open Settings (when menu bar icon is clicked) |
| ⌘Q | Quit Circle Launcher (from menu bar menu) |

## Mouse Interactions

### Radial Menu
- **Hover** → Highlight app
- **Click** → Launch app and close menu
- **Move away** → Auto-dismiss after ~2 seconds outside menu

### Settings Window
- **Drag items** → Reorder apps in launcher
- **Click +** → Add new app
- **Right-click** → Context menu (Move Up/Down/Remove)
- **Click trash** → Remove selected app

## Menu Bar

Click the grid icon (⚏) in menu bar:
- **Settings...** → Open configuration window
- **Quit Circle Launcher** → Exit the app

## Features at a Glance

✅ **Background Operation** - No Dock icon  
✅ **Cursor-Centered** - Appears exactly where you click  
✅ **Global Hotkey** - Works from any app  
✅ **Smart Dismissal** - Auto-closes when not needed  
✅ **Customizable** - Add any macOS app  
✅ **Fast Launch** - One click to open apps  
✅ **Persistent** - Saves your configuration  
✅ **Multi-Space** - Works across Mission Control spaces  

## Default Apps

The launcher comes pre-configured with:
1. Safari
2. Mail
3. Messages
4. Calendar
5. Notes
6. Finder

You can remove these and add your own!

## Tips & Tricks

### Finding Bundle Identifiers
If you need to manually enter a bundle ID:
1. Right-click app in Finder → Show Package Contents
2. Open `Contents/Info.plist`
3. Look for `CFBundleIdentifier`

Or use Terminal:
```bash
osascript -e 'id of app "AppName"'
```

### Custom App Icons
Apps automatically show their system icon. No configuration needed!

### Optimal Number of Apps
The radial layout works best with **6-8 apps**. More apps means smaller spacing.

### Troubleshooting
- **Hotkey not working?** → Check Accessibility permissions
- **App won't launch?** → Verify bundle ID in Settings
- **Menu not showing?** → Check menu bar for grid icon

### Performance
- Uses minimal CPU when idle
- Menu renders at 60 FPS
- No impact on system performance

## System Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac
- ~5 MB disk space

## Privacy

- ✅ All data stored locally
- ✅ No internet connection required
- ✅ No analytics or tracking
- ✅ Accessibility permission only for hotkey

## Customization

See `README.md` for instructions on:
- Changing the hotkey
- Adjusting menu size
- Modifying auto-dismiss behavior
- Customizing appearance

---

**Version 1.0** | Built with SwiftUI & SwiftData | macOS 13+
