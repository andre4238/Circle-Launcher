//
//  MusicControlView.swift
//  Circle Launcher
//
//  Created by André Lobach on 05.04.26.
//

import SwiftUI
import AppKit

struct MusicControlView: View {
    @AppStorage("circleRadius") private var circleRadius: Double = 80.0
    @AppStorage("iconSize") private var iconSize: Double = 32.0
    
    @State private var nowPlaying: MediaPlayerManager.NowPlayingInfo?
    @State private var hoveredControl: MusicControl? = nil
    
    var onClose: () -> Void
    
    private var centerCircleRadius: CGFloat {
        circleRadius * 0.375
    }
    
    private var itemSize: CGFloat {
        circleRadius * 0.625
    }
    
    private var frameSize: CGFloat {
        circleRadius * 3.75
    }
    
    private var backgroundSize: CGFloat {
        circleRadius * 2 + 80
    }
    
    enum MusicControl: String, CaseIterable {
        case playPause = "Play/Pause"
        case next = "Next"
        case previous = "Previous"
        case shuffle = "Shuffle"
        case repeat_ = "Repeat"
        
        var icon: String {
            switch self {
            case .playPause: return "play.fill"
            case .next: return "forward.fill"
            case .previous: return "backward.fill"
            case .shuffle: return "shuffle"
            case .repeat_: return "repeat"
            }
        }
        
        var pauseIcon: String {
            return "pause.fill"
        }
        
        var position: Int {
            switch self {
            case .playPause: return 0  // Top
            case .next: return 1       // Right
            case .repeat_: return 2    // Bottom-right
            case .shuffle: return 4    // Bottom-left
            case .previous: return 5   // Left
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background blur ring (same as RadialMenuView)
                VisualEffectView(material: NSVisualEffectView.Material.hudWindow, blendingMode: NSVisualEffectView.BlendingMode.behindWindow)
                    .frame(width: backgroundSize, height: backgroundSize)
                    .mask(
                        ZStack {
                            Circle()
                                .fill(Color.white)
                            
                            Circle()
                                .fill(Color.black)
                                .frame(width: centerCircleRadius * 2, height: centerCircleRadius * 2)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                    )
                
                // Center circle with now playing info
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: centerCircleRadius * 2.5, height: centerCircleRadius * 2.5)
                    
                    VStack(spacing: 4) {
                        if let info = nowPlaying {
                            // Album artwork or music icon
                            if let artwork = info.artwork {
                                Image(nsImage: artwork)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else {
                                Image(systemName: "music.note")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                            
                            Text(info.trackName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: centerCircleRadius * 2)
                            
                            Text(info.artist)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                                .frame(maxWidth: centerCircleRadius * 2)
                        } else {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("No Music Playing")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(8)
                }
                
                // Music controls
                ForEach(MusicControl.allCases, id: \.self) { control in
                    let angle = angleForPosition(control.position, total: 6)
                    let position = positionForAngle(angle, center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                    
                    MusicControlButton(
                        control: control,
                        isHovered: hoveredControl == control,
                        isPlaying: nowPlaying?.isPlaying ?? false,
                        isShuffleOn: nowPlaying?.shuffleEnabled ?? false,
                        repeatMode: nowPlaying?.repeatMode ?? "off",
                        iconSize: iconSize
                    )
                    .frame(width: itemSize, height: itemSize)
                    .background(Color.clear)
                    .position(position)
                    .contentShape(Circle())
                    .onHover { hovering in
                        hoveredControl = hovering ? control : nil
                    }
                    .onTapGesture {
                        handleControlTap(control)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(width: frameSize, height: frameSize)
        .onAppear {
            updateNowPlaying()
            
            // Update now playing info periodically
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateNowPlaying()
            }
        }
    }
    
    private func updateNowPlaying() {
        nowPlaying = MediaPlayerManager.shared.getNowPlayingInfo()
    }
    
    private func handleControlTap(_ control: MusicControl) {
        switch control {
        case .playPause:
            MediaPlayerManager.shared.togglePlayPause()
        case .next:
            MediaPlayerManager.shared.nextTrack()
        case .previous:
            MediaPlayerManager.shared.previousTrack()
        case .shuffle:
            MediaPlayerManager.shared.toggleShuffle()
        case .repeat_:
            MediaPlayerManager.shared.toggleRepeat()
        }
        
        // Update info after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            updateNowPlaying()
        }
        
        // Don't close on tap, only on release of keys
        print("🎵 Music control: \(control.rawValue)")
    }
    
    private func angleForPosition(_ position: Int, total: Int) -> Double {
        let angleStep = 360.0 / Double(total)
        return Double(position) * angleStep - 90
    }
    
    private func positionForAngle(_ angle: Double, center: CGPoint) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: center.x + circleRadius * cos(radians),
            y: center.y + circleRadius * sin(radians)
        )
    }
}

struct MusicControlButton: View {
    let control: MusicControlView.MusicControl
    let isHovered: Bool
    let isPlaying: Bool
    let isShuffleOn: Bool
    let repeatMode: String
    let iconSize: Double
    
    var iconName: String {
        switch control {
        case .playPause:
            return isPlaying ? control.pauseIcon : control.icon
        case .shuffle:
            return control.icon
        case .repeat_:
            return repeatMode == "one" ? "repeat.1" : control.icon
        default:
            return control.icon
        }
    }
    
    var isActive: Bool {
        switch control {
        case .shuffle:
            return isShuffleOn
        case .repeat_:
            return repeatMode != "off"
        default:
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: iconName)
                .font(.system(size: iconSize))
                .foregroundColor(isActive ? .accentColor : .white)
                .scaleEffect(isHovered ? 1.3 : 1.0)
                .shadow(color: isHovered ? .accentColor.opacity(0.6) : .black.opacity(0.3), radius: isHovered ? 12 : 4)
                .shadow(color: .black.opacity(0.5), radius: 2)
        }
        .background(Color.clear)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

// Visual effect view for macOS blur
fileprivate struct VisualEffectView: NSViewRepresentable {
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

