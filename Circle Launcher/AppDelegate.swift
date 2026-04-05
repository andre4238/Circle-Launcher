//
//  AppDelegate.swift
//  Circle Launcher
//
//  Created by André Lobach on 03.04.26.
//

import Cocoa
import SwiftUI
import SwiftData
import Carbon
import AppKit

// MARK: - Temporary Music Control View (inline until MusicControlView.swift is added to target)

fileprivate struct TempMusicControlView: View {
    @AppStorage("circleRadius") private var circleRadius: Double = 80.0
    @AppStorage("iconSize") private var iconSize: Double = 32.0
    
    @State private var hoveredControl: MusicControl? = nil
    
    var onClose: () -> Void
    
    private var centerCircleRadius: CGFloat {
        circleRadius * 0.375
    }
    
    private var itemSize: CGFloat {
        circleRadius * 0.625
    }
    
    private var frameSize: CGFloat {
        circleRadius * 3.75
    }
    
    private var backgroundSize: CGFloat {
        circleRadius * 2 + 80
    }
    
    enum MusicControl: String, CaseIterable {
        case playPause = "Play/Pause"
        case next = "Next"
        case previous = "Previous"
        case shuffle = "Shuffle"
        case repeat_ = "Repeat"
        
        var icon: String {
            switch self {
            case .playPause: return "play.fill"
            case .next: return "forward.fill"
            case .previous: return "backward.fill"
            case .shuffle: return "shuffle"
            case .repeat_: return "repeat"
            }
        }
        
        var position: Int {
            switch self {
            case .playPause: return 0
            case .next: return 1
            case .repeat_: return 2
            case .shuffle: return 4
            case .previous: return 5
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background blur ring (Donut-Form wie in RadialMenuView)
                VisualEffectView(material: NSVisualEffectView.Material.hudWindow, blendingMode: NSVisualEffectView.BlendingMode.behindWindow)
                    .frame(width: backgroundSize, height: backgroundSize)
                    .mask(
                        // Donut-Maske: Großer Kreis minus kleiner Kreis in der Mitte
                        ZStack {
                            Circle()
                                .fill(Color.white)
                            
                            Circle()
                                .fill(Color.black)
                                .frame(width: centerCircleRadius * 2, height: centerCircleRadius * 2)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                    )
                
                // CENTER CIRCLE ist ein LOCH - Man sieht durch (wie in RadialMenuView)
                // Aber wir zeigen ein Music Icon in der Mitte
                ZStack {
                    VStack(spacing: 4) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Music Controls")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.7), radius: 2)
                    }
                }
                
                // Music controls (wie AppItemView in RadialMenuView)
                ForEach(MusicControl.allCases, id: \.self) { control in
                    let angle = angleForPosition(control.position, total: 6)
                    let position = positionForAngle(angle, center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                    
                    MusicControlButton(
                        control: control,
                        isHovered: hoveredControl == control,
                        iconSize: iconSize
                    )
                    .frame(width: itemSize, height: itemSize)
                    .position(position)
                    .contentShape(Circle())
                    .onHover { hovering in
                        hoveredControl = hovering ? control : nil
                    }
                    .onTapGesture {
                        handleControlTap(control)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(width: frameSize, height: frameSize)
    }
    
    private func handleControlTap(_ control: MusicControl) {
        print("🎵 Music control tapped: \(control.rawValue)")
        // Hier würde die MediaPlayerManager-Logik kommen
    }
    
    private func angleForPosition(_ position: Int, total: Int) -> Double {
        let angleStep = 360.0 / Double(total)
        return Double(position) * angleStep - 90
    }
    
    private func positionForAngle(_ angle: Double, center: CGPoint) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: center.x + circleRadius * cos(radians),
            y: center.y + circleRadius * sin(radians)
        )
    }
}

// Music Control Button (ähnlich wie AppItemView)
fileprivate struct MusicControlButton: View {
    let control: TempMusicControlView.MusicControl
    let isHovered: Bool
    let iconSize: Double
    
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: control.icon)
                .font(.system(size: iconSize))
                .foregroundColor(.white)
                .scaleEffect(isHovered ? 1.2 : 1.0)
                .shadow(color: isHovered ? .accentColor.opacity(0.6) : .black.opacity(0.3), radius: isHovered ? 12 : 4)
                .shadow(color: .black.opacity(0.5), radius: 2)
            
            Text(control.rawValue)
                .font(.caption2)
                .fontWeight(isHovered ? .bold : .semibold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 2)
                .lineLimit(1)
                .frame(maxWidth: 70)
        }
        .background(Color.clear)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

// Visual effect view for macOS blur (für TempMusicControlView)
fileprivate struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - HotkeyManager
class HotkeyManager {
    
    /// Singleton-Instanz
    static let shared = HotkeyManager()
    
    private init() {}
    
    // MARK: - Hotkey Configuration
    
    /// Verfügbare Modifier-Kombinationen
    enum ModifierCombination: String, CaseIterable, Identifiable {
        case optionCommand = "⌥⌘ (Option + Command)"
        case controlOption = "⌃⌥ (Control + Option)"
        case controlCommand = "⌃⌘ (Control + Command)"
        case shiftCommand = "⇧⌘ (Shift + Command)"
        case shiftOption = "⇧⌥ (Shift + Option)"
        case controlShift = "⌃⇧ (Control + Shift)"
        
        var id: String { rawValue }
        
        /// NSEvent.ModifierFlags für diese Kombination
        var modifierFlags: NSEvent.ModifierFlags {
            switch self {
            case .optionCommand:
                return [.option, .command]
            case .controlOption:
                return [.control, .option]
            case .controlCommand:
                return [.control, .command]
            case .shiftCommand:
                return [.shift, .command]
            case .shiftOption:
                return [.shift, .option]
            case .controlShift:
                return [.control, .shift]
            }
        }
        
        /// Display-Name (kurz)
        var displayName: String {
            switch self {
            case .optionCommand:
                return "⌥⌘"
            case .controlOption:
                return "⌃⌥"
            case .controlCommand:
                return "⌃⌘"
            case .shiftCommand:
                return "⇧⌘"
            case .shiftOption:
                return "⇧⌥"
            case .controlShift:
                return "⌃⇧"
            }
        }
        
        /// Beschreibung für UI
        var description: String {
            switch self {
            case .optionCommand:
                return "Option + Command (Standard)"
            case .controlOption:
                return "Control + Option"
            case .controlCommand:
                return "Control + Command"
            case .shiftCommand:
                return "Shift + Command"
            case .shiftOption:
                return "Shift + Option"
            case .controlShift:
                return "Control + Shift"
            }
        }
    }
    
    /// Aktuell konfigurierte Modifier-Kombination
    var currentModifiers: ModifierCombination {
        get {
            let savedRawValue = UserDefaults.standard.string(forKey: "hotkeyModifiers") ?? ModifierCombination.optionCommand.rawValue
            return ModifierCombination(rawValue: savedRawValue) ?? .optionCommand
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "hotkeyModifiers")
            print("⌨️ Hotkey geändert zu: \(newValue.displayName)")
        }
    }
    
    /// Prüft, ob die aktuell gedrückten Modifier dem konfigurierten Hotkey entsprechen
    func matchesCurrentHotkey(_ modifiers: NSEvent.ModifierFlags) -> Bool {
        let currentFlags = currentModifiers.modifierFlags
        return modifiers.contains(currentFlags)
    }
    
    /// Gibt die aktuellen Modifier-Flags zurück
    var currentModifierFlags: NSEvent.ModifierFlags {
        return currentModifiers.modifierFlags
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var radialMenuPanel: RadialMenuPanel?
    var settingsWindow: NSWindow?
    var eventMonitor: Any?
    var modelContainer: ModelContainer!
    var isLauncherOpen = false
    var launcherOpenPosition: NSPoint?
    
    // Mode tracking for Apps vs Music
    enum LauncherMode {
        case apps
        case music
    }
    var currentMode: LauncherMode = .apps
    
    // Store only primitive values, not SwiftData objects
    private var hoveredAppBundleID: String?
    private var hoveredAppName: String?
    
    // Flag to track if X key was pressed (for Option+Command+X)
    private var xKeyPressed = false
    
    // Timer to delay opening the app launcher
    private var launcherOpenTimer: Timer?
    
    // DEBUG: Prevents automatic closing when releasing keys
    var debugKeepOpen = false
    
    deinit {
        // Cleanup
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup model container
        setupModelContainer()
        
        // Setup status bar icon (hidden by default, but can be shown via right-click)
        setupStatusBar()
        
        // Enable launch at login on first start
        LaunchAtLoginManager.shared.enableOnFirstLaunch()
        
        // Register global hotkey FIRST (this triggers the permission prompt)
        registerGlobalHotkey()
        
        // Check accessibility permissions AFTER attempting to register
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AccessibilityManager.checkAndRequestPermissions()
        }
        
        // Create the radial menu panel (hidden by default)
        setupRadialMenuPanel()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup bei Beendigung
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        // Panel schließen
        radialMenuPanel?.close()
        radialMenuPanel = nil
        
        // Settings Window schließen
        settingsWindow?.delegate = nil
        settingsWindow?.close()
        settingsWindow = nil
    }
    
    private func setupModelContainer() {
        let schema = Schema([
            AppItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Add default apps if none exist
            addDefaultAppsIfNeeded()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func addDefaultAppsIfNeeded() {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<AppItem>()
        
        do {
            let existingApps = try context.fetch(descriptor)
            if existingApps.isEmpty {
                // Add default apps
                let defaultApps = [
                    AppItem(name: "Safari", bundleIdentifier: "com.apple.Safari", position: 0),
                    AppItem(name: "Mail", bundleIdentifier: "com.apple.mail", position: 1),
                    AppItem(name: "Messages", bundleIdentifier: "com.apple.MobileSMS", position: 2),
                    AppItem(name: "Calendar", bundleIdentifier: "com.apple.iCal", position: 3),
                    AppItem(name: "Notes", bundleIdentifier: "com.apple.Notes", position: 4),
                    AppItem(name: "Finder", bundleIdentifier: "com.apple.finder", position: 5),
                ]
                
                for app in defaultApps {
                    context.insert(app)
                }
                
                try context.save()
            }
        } catch {
            print("Error adding default apps: \(error)")
        }
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "circle.grid.2x2", accessibilityDescription: "Circle Launcher")
        }
        
        let menu = NSMenu()
        
        // DEBUG: Toggle für "Circle offen halten" Modus
        let debugItem = NSMenuItem(title: "🐛 Debug: Circle offen halten", action: #selector(toggleDebugKeepOpen), keyEquivalent: "")
        menu.addItem(debugItem)
        menu.addItem(NSMenuItem.separator())
        
        // Debug menu item to test without hotkey
        menu.addItem(NSMenuItem(title: "Launcher anzeigen (Test)", action: #selector(toggleRadialMenu), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: "🎵 Music Controls anzeigen (Test)", action: #selector(showMusicControls), keyEquivalent: "m"))
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        
        // Add permission check menu item
        let permissionItem = NSMenuItem(title: "Berechtigungen prüfen", action: #selector(checkPermissions), keyEquivalent: "")
        menu.addItem(permissionItem)
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Quit Circle Launcher", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func setupRadialMenuPanel() {
        // Panel-Größe aus UserDefaults laden
        let circleRadius = UserDefaults.standard.double(forKey: "circleRadius")
        let radius = circleRadius > 0 ? circleRadius : 80.0  // Fallback auf 80
        let panelSize = radius * 3.75  // Gleiche Berechnung wie in RadialMenuView
        
        let panel = RadialMenuPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelSize, height: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.modelContainer = modelContainer
        // NICHT als Delegate setzen - RadialMenuPanel ist ein NSPanel, kein NSWindow
        panel.onEscapeClose = { [weak self] in
            self?.forceCloseRadialMenu()
        }
        
        radialMenuPanel = panel
    }
    
    private func registerGlobalHotkey() {
        // WICHTIG: Zuerst die Berechtigung mit Prompt anfordern
        // Das sorgt dafür, dass die App in den Systemeinstellungen erscheint
        AccessibilityManager.requestAccessibilityPermissions()
        
        // Monitor für Key Down Events (für die X-Taste) - HÖCHSTE PRIORITÄT!
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Debug: Zeige alle Key-Presses mit RAW Modifiers
            let modifiers = event.modifierFlags
            print("🔍 Global KeyDown: '\(event.charactersIgnoringModifiers ?? "nil")' - Raw: \(modifiers.rawValue)")
            
            // Prüfe ob X gedrückt wurde
            if let chars = event.charactersIgnoringModifiers?.lowercased(), chars == "x" {
                // Jetzt prüfen wir aktuell gedrückte Modifier mit NSEvent.modifierFlags
                let currentModifiers = NSEvent.modifierFlags
                print("🔍 Current system modifiers: \(currentModifiers.rawValue)")
                
                if currentModifiers.contains([.option, .command]) {
                    print("🎵 Option+Command+X erkannt - öffne Music Controls")
                    self?.xKeyPressed = true
                    
                    // Cancel any pending launcher timer
                    self?.launcherOpenTimer?.invalidate()
                    self?.launcherOpenTimer = nil
                    
                    // DEBUG: Zeige aktuellen Status
                    print("   ℹ️ isLauncherOpen: \(self?.isLauncherOpen ?? false)")
                    print("   ℹ️ currentMode: \(self?.currentMode == .apps ? "apps" : "music")")
                    
                    // Wenn der Launcher bereits offen ist, schließe ihn zuerst
                    if self?.isLauncherOpen == true {
                        print("   ⚠️ Launcher ist bereits offen - schließe zuerst")
                        self?.forceCloseRadialMenu()
                    }
                    
                    // Jetzt öffnen wir die Music Controls
                    self?.currentMode = .music
                    self?.showRadialMenuAtCursor()
                }
            }
        }
        
        // Monitor for Flags Changed (Option + Command für Apps)
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            // Wenn Option UND Command gedrückt sind (aber X wurde nicht gedrückt)
            if event.modifierFlags.contains([.option, .command]) && self?.xKeyPressed == false {
                // Invalidate any existing timer
                self?.launcherOpenTimer?.invalidate()
                
                // Start a short delay timer - gibt Zeit für X-Taste
                self?.launcherOpenTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
                    // Nur öffnen wenn noch nicht offen UND X nicht gedrückt wurde
                    if self?.isLauncherOpen == false && self?.xKeyPressed == false {
                        self?.currentMode = .apps
                        self?.showRadialMenuAtCursor()
                    }
                }
            } else {
                // Cancel timer wenn Modifier losgelassen werden
                self?.launcherOpenTimer?.invalidate()
                self?.launcherOpenTimer = nil
                
                // Reset X flag wenn Modifier losgelassen werden
                if !event.modifierFlags.contains([.option, .command]) {
                    self?.xKeyPressed = false
                }
                
                // DEBUG: Nur schließen wenn debugKeepOpen NICHT aktiv ist
                if self?.isLauncherOpen == true && self?.debugKeepOpen == false {
                    self?.closeRadialMenu()
                }
            }
        }
        
        // Local monitor für Key Down Events (für die X-Taste)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Debug: Zeige alle Key-Presses
            let modifiers = event.modifierFlags
            print("🔍 Local KeyDown: '\(event.charactersIgnoringModifiers ?? "nil")' - Raw: \(modifiers.rawValue)")
            
            // Prüfe ob X gedrückt wurde
            if let chars = event.charactersIgnoringModifiers?.lowercased(), chars == "x" {
                // Jetzt prüfen wir aktuell gedrückte Modifier mit NSEvent.modifierFlags
                let currentModifiers = NSEvent.modifierFlags
                print("🔍 Current system modifiers: \(currentModifiers.rawValue)")
                
                if currentModifiers.contains([.option, .command]) {
                    print("🎵 Option+Command+X erkannt - öffne Music Controls")
                    self?.xKeyPressed = true
                    
                    // Cancel any pending launcher timer
                    self?.launcherOpenTimer?.invalidate()
                    self?.launcherOpenTimer = nil
                    
                    // DEBUG: Zeige aktuellen Status
                    print("   ℹ️ isLauncherOpen: \(self?.isLauncherOpen ?? false)")
                    print("   ℹ️ currentMode: \(self?.currentMode == .apps ? "apps" : "music")")
                    
                    // Wenn der Launcher bereits offen ist, schließe ihn zuerst
                    if self?.isLauncherOpen == true {
                        print("   ⚠️ Launcher ist bereits offen - schließe zuerst")
                        self?.forceCloseRadialMenu()
                    }
                    
                    // Jetzt öffnen wir die Music Controls
                    self?.currentMode = .music
                    self?.showRadialMenuAtCursor()
                    return nil // Event konsumieren
                }
            }
            return event
        }
        
        // Local monitor for flags changed (wenn app aktiv ist)
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            // Wenn Option UND Command gedrückt sind (aber X wurde nicht gedrückt)
            if event.modifierFlags.contains([.option, .command]) && self?.xKeyPressed == false {
                // Invalidate any existing timer
                self?.launcherOpenTimer?.invalidate()
                
                // Start a short delay timer - gibt Zeit für X-Taste
                self?.launcherOpenTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
                    // Nur öffnen wenn noch nicht offen UND X nicht gedrückt wurde
                    if self?.isLauncherOpen == false && self?.xKeyPressed == false {
                        self?.currentMode = .apps
                        self?.showRadialMenuAtCursor()
                    }
                }
            } else {
                // Cancel timer wenn Modifier losgelassen werden
                self?.launcherOpenTimer?.invalidate()
                self?.launcherOpenTimer = nil
                
                // Reset X flag wenn Modifier losgelassen werden
                if !event.modifierFlags.contains([.option, .command]) {
                    self?.xKeyPressed = false
                }
                
                // DEBUG: Nur schließen wenn debugKeepOpen NICHT aktiv ist
                if self?.isLauncherOpen == true && self?.debugKeepOpen == false {
                    self?.closeRadialMenu()
                }
            }
            return event
        }
        
        // Verify permissions after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !AccessibilityManager.hasAccessibilityPermissions() {
                print("⚠️ Accessibility permissions not granted. Hotkey will not work globally.")
                print("📍 Die App sollte JETZT in Systemeinstellungen → Bedienungshilfen erscheinen!")
            } else {
                print("✅ Accessibility permissions granted. Hotkey ⌥⌘ is active, ⌥⌘X for music controls.")
            }
        }
    }
    
    private func closeRadialMenu() {
        guard let panel = radialMenuPanel else { return }
        
        if panel.isVisible {
            // Wenn eine App gehovert ist, starte sie
            if let bundleID = hoveredAppBundleID, let appName = hoveredAppName {
                // App über Bundle Identifier starten
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                    do {
                        try NSWorkspace.shared.launchApplication(at: url, options: [], configuration: [:])
                        print("🚀 App gestartet: \(appName)")
                    } catch {
                        print("❌ Fehler beim Starten von \(appName): \(error)")
                    }
                }
            }
            
            // Panel schließen auf Main Thread
            if Thread.isMainThread {
                panel.close()
            } else {
                DispatchQueue.main.async {
                    panel.close()
                }
            }
            
            isLauncherOpen = false
            launcherOpenPosition = nil
            hoveredAppBundleID = nil // Reset IDs
            hoveredAppName = nil
        }
    }
    
    private func forceCloseRadialMenu() {
        // Schließt das Menü OHNE App zu starten (z.B. bei Escape)
        guard let panel = radialMenuPanel else { return }
        
        if panel.isVisible {
            print("❌ Menü abgebrochen ohne App zu starten")
            
            // Panel schließen auf Main Thread
            if Thread.isMainThread {
                panel.close()
            } else {
                DispatchQueue.main.async {
                    panel.close()
                }
            }
            
            isLauncherOpen = false
            launcherOpenPosition = nil
            hoveredAppBundleID = nil
            hoveredAppName = nil
        }
    }
    
    @objc private func toggleRadialMenu() {
        guard let panel = radialMenuPanel else { return }
        
        if panel.isVisible {
            closeRadialMenu()
        } else {
            // Reset position für Test-Button
            launcherOpenPosition = nil
            isLauncherOpen = false
            currentMode = .apps  // Standard-Modus
            showRadialMenuAtCursor()
        }
    }
    
    @objc private func showMusicControls() {
        guard let panel = radialMenuPanel else { return }
        
        if panel.isVisible {
            closeRadialMenu()
        } else {
            // Reset position für Test-Button
            launcherOpenPosition = nil
            isLauncherOpen = false
            currentMode = .music  // Music-Modus
            showRadialMenuAtCursor()
        }
    }
    
    private func showRadialMenuAtCursor() {
        // Sicherstellen dass wir auf Main Thread sind
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showRadialMenuAtCursor()
            }
            return
        }
        
        // Prüfe ob Panel-Größe sich geändert hat
        let circleRadius = UserDefaults.standard.double(forKey: "circleRadius")
        let radius = circleRadius > 0 ? circleRadius : 80.0
        let expectedPanelSize = radius * 3.75
        
        // Wenn Panel nicht existiert ODER die Größe sich geändert hat, neu erstellen
        if radialMenuPanel == nil || abs(radialMenuPanel!.frame.width - expectedPanelSize) > 1.0 {
            print("🔄 Panel-Größe hat sich geändert - Erstelle neues Panel")
            radialMenuPanel?.close()
            radialMenuPanel = nil
            setupRadialMenuPanel()
        }
        
        guard let panel = radialMenuPanel else { return }
        
        // Nur Position beim ersten Öffnen speichern
        if launcherOpenPosition == nil {
            launcherOpenPosition = NSEvent.mouseLocation
        }
        
        // Verwende die gespeicherte Position
        guard let openPosition = launcherOpenPosition else { return }
        
        // Create appropriate view based on mode
        let hostingView: NSHostingView<AnyView>
        
        switch currentMode {
        case .apps:
            print("🚀 Opening App Launcher mode")
            let radialMenuView = RadialMenuView(
                onHoverChange: { [weak self] app in
                    self?.hoveredAppBundleID = app?.bundleIdentifier
                    self?.hoveredAppName = app?.name
                    if let app = app {
                        print("🎯 Hovering: \(app.name)")
                    }
                },
                onClose: { [weak self] in
                    self?.closeRadialMenu()
                }
            )
            .modelContainer(modelContainer)
            
            hostingView = NSHostingView(rootView: AnyView(radialMenuView))
            
        case .music:
            print("🎵 Opening Music Controls mode")
            
            let musicControlView = TempMusicControlView(
                onClose: { [weak self] in
                    self?.closeRadialMenu()
                }
            )
            
            hostingView = NSHostingView(rootView: AnyView(musicControlView))
        }
        
        hostingView.frame = panel.contentRect(forFrameRect: panel.frame)
        panel.contentView = hostingView
        
        // Center panel auf der gespeicherten Position
        let panelSize = panel.frame.size
        let origin = NSPoint(
            x: openPosition.x - panelSize.width / 2,
            y: openPosition.y - panelSize.height / 2
        )
        
        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
        panel.makeKey()
        isLauncherOpen = true
        
        // Debug output
        if currentMode == .apps {
            let debugContext = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<AppItem>()
            if let apps = try? debugContext.fetch(descriptor) {
                print("🔍 Launcher showing \(apps.count) apps")
            }
        }
    }
    
    @objc private func openSettings() {
        // Sicherstellen dass wir auf Main Thread sind
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.openSettings()
            }
            return
        }
        
        if settingsWindow == nil {
            // Neuen ModelContext für Settings erstellen
            let settingsContext = ModelContext(modelContainer)
            
            let settingsView = SettingsView()
                .modelContainer(modelContainer)
                .environment(\.modelContext, settingsContext)
                .frame(minWidth: 600, minHeight: 400)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Circle Launcher Settings"
            window.contentView = NSHostingView(rootView: settingsView)
            window.center()
            window.delegate = self  // WICHTIG: Delegate setzen
            
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func checkPermissions() {
        let hasPermission = AccessibilityManager.hasAccessibilityPermissions()
        
        let alert = NSAlert()
        if hasPermission {
            alert.messageText = "✅ Berechtigung erteilt"
            alert.informativeText = """
            Circle Launcher hat Accessibility-Berechtigung!
            
            Der globale Hotkey ⌥⌘ (Option + Command) sollte funktionieren.
            
            Falls nicht:
            1. Starten Sie die App neu
            2. Überprüfen Sie die Console.app für Fehlermeldungen
            3. Versuchen Sie den Test-Button im Menü
            """
            alert.alertStyle = .informational
        } else {
            alert.messageText = "❌ Berechtigung fehlt"
            alert.informativeText = """
            Circle Launcher hat KEINE Accessibility-Berechtigung.
            
            Der globale Hotkey ⌥⌘ (Option + Command) wird nicht funktionieren!
            
            So beheben (Schritt für Schritt):
            
            1. Öffnen Sie Systemeinstellungen
            2. Gehen Sie zu: Datenschutz & Sicherheit → Bedienungshilfen
            3. Klicken Sie auf das Schloss 🔒 unten links (Passwort eingeben)
            4. Suchen Sie "Circle Launcher" oder "Xcode" in der Liste
            5. Falls nicht da: Klicken Sie auf + und wählen Sie die Circle Launcher.app
            6. Aktivieren Sie das Kontrollkästchen ✅
            7. Starten Sie Circle Launcher neu
            
            WICHTIG: 
            - Bei Xcode-Builds steht manchmal "Xcode" statt "Circle Launcher" in der Liste
            - Die App erscheint erst nach dem ersten Start in der Liste
            - Nach dem Aktivieren MUSS die App neu gestartet werden
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Systemeinstellungen öffnen")
            alert.addButton(withTitle: "Berechtigung jetzt anfordern")
            alert.addButton(withTitle: "Abbrechen")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Systemeinstellungen öffnen
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            } else if response == .alertSecondButtonReturn {
                // Berechtigung explizit anfordern (zeigt System-Dialog)
                AccessibilityManager.requestAccessibilityPermissions()
                
                // Nach 1 Sekunde erneut prüfen
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.checkPermissions()
                }
            }
            return
        }
        
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func toggleDebugKeepOpen() {
        debugKeepOpen.toggle()
        
        let status = debugKeepOpen ? "AKTIVIERT ✅" : "DEAKTIVIERT ❌"
        print("🐛 DEBUG Modus: Circle offen halten - \(status)")
        
        // Aktualisiere Menu Item Text
        if let menuItem = statusItem?.menu?.item(withTitle: "🐛 Debug: Circle offen halten") {
            menuItem.title = debugKeepOpen ? "🐛 Debug: Circle offen halten ✅" : "🐛 Debug: Circle offen halten"
        }
        
        // Zeige Alert
        let alert = NSAlert()
        alert.messageText = "Debug-Modus: Circle offen halten"
        if debugKeepOpen {
            alert.informativeText = """
            ✅ AKTIVIERT
            
            Der Circle wird sich jetzt NICHT mehr automatisch schließen, wenn Sie die Tasten loslassen.
            
            So funktioniert es:
            • Drücken Sie ⌥⌘ um den Circle zu öffnen
            • Lassen Sie die Tasten los - Circle bleibt offen! 🎉
            • Klicken Sie auf eine App oder drücken Sie ESC zum Schließen
            
            Nützlich für:
            • Testen und Debuggen
            • Screenshots machen
            • Design-Anpassungen überprüfen
            """
            alert.alertStyle = .informational
        } else {
            alert.informativeText = """
            ❌ DEAKTIVIERT
            
            Normales Verhalten wiederhergestellt.
            
            Der Circle schließt sich wieder automatisch, wenn Sie ⌥⌘ loslassen.
            """
            alert.alertStyle = .warning
        }
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Sicher auf Main Thread ausführen
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.windowWillClose(notification)
            }
            return
        }
        
        guard let window = notification.object as? NSWindow else { 
            print("⚠️ windowWillClose: notification.object ist kein NSWindow")
            return 
        }
        
        // Prüfe ob es sich um unser Settings Window handelt
        if window === settingsWindow {
            print("🪟 Settings Window wird geschlossen")
            settingsWindow?.delegate = nil  // Delegate entfernen BEVOR wir nil setzen
            settingsWindow = nil
        }
    }
}
