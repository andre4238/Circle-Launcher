//
//  AppItem.swift
//  Circle Launcher
//
//  Created by André Lobach on 03.04.26.
//

import AppKit
import SwiftData

@Model
final class AppItem {
    var id: UUID
    var name: String
    var bundleIdentifier: String
    var position: Int
    
    // Cache für Icon (wird nicht in SwiftData gespeichert)
    @Transient
    private var cachedIcon: NSImage?
    
    init(name: String, bundleIdentifier: String, position: Int) {
        self.id = UUID()
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.position = position
    }
    
    /// Get the app icon from the bundle identifier (cached)
    var icon: NSImage {
        // Wenn bereits gecached, direkt zurückgeben
        if let cached = cachedIcon {
            return cached
        }
        
        // Icon laden und cachen
        let loadedIcon: NSImage
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            loadedIcon = NSWorkspace.shared.icon(forFile: appURL.path)
        } else {
            // Fallback Icon
            loadedIcon = NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil) ?? NSImage()
        }
        
        cachedIcon = loadedIcon
        return loadedIcon
    }
    
    /// Launch the app safely
    func launch() {
        // Sicheres Starten auf dem Main Thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            
            NSWorkspace.shared.openApplication(
                at: NSWorkspace.shared.urlForApplication(withBundleIdentifier: self.bundleIdentifier) ?? URL(fileURLWithPath: "/"),
                configuration: configuration
            ) { app, error in
                if let error = error {
                    print("❌ Fehler beim Starten von \(self.name): \(error.localizedDescription)")
                } else {
                    print("✅ App erfolgreich gestartet: \(self.name)")
                }
            }
        }
    }
}
