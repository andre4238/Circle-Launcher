//
//  LaunchAtLoginManager.swift
//  Circle Launcher
//
//  Created by André Lobach on 04.04.26.
//

import Foundation
import ServiceManagement
import AppKit

/// Manager für "Bei Systemstart öffnen" Funktionalität
class LaunchAtLoginManager {
    
    /// Singleton-Instanz
    static let shared = LaunchAtLoginManager()
    
    private init() {}
    
    /// Prüft, ob die App bei Login gestartet wird
    var isEnabled: Bool {
        get {
            // Für macOS 13.0+ verwenden wir SMAppService
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                // Fallback für ältere Versionen (sollte nicht nötig sein da wir macOS 13.0+ erfordern)
                return UserDefaults.standard.bool(forKey: "launchAtLogin")
            }
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        // Login Item registrieren
                        try SMAppService.mainApp.register()
                        print("✅ Launch at login aktiviert")
                    } else {
                        // Login Item deaktivieren
                        try SMAppService.mainApp.unregister()
                        print("❌ Launch at login deaktiviert")
                    }
                    
                    // Speichere in UserDefaults für Backup
                    UserDefaults.standard.set(newValue, forKey: "launchAtLogin")
                    
                } catch {
                    print("⚠️ Fehler beim Setzen von Launch at Login: \(error.localizedDescription)")
                    
                    // Bei Fehler in UserDefaults speichern
                    UserDefaults.standard.set(newValue, forKey: "launchAtLogin")
                }
            } else {
                // Fallback für ältere Versionen
                UserDefaults.standard.set(newValue, forKey: "launchAtLogin")
            }
        }
    }
    
    /// Status des Login Items als String (für Debugging)
    var statusDescription: String {
        if #available(macOS 13.0, *) {
            switch SMAppService.mainApp.status {
            case .enabled:
                return "Aktiviert ✅"
            case .notRegistered:
                return "Nicht registriert"
            case .notFound:
                return "Nicht gefunden"
            case .requiresApproval:
                return "Benötigt Genehmigung ⚠️"
            @unknown default:
                return "Unbekannter Status"
            }
        } else {
            return isEnabled ? "Aktiviert ✅" : "Deaktiviert ❌"
        }
    }
    
    /// Aktiviert Launch at Login beim ersten Start (einmalig)
    func enableOnFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        
        if !hasLaunchedBefore {
            // Erster Start - aktiviere Launch at Login automatisch
            print("🎉 Erster Start erkannt - aktiviere Launch at Login")
            isEnabled = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        } else {
            print("📍 App wurde bereits gestartet - Launch at Login Status: \(statusDescription)")
        }
    }
    
    /// Öffnet die Systemeinstellungen für Login Items (falls Genehmigung erforderlich)
    func openLoginItemsSettings() {
        if #available(macOS 13.0, *) {
            // Öffne Systemeinstellungen → Allgemein → Anmeldeobjekte
            if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
