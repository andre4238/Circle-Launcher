//
//  HotkeyManager.swift
//  Circle Launcher
//
//  Created by André Lobach on 04.04.26.
//

import Foundation
import AppKit

/// Manager für globale Hotkey-Konfiguration
class HotkeyManager {
    
    /// Singleton-Instanz
    static let shared = HotkeyManager()
    
    private init() {}
    
    // MARK: - Hotkey Configuration
    
    /// Verfügbare Modifier-Kombinationen
    enum ModifierCombination: String, CaseIterable, Identifiable {
        case optionCommand = "⌥⌘ (Option + Command)"
        case controlOption = "⌃⌥ (Control + Option)"
        case controlCommand = "⌃⌘ (Control + Command)"
        case shiftCommand = "⇧⌘ (Shift + Command)"
        case shiftOption = "⇧⌥ (Shift + Option)"
        case controlShift = "⌃⇧ (Control + Shift)"
        
        var id: String { rawValue }
        
        /// NSEvent.ModifierFlags für diese Kombination
        var modifierFlags: NSEvent.ModifierFlags {
            switch self {
            case .optionCommand:
                return [.option, .command]
            case .controlOption:
                return [.control, .option]
            case .controlCommand:
                return [.control, .command]
            case .shiftCommand:
                return [.shift, .command]
            case .shiftOption:
                return [.shift, .option]
            case .controlShift:
                return [.control, .shift]
            }
        }
        
        /// Display-Name (kurz)
        var displayName: String {
            switch self {
            case .optionCommand:
                return "⌥⌘"
            case .controlOption:
                return "⌃⌥"
            case .controlCommand:
                return "⌃⌘"
            case .shiftCommand:
                return "⇧⌘"
            case .shiftOption:
                return "⇧⌥"
            case .controlShift:
                return "⌃⇧"
            }
        }
        
        /// Beschreibung für UI
        var description: String {
            switch self {
            case .optionCommand:
                return "Option + Command (Standard)"
            case .controlOption:
                return "Control + Option"
            case .controlCommand:
                return "Control + Command"
            case .shiftCommand:
                return "Shift + Command"
            case .shiftOption:
                return "Shift + Option"
            case .controlShift:
                return "Control + Shift"
            }
        }
    }
    
    /// Aktuell konfigurierte Modifier-Kombination
    var currentModifiers: ModifierCombination {
        get {
            let savedRawValue = UserDefaults.standard.string(forKey: "hotkeyModifiers") ?? ModifierCombination.optionCommand.rawValue
            return ModifierCombination(rawValue: savedRawValue) ?? .optionCommand
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "hotkeyModifiers")
            print("⌨️ Hotkey geändert zu: \(newValue.displayName)")
        }
    }
    
    /// Prüft, ob die aktuell gedrückten Modifier dem konfigurierten Hotkey entsprechen
    func matchesCurrentHotkey(_ modifiers: NSEvent.ModifierFlags) -> Bool {
        let currentFlags = currentModifiers.modifierFlags
        return modifiers.contains(currentFlags)
    }
    
    /// Gibt die aktuellen Modifier-Flags zurück
    var currentModifierFlags: NSEvent.ModifierFlags {
        return currentModifiers.modifierFlags
    }
}
