# Launch at Login Feature

## Übersicht

Circle Launcher startet jetzt automatisch beim Systemstart. Diese Funktion wird beim ersten Start der App automatisch aktiviert und kann in den Einstellungen an/aus geschaltet werden.

## Features

✅ **Automatische Aktivierung** - Wird beim ersten Start automatisch eingeschaltet
✅ **Einstellbar** - Kann in Settings jederzeit an/aus geschaltet werden
✅ **Modern API** - Verwendet `ServiceManagement` Framework (macOS 13.0+)
✅ **Status-Anzeige** - Zeigt aktuellen Status in den Einstellungen
✅ **Genehmigungshinweise** - Leitet Benutzer zu Systemeinstellungen wenn Genehmigung benötigt wird

## Implementierung

### Dateien

1. **LaunchAtLoginManager.swift** (NEU)
   - Singleton-Manager für Launch at Login
   - Verwendet `SMAppService.mainApp` für macOS 13.0+
   - Automatische Aktivierung beim ersten Start
   - Status-Abfrage und Beschreibung

2. **SettingsView.swift** (ERWEITERT)
   - Neuer "General" Tab
   - Toggle für Launch at Login
   - Status-Anzeige
   - Link zu Systemeinstellungen bei Genehmigungsbedarf
   - Keyboard Shortcut Info
   - About-Sektion

3. **AppDelegate.swift** (ERWEITERT)
   - Ruft `LaunchAtLoginManager.shared.enableOnFirstLaunch()` beim Start auf

## Verwendung

### Für Benutzer

1. **Beim ersten Start**: Launch at Login wird automatisch aktiviert
2. **Einstellungen öffnen**: Klicke auf Menu Bar Icon → Settings
3. **General Tab**: Toggle "Launch at Login" an/aus
4. **Status prüfen**: Siehe Status-Anzeige unter dem Toggle

### Systemeinstellungen

Falls Genehmigung benötigt wird:
1. Öffne **Systemeinstellungen**
2. Gehe zu **Allgemein** → **Anmeldeobjekte**
3. Finde **Circle Launcher** in der Liste
4. Aktiviere es falls deaktiviert

## Technische Details

### ServiceManagement Framework

```swift
import ServiceManagement

// Status prüfen
SMAppService.mainApp.status // .enabled, .notRegistered, .requiresApproval, .notFound

// Registrieren
try SMAppService.mainApp.register()

// Deaktivieren
try SMAppService.mainApp.unregister()
```

### Mögliche Status

- **enabled**: ✅ Aktiviert und funktioniert
- **notRegistered**: Noch nicht registriert
- **requiresApproval**: ⚠️ Benötigt Benutzergenehmigung in Systemeinstellungen
- **notFound**: Fehler - App nicht gefunden

### UserDefaults Backup

Der Status wird zusätzlich in UserDefaults gespeichert:
- **Key**: `launchAtLogin`
- **Zweck**: Fallback und Tracking

Erster Start wird getrackt mit:
- **Key**: `hasLaunchedBefore`
- **Zweck**: Einmalige Auto-Aktivierung beim ersten Start

## UI Komponenten

### General Tab Struktur

```
┌─────────────────────────────────────┐
│ General Settings                    │
│ Configure app behavior...           │
├─────────────────────────────────────┤
│                                     │
│ Startup                             │
│ ┌─────────────────────────────────┐ │
│ │ [Toggle] Launch at Login        │ │
│ │ Automatically start...           │ │
│ │                                  │ │
│ │ Status: Aktiviert ✅             │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Keyboard Shortcuts                  │
│ ┌─────────────────────────────────┐ │
│ │ ⌨️  Global Hotkey               │ │
│ │     Press ⌥⌘                     │ │
│ │                                  │ │
│ │ How to use:                      │ │
│ │ • Press & Hold ⌥⌘                │ │
│ │ • Hover over your app            │ │
│ │ • Release keys to launch         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ About                               │
│ ┌─────────────────────────────────┐ │
│ │ ℹ️  About Circle Launcher       │ │
│ │ Version: 1.0.0                   │ │
│ │ Build: 1                         │ │
│ │ macOS: 13.0+                     │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Debugging

### Status prüfen

```swift
print(LaunchAtLoginManager.shared.statusDescription)
// Output: "Aktiviert ✅" oder "Benötigt Genehmigung ⚠️"
```

### Manuell aktivieren/deaktivieren

```swift
LaunchAtLoginManager.shared.isEnabled = true  // Aktivieren
LaunchAtLoginManager.shared.isEnabled = false // Deaktivieren
```

### Systemeinstellungen öffnen

```swift
LaunchAtLoginManager.shared.openLoginItemsSettings()
```

## Testing

### Erstes Start-Verhalten testen

1. Lösche UserDefaults:
   ```bash
   defaults delete com.yourcompany.Circle-Launcher hasLaunchedBefore
   ```

2. Starte App neu

3. Prüfe Console-Output:
   ```
   🎉 Erster Start erkannt - aktiviere Launch at Login
   ✅ Launch at login aktiviert
   ```

### Status testen

1. Öffne Settings → General Tab
2. Toggle Launch at Login an/aus
3. Prüfe Status-Anzeige
4. Checke in Systemeinstellungen → Allgemein → Anmeldeobjekte

## Migration

### Von alten Login Items APIs

Falls du vorher Legacy-APIs verwendet hast:

**Alt (deprecated):**
```swift
// SMLoginItemSetEnabled (deprecated in macOS 13.0)
SMLoginItemSetEnabled("com.example.helper" as CFString, true)
```

**Neu (modern):**
```swift
// ServiceManagement Framework
try SMAppService.mainApp.register()
```

## Troubleshooting

### Problem: Status zeigt "Requires Approval"

**Lösung:**
1. Öffne Systemeinstellungen → Allgemein → Anmeldeobjekte
2. Suche "Circle Launcher"
3. Falls nicht gefunden, starte App neu
4. Aktiviere den Eintrag

### Problem: App startet nicht bei Login

**Prüfe:**
1. Status in Settings → General
2. Eintrag in Systemeinstellungen → Anmeldeobjekte
3. Console.app für Fehlermeldungen
4. App wurde nicht manuell beendet beim letzten Logout

### Problem: Toggle funktioniert nicht

**Prüfe:**
1. macOS Version (13.0+ erforderlich)
2. App Sandbox Einstellungen
3. Console.app für Fehler

## Best Practices

✅ **DO:**
- Aktiviere automatisch beim ersten Start
- Zeige Status deutlich in UI
- Gebe hilfreiche Fehlerhinweise
- Leite zu Systemeinstellungen bei Problemen

❌ **DON'T:**
- Zwinge Benutzer zur Aktivierung
- Verstecke die Einstellung
- Zeige Fehler ohne Lösungsvorschläge
- Verwende deprecated APIs

## Zukünftige Erweiterungen

Mögliche zusätzliche Features:

- [ ] Verzögerten Start konfigurieren
- [ ] Start nur bei bestimmten Bedingungen
- [ ] Statistik: Wie oft wurde App über Login gestartet
- [ ] Benachrichtigung bei erfolgreichem Login-Start

## Changelog

### Version 1.0.0 (04.04.2026)
- ✅ Launch at Login implementiert
- ✅ Automatische Aktivierung beim ersten Start
- ✅ General Tab in Settings hinzugefügt
- ✅ Status-Anzeige und Genehmigungshinweise
- ✅ LaunchAtLoginManager Singleton erstellt

---

**Launch at Login ist jetzt vollständig implementiert! 🚀**
