//
//  CustomizationExamples.swift
//  Circle Launcher
//
//  Common customization snippets - NOT included in build
//  Copy and paste these into the appropriate files as needed
//

import Foundation
import AppKit

// MARK: - Hotkey Customization Examples

/*
 Replace the hotkey check in AppDelegate.swift → registerGlobalHotkey()
 */

// Example 1: Command + Space (⌘Space)
/*
if event.modifierFlags.contains(.command) && event.keyCode == 49 {
    self?.toggleRadialMenu()
}
*/

// Example 2: Control + Option + L (⌃⌥L)
/*
if event.modifierFlags.contains([.control, .option]) && event.keyCode == 37 { // 37 = L
    self?.toggleRadialMenu()
}
*/

// Example 3: Function + F1 (Fn+F1)
/*
if event.modifierFlags.contains(.function) && event.keyCode == 122 { // 122 = F1
    self?.toggleRadialMenu()
}
*/

// Common key codes:
// Space: 49, Return: 36, Escape: 53, Tab: 48
// A: 0, B: 11, C: 8, D: 2, E: 14, F: 3, G: 5, H: 4
// I: 34, J: 38, K: 40, L: 37, M: 46, N: 45, O: 31, P: 35
// Q: 12, R: 15, S: 1, T: 17, U: 32, V: 9, W: 13, X: 7, Y: 16, Z: 6
// F1-F12: 122-111

// MARK: - Layout Customization Examples

/*
 Modify these constants in RadialMenuView.swift
 */

// Example 1: Larger menu
/*
private let radius: CGFloat = 150           // More spread out
private let centerCircleRadius: CGFloat = 50
private let itemSize: CGFloat = 70
// Also change .frame(width: 500, height: 500) at bottom
*/

// Example 2: Compact menu
/*
private let radius: CGFloat = 80            // Tighter spacing
private let centerCircleRadius: CGFloat = 30
private let itemSize: CGFloat = 50
// Also change .frame(width: 300, height: 300) at bottom
*/

// Example 3: Different starting position
/*
private func angleForIndex(_ index: Int, total: Int) -> Double {
    let angleStep = 360.0 / Double(total)
    return Double(index) * angleStep - 0   // Start at right (was -90 for top)
}
*/

// MARK: - Visual Customization Examples

/*
 Add these to RadialMenuView.swift
 */

// Example 1: Different blur material
/*
VisualEffectView(material: .menu, blendingMode: .behindWindow)
// Options: .menu, .popover, .sidebar, .headerView, .sheet, .windowBackground, .hudWindow
*/

// Example 2: Colored background
/*
Circle()
    .fill(Color.blue.opacity(0.3))
    .background(.ultraThinMaterial)
    .frame(width: radius * 2 + 100, height: radius * 2 + 100)
*/

// Example 3: Custom accent color
/*
// Add to app initialization in AppDelegate
NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
// Or set accent color in project settings
*/

// MARK: - Auto-Dismiss Customization

/*
 Modify in RadialMenuPanel.swift → checkMousePosition()
 */

// Example 1: Faster dismiss (smaller threshold)
/*
if distance > panelFrame.width / 2 + 20 {  // Closes sooner
    self.close()
}
*/

// Example 2: Delayed dismiss (larger threshold)
/*
if distance > panelFrame.width / 2 + 100 {  // More forgiving
    self.close()
}
*/

// Example 3: Never auto-dismiss (manual close only)
/*
private func checkMousePosition() {
    // Comment out or remove the entire method
    // User must press Escape or click outside
}
*/

// Example 4: Time-based dismiss (close after 5 seconds)
/*
private var dismissTimer: Timer?

override func makeKeyAndOrderFront(_ sender: Any?) {
    super.makeKeyAndOrderFront(sender)
    
    dismissTimer?.invalidate()
    dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
        self?.close()
    }
}
*/

// MARK: - Default Apps Customization

/*
 Modify in AppDelegate.swift → addDefaultAppsIfNeeded()
 */

// Example: Developer apps
/*
let defaultApps = [
    AppItem(name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", position: 0),
    AppItem(name: "Terminal", bundleIdentifier: "com.apple.Terminal", position: 1),
    AppItem(name: "Safari", bundleIdentifier: "com.apple.Safari", position: 2),
    AppItem(name: "VS Code", bundleIdentifier: "com.microsoft.VSCode", position: 3),
    AppItem(name: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap", position: 4),
    AppItem(name: "GitHub Desktop", bundleIdentifier: "com.github.GitHubClient", position: 5),
]
*/

// Example: Productivity apps
/*
let defaultApps = [
    AppItem(name: "Calendar", bundleIdentifier: "com.apple.iCal", position: 0),
    AppItem(name: "Reminders", bundleIdentifier: "com.apple.reminders", position: 1),
    AppItem(name: "Notes", bundleIdentifier: "com.apple.Notes", position: 2),
    AppItem(name: "Mail", bundleIdentifier: "com.apple.mail", position: 3),
    AppItem(name: "Safari", bundleIdentifier: "com.apple.Safari", position: 4),
    AppItem(name: "Music", bundleIdentifier: "com.apple.Music", position: 5),
]
*/

// MARK: - Status Bar Icon Customization

/*
 Modify in AppDelegate.swift → setupStatusBar()
 */

// Example 1: Different icon
/*
button.image = NSImage(systemSymbolName: "app.dashed", accessibilityDescription: "Circle Launcher")
// Other options: "circle.circle", "app.badge", "star.circle", "command.circle"
*/

// Example 2: Hide status bar icon (access via Spotlight or hotkey only)
/*
private func setupStatusBar() {
    // Comment out or don't call this method
    // Note: You won't be able to access Settings UI without alternative method
}
*/

// Example 3: Add more menu items
/*
menu.addItem(NSMenuItem(title: "About Circle Launcher", action: #selector(showAbout), keyEquivalent: ""))
menu.addItem(NSMenuItem.separator())
menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
menu.addItem(NSMenuItem(title: "Refresh Apps", action: #selector(refreshApps), keyEquivalent: "r"))
menu.addItem(NSMenuItem.separator())
menu.addItem(NSMenuItem(title: "Quit Circle Launcher", action: #selector(quitApp), keyEquivalent: "q"))
*/

// MARK: - Animation Customization

/*
 Modify in RadialMenuView.swift → AppItemView
 */

// Example 1: Slower, bouncier animation
/*
.animation(.spring(response: 0.6, dampingFraction: 0.5), value: isHovered)
*/

// Example 2: Quick, snappy animation
/*
.animation(.spring(response: 0.2, dampingFraction: 0.9), value: isHovered)
*/

// Example 3: Linear fade
/*
.animation(.linear(duration: 0.2), value: isHovered)
*/

// Example 4: Bigger scale effect
/*
.scaleEffect(isHovered ? 1.3 : 1.0)  // More dramatic
*/

// MARK: - Add Sound Effects

/*
 Add to AppItemView when launching
 */

/*
import AVFoundation

func playLaunchSound() {
    NSSound(named: "Blow")?.play()  // System sound
}

// Then in .onTapGesture:
.onTapGesture {
    playLaunchSound()
    app.launch()
    onClose()
}
*/

// MARK: - Panel Window Level Customization

/*
 Modify in RadialMenuPanel.swift → init
 */

// Example: Even higher priority
/*
self.level = .modalPanel  // Above popups
// or
self.level = .statusBar   // Same level as menu bar
*/

// MARK: - Multiple Radial Menus

/*
 Add support for different radial menus (e.g., different hotkeys for different app sets)
 */

/*
// In AppDelegate:
var workRadialMenu: RadialMenuPanel?
var personalRadialMenu: RadialMenuPanel?

// Register different hotkeys:
if event.modifierFlags.contains(.option) && event.keyCode == 49 {
    showWorkRadialMenu()
} else if event.modifierFlags.contains(.control) && event.keyCode == 49 {
    showPersonalRadialMenu()
}

// Each panel loads different AppItem filter:
// @Query(filter: #Predicate { $0.category == "work" })
*/

// MARK: - Launch with Animation

/*
 Modify AppItem.swift → launch()
 */

/*
func launch(completion: @escaping () -> Void) {
    NSWorkspace.shared.launchApplication(
        withBundleIdentifier: bundleIdentifier,
        options: [.async],
        additionalEventParamDescriptor: nil,
        launchIdentifier: nil
    )
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        completion()
    }
}
*/

// MARK: - Keyboard Navigation

/*
 Add to RadialMenuView for keyboard shortcuts
 */

/*
@State private var selectedIndex: Int = 0

// Add to body:
.onKeyPress(.upArrow) {
    selectedIndex = (selectedIndex - 1 + apps.count) % apps.count
    return .handled
}
.onKeyPress(.downArrow) {
    selectedIndex = (selectedIndex + 1) % apps.count
    return .handled
}
.onKeyPress(.return) {
    apps[selectedIndex].launch()
    onClose()
    return .handled
}
*/

// MARK: - Recent Apps Tracking

/*
 Add last used timestamp to AppItem
 */

/*
// In AppItem.swift:
var lastUsed: Date = Date.distantPast

// Sort query by recent:
@Query(sort: \AppItem.lastUsed, order: .reverse) private var apps: [AppItem]

// Update on launch:
func launch() {
    lastUsed = Date()
    // ... existing launch code
}
*/

// MARK: - App Usage Statistics

/*
 Track how many times each app is launched
 */

/*
// In AppItem.swift:
var launchCount: Int = 0

// Increment on launch:
func launch() {
    launchCount += 1
    // ... existing launch code
}

// Show in UI:
Text("\(app.launchCount) launches")
*/
