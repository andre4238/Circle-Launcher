//
//  RadialMenuPanel.swift
//  Circle Launcher
//
//  Created by André Lobach on 03.04.26.
//

import Cocoa
import SwiftUI
import SwiftData

class RadialMenuPanel: NSPanel {
    var modelContainer: ModelContainer?
    private var mouseTrackingTimer: Timer?
    var onEscapeClose: (() -> Void)?  // Callback für Escape-Taste
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        // Configure panel properties
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .popUpMenu
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isMovableByWindowBackground = false
        self.hasShadow = true
        
        // Setup content view
        setupContentView()
        
        // Setup escape key handling
        setupEscapeKeyHandling()
    }
    
    private func setupContentView() {
        let radialMenuView = RadialMenuView(
            onHoverChange: { _ in },
            onClose: { [weak self] in
                self?.close()
            }
        )
        
        let hostingView = NSHostingView(rootView: radialMenuView)
        hostingView.frame = contentRect(forFrameRect: frame)
        
        self.contentView = hostingView
    }
    
    private func setupEscapeKeyHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                self?.onEscapeClose?() // Rufe den Callback auf
                return nil
            }
            return event
        }
    }
    
    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        
        // Update the hosting view with fresh data
        if let container = modelContainer {
            let radialMenuView = RadialMenuView(
                onHoverChange: { _ in },
                onClose: { [weak self] in
                    self?.close()
                }
            )
            .modelContainer(container)
            
            let hostingView = NSHostingView(rootView: radialMenuView)
            hostingView.frame = contentRect(forFrameRect: frame)
            self.contentView = hostingView
        }
        
        // Mouse tracking ist deaktiviert - Menü schließt nur beim Loslassen der Tasten
        // startMouseTracking()
    }
    
    override func close() {
        stopMouseTracking()
        super.close()
    }
    
    private func startMouseTracking() {
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkMousePosition()
        }
    }
    
    private func stopMouseTracking() {
        mouseTrackingTimer?.invalidate()
        mouseTrackingTimer = nil
    }
    
    private func checkMousePosition() {
        let mouseLocation = NSEvent.mouseLocation
        let panelFrame = self.frame
        
        // Calculate distance from center
        let centerX = panelFrame.midX
        let centerY = panelFrame.midY
        let distance = sqrt(pow(mouseLocation.x - centerX, 2) + pow(mouseLocation.y - centerY, 2))
        
        // Close if mouse is far from the menu (more than half the panel size)
        if distance > panelFrame.width / 2 + 50 {
            self.close()
        }
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}
