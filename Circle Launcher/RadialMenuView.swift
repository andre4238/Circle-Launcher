//
//  RadialMenuView.swift
//  Circle Launcher
//
//  Created by André Lobach on 03.04.26.
//

import SwiftUI
import SwiftData
import AppKit

struct RadialMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppItem.position) private var apps: [AppItem]
    
    var onHoverChange: (AppItem?) -> Void
    var onClose: () -> Void
    
    @State private var hoveredIndex: Int? = nil
    @State private var mouseLocation: CGPoint = .zero
    @State private var trackingMouseLocation = false
    
    private let radius: CGFloat = 80  // Reduziert von 120 → Apps näher am Zentrum
    private let centerCircleRadius: CGFloat = 30  // Reduziert von 40 → Kleinerer Mittelkreis
    private let itemSize: CGFloat = 50  // Reduziert von 60 → Kleinere App-Icons
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with blur effect
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .clipShape(Circle())
                    .frame(width: radius * 2 + 80, height: radius * 2 + 80)  // Reduziert von +100 → kompakter
                
                // LINIEN ENTFERNT - Kein Canvas mehr
                
                // Center circle
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    
                    Image(systemName: "app.dashed")
                        .font(.system(size: 18))  // Reduziert von 24 → kleineres Icon
                        .foregroundStyle(.secondary)
                }
                .frame(width: centerCircleRadius * 2, height: centerCircleRadius * 2)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // App items
                ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                    let angle = angleForIndex(index, total: apps.count)
                    let position = positionForAngle(angle, center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                    
                    AppItemView(
                        app: app,
                        isHovered: hoveredIndex == index
                    )
                    .frame(width: itemSize, height: itemSize)
                    .position(position)
                    .contentShape(Circle()) // Wichtig: Definiert die Hover-Area als Kreis
                    .onHover { hovering in
                        hoveredIndex = hovering ? index : nil
                        onHoverChange(hovering ? app : nil)
                        print("🎯 Hover-Status für \(app.name): \(hovering ? "EIN" : "AUS")")
                    }
                    .onTapGesture {
                        // Beim Klicken: App sofort starten und Menü schließen
                        app.launch()
                        print("🖱️ App per Klick gestartet: \(app.name)")
                        onClose()
                    }
                }
                
                // Invisible overlay for mouse tracking
                MouseTrackingView { location in
                    handleMouseMove(at: location, in: geometry.size)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(width: 300, height: 300)  // Reduziert von 400x400 → kompakteres Menü
    }
    
    private func handleMouseMove(at location: CGPoint, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Check which app is being hovered
        var newHoveredIndex: Int? = nil
        var closestDistance: CGFloat = .infinity
        
        for (index, _) in apps.enumerated() {
            let angle = angleForIndex(index, total: apps.count)
            let position = positionForAngle(angle, center: center)
            
            // Calculate distance from mouse to app position
            let distance = sqrt(pow(location.x - position.x, 2) + pow(location.y - position.y, 2))
            
            // If within itemSize radius (not /2, full size for easier hover)
            if distance <= itemSize && distance < closestDistance {
                newHoveredIndex = index
                closestDistance = distance
            }
        }
        
        // Only update if changed
        if newHoveredIndex != hoveredIndex {
            hoveredIndex = newHoveredIndex
            onHoverChange(newHoveredIndex != nil ? apps[newHoveredIndex!] : nil)
            
            if let index = newHoveredIndex {
                print("🎯 Hovering über: \(apps[index].name) (Distanz: \(Int(closestDistance))px)")
            } else {
                print("❌ Kein Hover")
            }
        }
    }
    
    private func angleForIndex(_ index: Int, total: Int) -> Double {
        let angleStep = 360.0 / Double(total)
        return Double(index) * angleStep - 90 // Start from top
    }
    
    private func positionForAngle(_ angle: Double, center: CGPoint) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: center.x + radius * cos(radians),
            y: center.y + radius * sin(radians)
        )
    }
}

struct AppItemView: View {
    let app: AppItem
    let isHovered: Bool
    
    var body: some View {
        VStack(spacing: 3) {  // Reduziert von 4 → kompakter
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(isHovered ? Color.accentColor : Color.white.opacity(0.3), lineWidth: isHovered ? 3 : 2)
                    )
                
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)  // Reduziert von 32 → kleinere Icons
            }
            .frame(width: 42, height: 42)  // Reduziert von 50 → kompaktere Circles
            .scaleEffect(isHovered ? 1.15 : 1.0)  // Etwas mehr Scale für bessere Sichtbarkeit
            .shadow(color: isHovered ? .accentColor.opacity(0.5) : .clear, radius: 10)
            
            Text(app.name)
                .font(.caption2)  // Kleinere Schrift
                .fontWeight(isHovered ? .semibold : .regular)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2)
                .lineLimit(1)
                .frame(maxWidth: 70)  // Reduziert von 80 → weniger Platz
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

// Visual effect view for macOS blur
struct VisualEffectView: NSViewRepresentable {
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

// Mouse tracking view for accurate hover detection
struct MouseTrackingView: NSViewRepresentable {
    var onMouseMove: (CGPoint) -> Void
    
    func makeNSView(context: Context) -> MouseTrackingNSView {
        let view = MouseTrackingNSView()
        view.onMouseMove = onMouseMove
        return view
    }
    
    func updateNSView(_ nsView: MouseTrackingNSView, context: Context) {
        nsView.onMouseMove = onMouseMove
    }
}

class MouseTrackingNSView: NSView {
    var onMouseMove: ((CGPoint) -> Void)?
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [
            .activeAlways,
            .mouseMoved,
            .mouseEnteredAndExited,
            .inVisibleRect
        ]
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: options,
            owner: self,
            userInfo: nil
        )
        
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        let locationInView = convert(event.locationInWindow, from: nil)
        // Flip Y coordinate because AppKit uses bottom-left origin, SwiftUI uses top-left
        let flippedLocation = CGPoint(x: locationInView.x, y: bounds.height - locationInView.y)
        onMouseMove?(flippedLocation)
    }
    
    override func mouseEntered(with event: NSEvent) {
        let locationInView = convert(event.locationInWindow, from: nil)
        let flippedLocation = CGPoint(x: locationInView.x, y: bounds.height - locationInView.y)
        onMouseMove?(flippedLocation)
    }
    
    override func mouseExited(with event: NSEvent) {
        onMouseMove?(CGPoint(x: -1000, y: -1000)) // Send far away point to clear hover
    }
}

#Preview {
    RadialMenuView(
        onHoverChange: { app in
            if let app = app {
                print("Hovering: \(app.name)")
            }
        },
        onClose: {
            print("Close")
        }
    )
    .modelContainer(for: AppItem.self, inMemory: true)
    .frame(width: 300, height: 300)  // Angepasst an neue Größe
}
