//
//  AccessibilityManager.swift
//  Circle Launcher
//
//  Created by André Lobach on 03.04.26.
//

import Cocoa
import ApplicationServices

class AccessibilityManager {
    
    /// Check if the app has accessibility permissions
    static func hasAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Request accessibility permissions with prompt
    static func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// Show alert if permissions are not granted
    static func checkAndRequestPermissions() {
        if !hasAccessibilityPermissions() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showPermissionAlert()
            }
        }
    }
    
    private static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        Circle Launcher needs Accessibility permission to detect the global hotkey (⌥Space).
        
        How to fix:
        
        1. Open System Settings → Privacy & Security → Accessibility
        2. Click the lock icon 🔒 and authenticate
        3. Look for "Circle Launcher" in the list (or add it with +)
        4. Enable the checkbox
        5. Restart Circle Launcher
        
        IMPORTANT: The app will only appear in the list after you've seen this warning!
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        alert.addButton(withTitle: "Copy Instructions")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            openAccessibilityPreferences()
        } else if response == .alertThirdButtonReturn {
            // Copy instructions to clipboard
            let instructions = """
            Circle Launcher - Setting up Accessibility Permission:
            
            1. System Settings → Privacy & Security → Accessibility
            2. Click the lock icon (🔒) and authenticate
            3. Look for "Circle Launcher" in the list
            4. If not present: Click + and select Circle Launcher.app
            5. Enable the checkbox next to Circle Launcher
            6. Restart Circle Launcher
            
            Then the ⌥Space hotkey will work system-wide!
            """
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(instructions, forType: .string)
            
            let copied = NSAlert()
            copied.messageText = "Instructions Copied!"
            copied.informativeText = "The instructions have been copied to the clipboard."
            copied.runModal()
        }
    }
    
    private static func openAccessibilityPreferences() {
        let prefpaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(prefpaneURL)
    }
}
