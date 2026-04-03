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
    
    init(name: String, bundleIdentifier: String, position: Int) {
        self.id = UUID()
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.position = position
    }
    
    /// Get the app icon from the bundle identifier
    var icon: NSImage {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        return NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil) ?? NSImage()
    }
    
    /// Launch the app
    func launch() {
        NSWorkspace.shared.launchApplication(
            withBundleIdentifier: bundleIdentifier,
            options: [],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )
    }
}
