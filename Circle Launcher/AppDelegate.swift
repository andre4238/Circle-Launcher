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

/// Manager für globale Hotkey-Konfiguration
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
        
        // Monitor for Flags Changed (Option + Command)
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            // Wenn Option UND Command gedrückt sind
            if event.modifierFlags.contains([.option, .command]) {
                // Nur öffnen wenn noch nicht offen
                if self?.isLauncherOpen == false {
                    self?.showRadialMenuAtCursor()
                }
            } else {
                // DEBUG: Nur schließen wenn debugKeepOpen NICHT aktiv ist
                if self?.isLauncherOpen == true && self?.debugKeepOpen == false {
                    self?.closeRadialMenu()
                }
            }
        }
        
        // Local monitor for flags changed (wenn app aktiv ist)
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            // Wenn Option UND Command gedrückt sind
            if event.modifierFlags.contains([.option, .command]) {
                // Nur öffnen wenn noch nicht offen
                if self?.isLauncherOpen == false {
                    self?.showRadialMenuAtCursor()
                }
            } else {
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
                print("✅ Accessibility permissions granted. Hotkey ⌥⌘ is active.")
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
            
            // MusicControlView inline definition (temporary until file is added to build target)
            struct TempMusicView: View {
                var onClose: () -> Void
                
                var body: some View {
                    ZStack {
                        Color.black.opacity(0.3)
                        
                        VStack(spacing: 20) {
                            Image(systemName: "music.note")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("Music Controls")
                                .font(.title)
                                .foregroundColor(.white)
                            
                            Text("Coming Soon")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button("Close") {
                                onClose()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(width: 300, height: 300)
                }
            }
            
            let tempMusicView = TempMusicView(
                onClose: { [weak self] in
                    self?.closeRadialMenu()
                }
            )
            
            hostingView = NSHostingView(rootView: AnyView(tempMusicView))
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
