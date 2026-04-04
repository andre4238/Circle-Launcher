//
//  IconCacheManager.swift
//  Circle Launcher
//
//  Created by André Lobach on 03.04.26.
//

import AppKit

/// Thread-sicherer Icon-Cache-Manager mit NSLock
final class IconCacheManager {
    static let shared = IconCacheManager()
    
    private var cache: [String: NSImage] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    /// Holt ein Icon aus dem Cache oder lädt es neu (thread-sicher)
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
    
    /// Lädt ein Icon synchron (muss auf Main Thread sein für NSWorkspace)
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
    
    /// Cache löschen (z.B. bei Memory-Warning)
    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
    
    /// Einzelnes Icon aus Cache entfernen
    func removeIcon(for bundleIdentifier: String) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeValue(forKey: bundleIdentifier)
    }
}
