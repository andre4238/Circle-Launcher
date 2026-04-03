# Xcode Project Setup Guide

Follow these steps to properly configure your Circle Launcher project in Xcode.

## Step 1: Add Info.plist to Your Target

1. In Xcode, select your project in the Project Navigator
2. Select the **Circle Launcher** target
3. Go to the **Build Settings** tab
4. Search for "Info.plist"
5. Find **Info.plist File** setting
6. Set it to: `Circle Launcher/Info.plist` (or just `Info.plist` depending on your folder structure)

## Step 2: Configure App Sandbox (Optional)

If you plan to distribute your app, you'll need to configure sandboxing:

1. Select your target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Sandbox**
5. Under **File Access**, enable:
   - **User Selected File** → **Read Only** (for choosing apps to launch)

## Step 3: Verify LSUIElement Setting

1. Select your target
2. Go to the **Info** tab
3. Look for **Application is agent (UIElement)** 
4. If it doesn't exist:
   - Right-click in the list and select **Add Row**
   - Choose **Application is agent (UIElement)**
   - Set value to **YES**

Or verify in **Info.plist** source code:
```xml
<key>LSUIElement</key>
<true/>
```

## Step 4: Set Minimum Deployment Target

1. Select your target
2. Go to **General** tab
3. Under **Deployment Info**, set:
   - **macOS** → **13.0** or later

## Step 5: Build and Run

1. Select **Product** → **Clean Build Folder** (⇧⌘K)
2. Select **Product** → **Build** (⌘B)
3. Fix any build errors
4. Select **Product** → **Run** (⌘R)

## Step 6: Grant Permissions

After first launch:

1. The app will show a permission dialog
2. Click **Open System Settings**
3. Or manually go to: **System Settings** → **Privacy & Security** → **Accessibility**
4. Find **Circle Launcher** and enable it
5. Restart the app

## Step 7: Test the Hotkey

1. Make sure the app is running (check menu bar for grid icon)
2. Click anywhere outside the app
3. Press **⌥Space** (Option + Space)
4. The radial menu should appear at your cursor

## Troubleshooting Build Issues

### Error: "Cannot find 'AppDelegate' in scope"

Make sure all files are added to your target:
1. Select each .swift file in Project Navigator
2. Open File Inspector (⌥⌘1)
3. Under **Target Membership**, check **Circle Launcher**

### Error: "Bundle format unrecognized, invalid, or unsuitable"

This usually means Info.plist isn't configured:
1. Verify Info.plist path in Build Settings
2. Make sure Info.plist is in your project folder
3. Clean build folder and rebuild

### Error: Swift Data model issues

If you see errors about Item.swift conflicts:
1. You can safely delete `Item.swift` (it's from the template)
2. Update `ContentView.swift` if needed (it's not used in the final app)

## File Checklist

Make sure all these files are in your project and added to target:

- ✅ Circle_LauncherApp.swift
- ✅ AppDelegate.swift
- ✅ AppItem.swift
- ✅ RadialMenuPanel.swift
- ✅ RadialMenuView.swift
- ✅ SettingsView.swift
- ✅ AccessibilityManager.swift
- ✅ Info.plist

Optional (can be removed):
- ❌ ContentView.swift (from template, not needed)
- ❌ Item.swift (from template, not needed)

## Build Settings Summary

| Setting | Value |
|---------|-------|
| Product Name | Circle Launcher |
| Bundle Identifier | com.yourname.Circle-Launcher |
| Deployment Target | macOS 13.0 |
| Info.plist File | Info.plist |
| Swift Language Version | Swift 5 |

## Next Steps

Once built successfully:
1. Test the radial menu with ⌥Space
2. Open Settings from menu bar
3. Add your own apps
4. Customize hotkey if desired
5. Enjoy your new launcher! 🚀
