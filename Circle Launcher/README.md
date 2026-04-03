# Circle Launcher

A radial app launcher for macOS that appears at your cursor position with a global hotkey.

## Features

- 🎯 **Cursor-centered menu** - Appears exactly where your mouse is
- ⌨️ **Global hotkey** - Press ⌥Space (Option+Space) from anywhere
- 🎨 **Beautiful radial design** - Apps arranged in a circle with smooth animations
- 🔧 **Fully configurable** - Add, remove, and reorder apps
- 👻 **Background operation** - No Dock icon, runs silently in the menu bar
- 🚀 **Fast launching** - Click any app to launch instantly
- 💨 **Auto-dismiss** - Move mouse away or press Escape to close

## Installation & Setup

### 1. Build Configuration

1. Open the project in Xcode 15 or later
2. Select your target (Circle Launcher)
3. Go to **Signing & Capabilities**
   - Enable **App Sandbox** (required for distribution)
   - Add capability: **com.apple.security.app-sandbox** = YES
   - Add capability: **com.apple.security.files.user-selected.read-only** = YES (for app selection)
   - Go to **Info** tab and ensure **Info.plist** file is set correctly

### 2. Info.plist Configuration

The `Info.plist` file is already configured with:
```xml
<key>LSUIElement</key>
<true/>
```

This makes the app run without a Dock icon. You can verify this in your target's Info tab.

### 3. Enable Accessibility Permissions

For global hotkey monitoring to work, you need to grant Accessibility permissions:

1. Build and run the app
2. Open **System Settings** → **Privacy & Security** → **Accessibility**
3. Find **Circle Launcher** in the list and enable it
4. If it doesn't appear, click the **+** button and add it manually

### 4. First Run

On first launch, the app will:
- Create a menu bar icon (grid icon)
- Set up default apps (Safari, Mail, Messages, Calendar, Notes, Finder)
- Register the ⌥Space hotkey listener

## Usage

### Opening the Launcher

Press **⌥Space** (Option+Space) from anywhere to show the radial menu at your cursor.

### Using the Menu

- **Hover** over any app icon to highlight it
- **Click** to launch the app
- **Move mouse away** from the wheel to dismiss
- **Press Escape** to close immediately

### Configuring Apps

1. Click the menu bar icon (grid icon)
2. Select **Settings...**
3. In the settings window:
   - Click **+ Add App** to add new applications
   - Select apps from `/Applications` folder
   - Drag to reorder
   - Right-click for more options (Move Up/Down, Remove)
   - Click **Remove** to delete selected app

## Project Structure

```
Circle Launcher/
├── Circle_LauncherApp.swift    # Main app entry point
├── AppDelegate.swift            # App lifecycle, hotkey, status bar
├── AppItem.swift                # Data model for app entries
├── RadialMenuPanel.swift        # NSPanel for the floating menu
├── RadialMenuView.swift         # SwiftUI radial menu UI
├── SettingsView.swift           # App configuration UI
├── Info.plist                   # App configuration (LSUIElement)
└── README.md                    # This file
```

## Technical Details

### Global Hotkey Detection

Uses `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)` to detect ⌥Space:
- Works even when app is not active
- Keycode 49 = Space
- `.option` modifier flag

### Window Management

- **RadialMenuPanel** is an `NSPanel` with:
  - `.nonactivatingPanel` style (doesn't steal focus)
  - `.popUpMenu` level (appears above other windows)
  - `.canJoinAllSpaces` (works in all Mission Control spaces)

### Data Persistence

- Uses **SwiftData** for storing app configurations
- **AppItem** model stores: name, bundle ID, position
- Automatically persists changes

### Cursor Position

Uses `NSEvent.mouseLocation` to get screen coordinates and centers the 400×400 panel at cursor.

### Auto-dismiss Logic

Timer-based tracking checks mouse position every 0.1s:
- Calculates distance from panel center
- Closes if distance > (panel width / 2) + 50px

## Requirements

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## Customization

### Change Hotkey

In `AppDelegate.swift`, modify the hotkey check:

```swift
// Current: Option + Space (keyCode 49)
if event.modifierFlags.contains(.option) && event.keyCode == 49 {

// Example: Command + Space
if event.modifierFlags.contains(.command) && event.keyCode == 49 {
```

Common key codes:
- Space: 49
- Return: 36
- Escape: 53
- Tab: 48

### Adjust Menu Size

In `RadialMenuView.swift`:

```swift
private let radius: CGFloat = 120           // Distance from center
private let centerCircleRadius: CGFloat = 40 // Center circle size
private let itemSize: CGFloat = 60          // App icon size
```

### Change Number of Apps

The radial layout automatically adjusts to the number of apps. Works best with 6-8 apps.

### Modify Auto-dismiss Distance

In `RadialMenuPanel.swift`:

```swift
if distance > panelFrame.width / 2 + 50 {  // Change 50 to adjust threshold
    self.close()
}
```

## Troubleshooting

### Hotkey Not Working

1. Check Accessibility permissions in System Settings
2. Make sure no other app is using ⌥Space
3. Try restarting the app

### Apps Not Launching

1. Verify bundle identifier is correct in Settings
2. Check that the app is installed
3. Some system apps may have different bundle IDs

### Menu Not Appearing

1. Check that LSUIElement is set to YES in Info.plist
2. Verify the app is running (check menu bar)
3. Look for errors in Console.app

### Menu Bar Icon Not Showing

If you want the menu bar icon hidden by default, comment out `setupStatusBar()` in `AppDelegate.swift`. To access settings, you'll need to add an alternative way to open the settings window.

## License

MIT License - Feel free to modify and distribute.

## Credits

Created by André Lobach, 2026
