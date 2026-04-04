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

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var radialMenuPanel: RadialMenuPanel?
    var settingsWindow: NSWindow?
    var eventMonitor: Any?
    var modelContainer: ModelContainer!
    var isLauncherOpen = false // Track ob Launcher offen ist
    var launcherOpenPosition: NSPoint? // Position wo Launcher geöffnet wurde
    var hoveredApp: AppItem? // Aktuell gehoverte App
    
    // DEBUG: Verhindert automatisches Schließen beim Loslassen der Tasten
    var debugKeepOpen = false
    
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
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
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
        panel.delegate = self
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
            if let app = hoveredApp {
                app.launch()
                print("🚀 App gestartet: \(app.name)")
            }
            
            panel.close()
            isLauncherOpen = false
            launcherOpenPosition = nil
            hoveredApp = nil // Reset nach dem Schließen
        }
    }
    
    private func forceCloseRadialMenu() {
        // Schließt das Menü OHNE App zu starten (z.B. bei Escape)
        guard let panel = radialMenuPanel else { return }
        if panel.isVisible {
            print("❌ Menü abgebrochen ohne App zu starten")
            panel.close()
            isLauncherOpen = false
            launcherOpenPosition = nil
            hoveredApp = nil // Reset ohne App zu starten
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
        guard let panel = radialMenuPanel else { return }
        
        // Nur Position beim ersten Öffnen speichern
        if launcherOpenPosition == nil {
            launcherOpenPosition = NSEvent.mouseLocation
        }
        
        // Verwende die gespeicherte Position
        guard let openPosition = launcherOpenPosition else { return }
        
        // Update content view with fresh data from model container
        let radialMenuView = RadialMenuView(
            onHoverChange: { [weak self] app in
                self?.hoveredApp = app
                if let app = app {
                    print("🎯 Hovering: \(app.name)")
                } else {
                    print("❌ Kein Hover")
                }
            },
            onClose: { [weak self] in
                self?.closeRadialMenu()
            }
        )
        .modelContainer(modelContainer)
        
        let hostingView = NSHostingView(rootView: radialMenuView)
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
        
        // Debug: Apps zählen
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<AppItem>()
        if let apps = try? context.fetch(descriptor) {
            print("🔍 Launcher zeigt \(apps.count) Apps an")
            for app in apps {
                print("  - \(app.name) (\(app.bundleIdentifier))")
            }
        }
    }
    
    @objc private func openSettings() {
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
            window.title = "Circle Launcher Settings"
            window.contentView = NSHostingView(rootView: settingsView)
            window.center()
            
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
        if let window = notification.object as? NSWindow, window === settingsWindow {
            settingsWindow = nil
        }
    }
}
