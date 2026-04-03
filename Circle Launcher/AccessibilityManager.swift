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
        alert.messageText = "Accessibility-Berechtigung erforderlich"
        alert.informativeText = """
        Circle Launcher benötigt Accessibility-Berechtigung, um den globalen Hotkey (⌥Space) zu erkennen.
        
        So beheben Sie das Problem:
        
        1. Öffnen Sie Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen
        2. Klicken Sie auf das Schloss-Symbol 🔒 und authentifizieren Sie sich
        3. Suchen Sie "Circle Launcher" in der Liste (oder fügen Sie es mit + hinzu)
        4. Aktivieren Sie das Kontrollkästchen
        5. Starten Sie Circle Launcher neu
        
        WICHTIG: Die App erscheint erst in der Liste, nachdem Sie diese Warnung gesehen haben!
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Systemeinstellungen öffnen")
        alert.addButton(withTitle: "Später")
        alert.addButton(withTitle: "Anleitung kopieren")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            openAccessibilityPreferences()
        } else if response == .alertThirdButtonReturn {
            // Copy instructions to clipboard
            let instructions = """
            Circle Launcher - Accessibility-Berechtigung einrichten:
            
            1. Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen
            2. Klicken Sie auf das Schloss-Symbol (🔒) und authentifizieren Sie sich
            3. Suchen Sie "Circle Launcher" in der Liste
            4. Falls nicht vorhanden: Klicken Sie auf + und wählen Sie die Circle Launcher.app
            5. Aktivieren Sie das Kontrollkästchen neben Circle Launcher
            6. Starten Sie Circle Launcher neu
            
            Dann funktioniert der ⌥Space Hotkey systemweit!
            """
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(instructions, forType: .string)
            
            let copied = NSAlert()
            copied.messageText = "Anleitung kopiert!"
            copied.informativeText = "Die Anleitung wurde in die Zwischenablage kopiert."
            copied.runModal()
        }
    }
    
    private static func openAccessibilityPreferences() {
        let prefpaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(prefpaneURL)
    }
}
