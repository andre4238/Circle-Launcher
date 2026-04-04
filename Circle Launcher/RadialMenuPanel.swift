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
    private var localEventMonitor: Any?  // Store the event monitor
    
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
    
    deinit {
        // Cleanup event monitor auf main thread
        if Thread.isMainThread {
            if let monitor = localEventMonitor {
                NSEvent.removeMonitor(monitor)
            }
            stopMouseTracking()
        } else {
            let monitor = localEventMonitor
            DispatchQueue.main.async {
                if let monitor = monitor {
                    NSEvent.removeMonitor(monitor)
                }
            }
        }
    }
    
    private func setupContentView() {
        // Sicherstellen, dass wir auf dem Main Thread sind
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let radialMenuView = RadialMenuView(
                onHoverChange: { _ in },
                onClose: { [weak self] in
                    DispatchQueue.main.async {
                        self?.close()
                    }
                }
            )
            
            let hostingView = NSHostingView(rootView: radialMenuView)
            hostingView.frame = self.contentRect(forFrameRect: self.frame)
            
            self.contentView = hostingView
        }
    }
    
    private func setupEscapeKeyHandling() {
        // Remove old monitor if exists
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                DispatchQueue.main.async {
                    self?.onEscapeClose?()
                }
                return nil
            }
            return event
        }
    }
    
    override func makeKeyAndOrderFront(_ sender: Any?) {
        // Call super first, before async block
        super.makeKeyAndOrderFront(sender)
        
        // Then update content on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update the hosting view with fresh data
            if let container = self.modelContainer {
                let radialMenuView = RadialMenuView(
                    onHoverChange: { _ in },
                    onClose: { [weak self] in
                        DispatchQueue.main.async {
                            self?.close()
                        }
                    }
                )
                .modelContainer(container)
                
                let hostingView = NSHostingView(rootView: radialMenuView)
                hostingView.frame = self.contentRect(forFrameRect: self.frame)
                self.contentView = hostingView
            }
        }
    }
    
    override func close() {
        // Immer auf Main Thread ausführen
        if Thread.isMainThread {
            performClose()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.performClose()
            }
        }
    }
    
    private func performClose() {
        stopMouseTracking()
        super.close()
    }
    
    private func startMouseTracking() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.checkMousePosition()
            }
        }
    }
    
    private func stopMouseTracking() {
        if Thread.isMainThread {
            mouseTrackingTimer?.invalidate()
            mouseTrackingTimer = nil
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.mouseTrackingTimer?.invalidate()
                self?.mouseTrackingTimer = nil
            }
        }
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
            DispatchQueue.main.async { [weak self] in
                self?.close()
            }
        }
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}
