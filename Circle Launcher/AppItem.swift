//
//  AppItem.swift
//  Circle Launcher
//
//  Created by André Lobach on 03.04.26.
//

import AppKit
import SwiftData

/// Thread-sicherer Icon-Cache
private final class AppIconCache {
    static let shared = AppIconCache()
    
    private var cache: [String: NSImage] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    func getIcon(for bundleIdentifier: String) -> NSImage {
        lock.lock()
        
        // Prüfe Cache
        if let cached = cache[bundleIdentifier] {
            lock.unlock()
            return cached
        }
        
        lock.unlock()
        
        // Icon laden (außerhalb des Locks)
        let icon = loadIcon(for: bundleIdentifier)
        
        lock.lock()
        cache[bundleIdentifier] = icon
        lock.unlock()
        
        return icon
    }
    
    private func loadIcon(for bundleIdentifier: String) -> NSImage {
        // Sicherstellen dass wir auf Main Thread sind
        guard Thread.isMainThread else {
            return DispatchQueue.main.sync {
                return loadIcon(for: bundleIdentifier)
            }
        }
        
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSSize(width: 512, height: 512)
            return icon
        } else {
            // Fallback Icon
            return NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil) ?? NSImage()
        }
    }
    
    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}

@Model
final class AppItem {
    var id: UUID
    var name: String
    var bundleIdentifier: String
    var position: Int
    
    init(name: String, bundleIdentifier: String, position: Int) {
        self.id = UUID()
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.position = position
    }
    
    /// Get the app icon from the bundle identifier
    /// Verwendet thread-sicheren Cache
    var icon: NSImage {
        return AppIconCache.shared.getIcon(for: bundleIdentifier)
    }
    
    /// Launch the app safely
    func launch() {
        // Capture values we need BEFORE going async
        let appName = self.name
        let bundleID = self.bundleIdentifier
        
        // Sicheres Starten auf dem Main Thread
        DispatchQueue.main.async {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
                print("❌ App nicht gefunden: \(appName) (\(bundleID))")
                return
            }
            
            NSWorkspace.shared.openApplication(
                at: appURL,
                configuration: configuration
            ) { app, error in
                if let error = error {
                    print("❌ Fehler beim Starten von \(appName): \(error.localizedDescription)")
                } else {
                    print("✅ App erfolgreich gestartet: \(appName)")
                }
            }
        }
    }
}
