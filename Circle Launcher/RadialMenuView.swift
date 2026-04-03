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
    
    private let radius: CGFloat = 120
    private let centerCircleRadius: CGFloat = 40
    private let itemSize: CGFloat = 60
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with blur effect
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .clipShape(Circle())
                    .frame(width: radius * 2 + 100, height: radius * 2 + 100)
                
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
                        .font(.system(size: 24))
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
                    .onHover { hovering in
                        hoveredIndex = hovering ? index : nil
                        onHoverChange(hovering ? app : nil)
                    }
                    // KEIN onTapGesture mehr - nur Hover
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(width: 400, height: 400)
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
        VStack(spacing: 4) {
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
                    .frame(width: 32, height: 32)
            }
            .frame(width: 50, height: 50)
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .shadow(color: isHovered ? .accentColor.opacity(0.5) : .clear, radius: 10)
            
            Text(app.name)
                .font(.caption)
                .fontWeight(isHovered ? .semibold : .regular)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2)
                .lineLimit(1)
                .frame(maxWidth: 80)
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
    .frame(width: 400, height: 400)
}
