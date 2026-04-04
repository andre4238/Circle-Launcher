# Customizable Hotkey Feature

## Übersicht

Circle Launcher unterstützt jetzt **konfigurierbare globale Hotkeys**! Benutzer können aus 6 verschiedenen Modifier-Kombinationen wählen.

**Standard:** ⌥⌘ (Option + Command)

## Verfügbare Hotkeys

| Kombination | Symbole | Beschreibung |
|-------------|---------|--------------|
| **Option + Command** | ⌥⌘ | Standard (empfohlen) |
| Control + Option | ⌃⌥ | Alternative 1 |
| Control + Command | ⌃⌘ | Alternative 2 |
| Shift + Command | ⇧⌘ | Alternative 3 |
| Shift + Option | ⇧⌥ | Alternative 4 |
| Control + Shift | ⌃⇧ | Alternative 5 |

## Implementation

### Neue Dateien

#### 1. HotkeyManager.swift (NEU)

**Zweck:** Zentrale Verwaltung der Hotkey-Konfiguration

**Features:**
- Singleton-Pattern für globalen Zugriff
- Enum mit allen verfügbaren Kombinationen
- UserDefaults-Integration
- NSEvent.ModifierFlags-Mapping

**Code:**
```swift
class HotkeyManager {
    static let shared = HotkeyManager()
    
    enum ModifierCombination: String, CaseIterable {
        case optionCommand = "⌥⌘ (Option + Command)"
        case controlOption = "⌃⌥ (Control + Option)"
        // ... weitere Kombinationen
        
        var modifierFlags: NSEvent.ModifierFlags {
            switch self {
            case .optionCommand:
                return [.option, .command]
            // ...
            }
        }
    }
    
    var currentModifiers: ModifierCombination {
        get { /* UserDefaults */ }
        set { /* UserDefaults */ }
    }
    
    func matchesCurrentHotkey(_ modifiers: NSEvent.ModifierFlags) -> Bool
}
```

### Geänderte Dateien

#### 2. AppDelegate.swift

**Änderungen:**
- Verwendet `HotkeyManager.shared.matchesCurrentHotkey()`
- Dynamische Hotkey-Prüfung statt hardcoded `[.option, .command]`
- Zeigt aktuellen Hotkey in Console-Logs

**Vorher:**
```swift
if event.modifierFlags.contains([.option, .command]) {
    // Öffnen
}
```

**Nachher:**
```swift
if HotkeyManager.shared.matchesCurrentHotkey(event.modifierFlags) {
    // Öffnen
}
```

#### 3. SettingsView.swift

**Neue UI-Elemente im General Tab:**

1. **Hotkey Picker** - Dropdown-Menü mit allen Kombinationen
2. **Current Hotkey Display** - Zeigt aktiven Hotkey prominent
3. **Instructions** - Dynamische Anleitung mit aktuellem Hotkey
4. **Change Alert** - Bestätigung bei Hotkey-Änderung

**Code:**
```swift
@State private var selectedHotkey: HotkeyManager.ModifierCombination = HotkeyManager.shared.currentModifiers

Picker("Hotkey Combination", selection: $selectedHotkey) {
    ForEach(HotkeyManager.ModifierCombination.allCases) { combination in
        Text(combination.description)
            .tag(combination)
    }
}
.onChange(of: selectedHotkey) { oldValue, newValue in
    HotkeyManager.shared.currentModifiers = newValue
    showHotkeyChangedAlert(newValue)
}
```

## UI Design - General Tab

```
┌────────────────────────────────────────┐
│ Keyboard Shortcuts                     │
├────────────────────────────────────────┤
│ ⌨️  Global Hotkey                      │
│     Customize your launcher hotkey     │
│                                        │
│ Hotkey Combination:                    │
│ [Dropdown: ⌥⌘ (Option + Command) ▼]   │
│                                        │
│ ✋ Current Hotkey: ⌥⌘                  │
│                                        │
│ ────────────────────────────────────   │
│                                        │
│ How to use:                            │
│ • Press & Hold    ⌥⌘                   │
│ • Hover          Over your app         │
│ • Release        Keys to launch        │
└────────────────────────────────────────┘
```

## User Flow

### Hotkey ändern:

1. **Settings öffnen** → Menu Bar Icon → Settings
2. **General Tab** öffnen
3. **Hotkey Combination Picker** öffnen
4. **Neue Kombination** auswählen
5. **Alert** bestätigen
6. **Sofort aktiv** - Testen!

### Alert-Text:
```
Hotkey Changed
──────────────

Your global hotkey has been changed to: ⌃⌥

The change takes effect immediately. Try it now!

Press and hold ⌃⌥ to open Circle Launcher.

[OK]
```

## UserDefaults

**Key:** `hotkeyModifiers`
**Type:** String (rawValue des Enums)
**Default:** `"⌥⌘ (Option + Command)"`

### Beispiel:
```swift
UserDefaults.standard.string(forKey: "hotkeyModifiers")
// Returns: "⌥⌘ (Option + Command)"
```

## Features

### ✅ Vorteile

1. **Flexibilität** - 6 verschiedene Kombinationen
2. **Sofort wirksam** - Keine App-Neustart erforderlich
3. **Konflikt-Vermeidung** - Wenn Standard-Hotkey belegt ist
4. **User-Friendly** - Dropdown statt manuelle Eingabe
5. **Persistent** - Gespeichert in UserDefaults
6. **Visual Feedback** - Aktueller Hotkey prominent angezeigt

### 🎯 Anwendungsfälle

**Problem:** ⌥⌘ ist schon von anderer App belegt
**Lösung:** Wechsel zu ⌃⌥ oder einer anderen Kombination

**Problem:** Benutzer bevorzugt andere Modifier
**Lösung:** Freie Wahl aus 6 Optionen

**Problem:** Ergonomie - Rechts-/Linkshänder
**Lösung:** Verschiedene Kombinationen bieten unterschiedliche Hand-Positionen

## Technische Details

### Modifier Flags Mapping

```swift
NSEvent.ModifierFlags:
─────────────────────
.option    = Alt/Option Key
.command   = ⌘ Command Key
.control   = ⌃ Control Key
.shift     = ⇧ Shift Key

Kombinationen:
──────────────
[.option, .command]   → ⌥⌘
[.control, .option]   → ⌃⌥
[.control, .command]  → ⌃⌘
[.shift, .command]    → ⇧⌘
[.shift, .option]     → ⇧⌥
[.control, .shift]    → ⌃⇧
```

### Hotkey Detection

```swift
// AppDelegate.swift - registerGlobalHotkey()

NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
    if HotkeyManager.shared.matchesCurrentHotkey(event.modifierFlags) {
        // Öffnen
    } else {
        // Schließen
    }
}
```

### Thread Safety

Alle Hotkey-Operationen sind thread-safe:
- UserDefaults-Zugriff ist atomic
- HotkeyManager ist Singleton
- Event Monitors laufen auf Main Thread

## Testing

### Test-Szenarien

1. **Standard-Hotkey**
   - Drücke ⌥⌘ → Launcher öffnet

2. **Hotkey ändern**
   - Wechsel zu ⌃⌥ in Settings
   - Drücke ⌃⌥ → Launcher öffnet
   - Drücke ⌥⌘ → Nichts passiert ✅

3. **Persistence**
   - Ändere Hotkey
   - Beende App
   - Starte App neu
   - Neuer Hotkey sollte aktiv sein ✅

4. **Multi-Monitor**
   - Teste auf verschiedenen Bildschirmen
   - Hotkey sollte überall funktionieren ✅

### Verification Checklist

- [ ] Standard ⌥⌘ funktioniert
- [ ] Alle 6 Kombinationen funktionieren
- [ ] Hotkey-Wechsel sofort wirksam
- [ ] Alert wird angezeigt bei Änderung
- [ ] UserDefaults speichert korrekt
- [ ] Persistence nach Neustart
- [ ] UI zeigt aktuellen Hotkey
- [ ] Instructions aktualisieren sich

## Best Practices

### ✅ Do's

- Teste neue Hotkey-Kombination nach Änderung
- Wähle Kombination, die nicht von anderen Apps verwendet wird
- Nutze Standard ⌥⌘ wenn möglich (bewährt)

### ❌ Don'ts

- Verwende keine Kombination, die System-Shortcuts sind
- Wechsle nicht zu häufig (Gewöhnung)
- Vergiss nicht, neue Hotkey zu testen

## Known Conflicts

Mögliche Konflikte mit System/Apps:

| Hotkey | Möglicher Konflikt |
|--------|-------------------|
| ⌥⌘ | Selten - meist frei |
| ⌃⌥ | Selten - meist frei |
| ⌃⌘ | Spotlight (⌃⌘Space) |
| ⇧⌘ | Screenshot-Tools |
| ⇧⌥ | Selten - meist frei |
| ⌃⇧ | IDE-Shortcuts |

**Empfehlung:** ⌥⌘ (Standard) oder ⌃⌥ sind am sichersten

## Future Enhancements

Mögliche zukünftige Features:

- [ ] Custom Key + Modifier (z.B. ⌘F)
- [ ] Hotkey-Konflikt-Erkennung
- [ ] Hotkey-Test direkt in Settings
- [ ] Multiple Hotkeys gleichzeitig
- [ ] App-spezifische Hotkeys
- [ ] Gesture-Based Activation

## Changelog

### Version 1.0.0 (04.04.2026)
- ✅ Customizable Hotkey implementiert
- ✅ 6 Modifier-Kombinationen verfügbar
- ✅ HotkeyManager erstellt
- ✅ UI in Settings General Tab
- ✅ Sofortige Wirksamkeit
- ✅ UserDefaults Persistence
- ✅ Alert bei Änderung
- ✅ Dynamische Instructions

---

**Hotkey Customization ist vollständig! ⌨️**

Benutzer können jetzt ihren bevorzugten Hotkey wählen und Circle Launcher genau so steuern, wie sie es möchten!
