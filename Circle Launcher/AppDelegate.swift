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
import Combine

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
    
    // Store only primitive values, not SwiftData objects
    private var hoveredAppBundleID: String?
    private var hoveredAppName: String?
    
    // Timer to delay opening the app launcher
    private var launcherOpenTimer: Timer?
    
    // Timer that polls the modifier keys for the global hotkey
    private var hotkeyPollTimer: Timer?
    private var isHotkeyPressed = false
    
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
        
        // Register global hotkey
        registerGlobalHotkey()
        
        // Create the radial menu panel (hidden by default)
        setupRadialMenuPanel()
        
        #if DIRECT
        // Direct (.dmg) build: the app is locked until a valid licence key has been entered.
        startLicensing()
        #endif
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup bei Beendigung
        hotkeyPollTimer?.invalidate()
        hotkeyPollTimer = nil
        
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
        
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        #if DIRECT
        menu.addItem(NSMenuItem(title: "License...", action: #selector(showLicense), keyEquivalent: ""))
        #endif
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
        // Modifier-Status per Timer abfragen. NSEvent.modifierFlags liefert den
        // systemweiten Status und benötigt KEINE Accessibility-Berechtigung
        // (im Gegensatz zu globalen Event-Monitoren).
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.checkHotkeyModifiers()
        }
        timer.tolerance = 0.01
        RunLoop.main.add(timer, forMode: .common)
        hotkeyPollTimer = timer
    }
    
    private func checkHotkeyModifiers() {
        let isPressed = HotkeyManager.shared.matchesCurrentHotkey(NSEvent.modifierFlags)
        
        // Nur auf Änderungen reagieren
        guard isPressed != isHotkeyPressed else { return }
        isHotkeyPressed = isPressed
        
        if isPressed {
            // Invalidate any existing timer
            launcherOpenTimer?.invalidate()
            
            // Start a short delay timer
            let openTimer = Timer(timeInterval: 0.15, repeats: false) { [weak self] _ in
                if self?.isLauncherOpen == false {
                    self?.showRadialMenuAtCursor()
                }
            }
            RunLoop.main.add(openTimer, forMode: .common)
            launcherOpenTimer = openTimer
        } else {
            // Cancel timer wenn Modifier losgelassen werden
            launcherOpenTimer?.invalidate()
            launcherOpenTimer = nil
            
            // DEBUG: Nur schließen wenn debugKeepOpen NICHT aktiv ist
            if isLauncherOpen && !debugKeepOpen {
                closeRadialMenu()
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
    
    private func showRadialMenuAtCursor() {
        // Sicherstellen dass wir auf Main Thread sind
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showRadialMenuAtCursor()
            }
            return
        }
        
        #if DIRECT
        // Ohne gültige Lizenz öffnet sich statt des Launchers das Lizenzfenster.
        guard requireLicense() else { return }
        #endif
        
        // Prüfe ob Panel-Größe sich geändert hat
        let circleRadius = UserDefaults.standard.double(forKey: "circleRadius")
        let radius = circleRadius > 0 ? circleRadius : 80.0
        let expectedPanelSize = radius * 3.75
        
        // Wenn Panel nicht existiert ODER die Größe sich geändert hat, neu erstellen
        let shouldRecreatePanel = radialMenuPanel == nil || 
                                  (radialMenuPanel.map { abs($0.frame.width - expectedPanelSize) > 1.0 } ?? false)
        
        if shouldRecreatePanel {
            print("🔄 Panel-Größe hat sich geändert oder Panel existiert nicht - Erstelle neues Panel")
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
        
        print("🚀 Opening App Launcher")
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
        
        let hostingView = NSHostingView(rootView: AnyView(radialMenuView))
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
        let debugContext = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<AppItem>()
        if let apps = try? debugContext.fetch(descriptor) {
            print("🔍 Launcher showing \(apps.count) apps")
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
        
        #if DIRECT
        guard requireLicense() else { return }
        #endif
        
        if settingsWindow == nil {
            let settingsView = SettingsView()
                .modelContainer(modelContainer)
                .frame(minWidth: 600, minHeight: 400)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false  // Wichtig: ARC verwaltet die Lebensdauer
            window.title = "Circle Launcher Settings"
            window.contentView = NSHostingView(rootView: settingsView)
            window.center()
            window.delegate = self
            
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window === settingsWindow {
            // Defer nil-setting so the window finishes its close sequence first
            DispatchQueue.main.async { [weak self] in
                self?.settingsWindow = nil
            }
        }
    }
}

#if DIRECT
// MARK: - Licence (direct build only)
extension AppDelegate {
    static var isRunningTests: Bool { ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil }
    
    /// Confirms the stored licence key and shows the licence window if the app is locked.
    func startLicensing() {
        guard !Self.isRunningTests else { return }
        let window = LicenseWindowController.shared
        NotificationCenter.default.addObserver(forName: Licensing.stateDidChange, object: Licensing.shared, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.licenseStateDidChange() }
        }
        Task {
            await Licensing.shared.checkStoredKey()
            window.present()   // does nothing when the app is unlocked
        }
        #if DEBUG
        autoActivateIfRequested()
        #endif
    }
    
    /// Returns true when the app may be used; otherwise brings up the licence window.
    func requireLicense() -> Bool {
        if Self.isRunningTests || Licensing.shared.isUnlocked { return true }
        LicenseWindowController.shared.present()
        return false
    }
    
    /// Menu item "License...": the licence window while locked, otherwise the settings
    /// (the licence is shown and can be deactivated on the General tab).
    @objc func showLicense() {
        if Licensing.shared.isUnlocked { openSettings() } else { LicenseWindowController.shared.present() }
    }
    
    /// The app has just been locked (licence deactivated in Settings, or rejected by the server):
    /// nothing of the app stays usable – the licence window takes over.
    func licenseStateDidChange() {
        guard !Licensing.shared.isUnlocked else { return }
        settingsWindow?.close()
        if isLauncherOpen { forceCloseRadialMenu() }
        LicenseWindowController.shared.present()
    }
    
    #if DEBUG
    /// Diagnostic hook (debug builds only): `-CircleAutoActivate <key>` runs the whole licence
    /// cycle in the real app – enter the key, open the settings, deactivate – prints the outcome
    /// and quits. It uses its own keychain entry and settings, so a licence that is really in use
    /// on this Mac is not touched.
    private func autoActivateIfRequested() {
        guard let key = UserDefaults.standard.string(forKey: "CircleAutoActivate"), !key.isEmpty else { return }
        Task {
            try? await Task.sleep(for: .seconds(2))
            while Licensing.shared.isCheckingKey { try? await Task.sleep(for: .milliseconds(100)) }
            let gate = LicenseWindowController.shared.window
            var report = "windowBefore=\(gate?.isVisible ?? false) closable=\(gate?.styleMask.contains(.closable) ?? true) lockedBefore=\(!self.requireLicense())"
            let unlocked = await Licensing.shared.activate(licenseKey: key)
            try? await Task.sleep(for: .milliseconds(600))
            report += " | unlocked=\(unlocked) usable=\(self.requireLicense()) windowAfter=\(gate?.isVisible ?? false) error=\(Licensing.shared.lastError ?? "-")"
            if unlocked {
                // Settings open, then what "Deactivate License on This Mac" does.
                self.openSettings()
                try? await Task.sleep(for: .milliseconds(600))
                let settingsOpen = self.settingsWindow?.isVisible ?? false
                let deactivated = await Licensing.shared.deactivateThisDevice()
                try? await Task.sleep(for: .milliseconds(800))
                report += " | settingsOpen=\(settingsOpen) deactivated=\(deactivated) lockedAfter=\(!Licensing.shared.isUnlocked) settingsClosed=\(!(self.settingsWindow?.isVisible ?? false)) windowBack=\(gate?.isVisible ?? false) keyForgotten=\(Licensing.shared.maskedLicenseKey == nil)"
            }
            print("LICENSE-SELFTEST " + report)
            Licensing.shared.forgetStoredKeyForTesting()
            exit(0)
        }
    }
    #endif
}
#endif
