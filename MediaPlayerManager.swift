//
//  MediaPlayerManager.swift
//  Circle Launcher
//
//  Created by André Lobach on 05.04.26.
//

import AppKit
import MediaPlayer

/// Manager for controlling system media playback
class MediaPlayerManager {
    static let shared = MediaPlayerManager()
    
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    private let nowPlayingCenter = MPNowPlayingInfoCenter.default()
    
    private init() {}
    
    // MARK: - Playback Controls
    
    /// Toggle play/pause
    func togglePlayPause() {
        // Use AppleScript for reliable Music.app control
        let script = """
        tell application "Music"
            if it is running then
                playpause
            end if
        end tell
        """
        executeAppleScript(script)
    }
    
    /// Play next track
    func nextTrack() {
        let script = """
        tell application "Music"
            if it is running then
                next track
            end if
        end tell
        """
        executeAppleScript(script)
    }
    
    /// Play previous track
    func previousTrack() {
        let script = """
        tell application "Music"
            if it is running then
                previous track
            end if
        end tell
        """
        executeAppleScript(script)
    }
    
    /// Toggle shuffle
    func toggleShuffle() {
        let script = """
        tell application "Music"
            if it is running then
                set shuffle enabled to not shuffle enabled
            end if
        end tell
        """
        executeAppleScript(script)
    }
    
    /// Toggle repeat mode
    func toggleRepeat() {
        let script = """
        tell application "Music"
            if it is running then
                if song repeat is off then
                    set song repeat to all
                else if song repeat is all then
                    set song repeat to one
                else
                    set song repeat to off
                end if
            end if
        end tell
        """
        executeAppleScript(script)
    }
    
    // MARK: - Now Playing Info
    
    struct NowPlayingInfo {
        let trackName: String
        let artist: String
        let album: String
        let artwork: NSImage?
        let isPlaying: Bool
        let shuffleEnabled: Bool
        let repeatMode: String // "off", "all", "one"
    }
    
    /// Get current now playing info
    func getNowPlayingInfo() -> NowPlayingInfo? {
        let script = """
        tell application "Music"
            if it is running and player state is not stopped then
                set trackName to name of current track
                set artistName to artist of current track
                set albumName to album of current track
                set isPlaying to (player state is playing)
                set shuffleState to shuffle enabled
                set repeatState to song repeat as string
                return trackName & "|||" & artistName & "|||" & albumName & "|||" & isPlaying & "|||" & shuffleState & "|||" & repeatState
            else
                return "Not Playing"
            end if
        end tell
        """
        
        guard let result = executeAppleScript(script),
              result != "Not Playing",
              !result.isEmpty else {
            return nil
        }
        
        let components = result.split(separator: "|||").map(String.init)
        guard components.count >= 6 else { return nil }
        
        return NowPlayingInfo(
            trackName: components[0],
            artist: components[1],
            album: components[2],
            artwork: getArtwork(),
            isPlaying: components[3] == "true",
            shuffleEnabled: components[4] == "true",
            repeatMode: components[5].lowercased()
        )
    }
    
    private func getArtwork() -> NSImage? {
        // Try to get artwork from Music.app
        let script = """
        tell application "Music"
            if it is running and player state is not stopped then
                try
                    set artworkData to data of artwork 1 of current track
                    return artworkData
                end try
            end if
        end tell
        """
        
        // For now, return placeholder
        // Artwork extraction via AppleScript is complex
        return NSImage(systemSymbolName: "music.note", accessibilityDescription: "Music")
    }
    
    // MARK: - Helper
    
    @discardableResult
    private func executeAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("❌ AppleScript Error: \(error)")
                return nil
            }
            return output.stringValue
        }
        return nil
    }
    
    /// Check if Music.app is running
    func isMusicAppRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
    }
    
    /// Launch Music.app
    func launchMusicApp() {
        if let musicURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Music") {
            NSWorkspace.shared.openApplication(at: musicURL, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                if let error = error {
                    print("❌ Error launching Music: \(error)")
                }
            }
        }
    }
}
