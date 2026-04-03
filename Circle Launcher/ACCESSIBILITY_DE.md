# Circle Launcher - Accessibility-Berechtigung einrichten

## 🔒 Problem: App erscheint nicht in den Einstellungen

Die App erscheint **erst** in den Accessibility-Einstellungen, **nachdem** sie versucht hat, auf Accessibility-Features zuzugreifen.

## ✅ Lösung (Schritt für Schritt)

### Schritt 1: App starten
1. Starten Sie Circle Launcher
2. Sie sehen eine Warnung über fehlende Accessibility-Berechtigung
3. **WICHTIG**: Klicken Sie auf "Später" (nicht auf "Systemeinstellungen öffnen" - noch nicht!)
4. Die App läuft jetzt und ist bei macOS registriert

### Schritt 2: Systemeinstellungen öffnen
1. Öffnen Sie **Systemeinstellungen** (oder **System Settings**)
2. Gehen Sie zu **Datenschutz & Sicherheit** (Privacy & Security)
3. Wählen Sie **Bedienungshilfen** (Accessibility) in der linken Spalte

### Schritt 3: App autorisieren
1. Klicken Sie auf das **Schloss-Symbol** 🔒 unten links
2. Geben Sie Ihr Passwort ein
3. **Jetzt sollte** "Circle Launcher" in der Liste erscheinen!
4. Falls nicht: Klicken Sie auf **+** und navigieren Sie zu Ihrer Circle Launcher.app
5. Aktivieren Sie das Kontrollkästchen ✅ neben Circle Launcher

### Schritt 4: App neu starten
1. Beenden Sie Circle Launcher (Menü-Symbol → "Quit Circle Launcher")
2. Starten Sie die App erneut
3. Fertig! ⌥Space sollte jetzt funktionieren!

## 🧪 Testen

Nach dem Neustart:
1. Klicken Sie irgendwo außerhalb der App
2. Drücken Sie **⌥Space** (Option + Leertaste)
3. Das radiale Menü sollte am Cursor erscheinen! 🎯

## 🐛 Troubleshooting

### Problem: App erscheint immer noch nicht in der Liste

**Lösung 1**: Manuell hinzufügen
1. Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen
2. Klicken Sie auf das Schloss 🔒
3. Klicken Sie auf **+** (Plus-Symbol)
4. Navigieren Sie zu Ihrer Circle Launcher.app:
   - Wahrscheinlich in `/Applications/`
   - Oder wo auch immer Sie die App gebaut haben
   - Im Xcode: `~/Library/Developer/Xcode/DerivedData/.../Products/Debug/Circle Launcher.app`
5. Wählen Sie die App aus und klicken Sie auf "Öffnen"
6. Aktivieren Sie das Kontrollkästchen

**Lösung 2**: Entwickler-Build-Pfad
Wenn Sie die App aus Xcode ausführen:
1. In Xcode: **Product** → **Show Build Folder in Finder**
2. Navigieren Sie zu: `Products/Debug/Circle Launcher.app`
3. Ziehen Sie diese App in die Accessibility-Liste

**Lösung 3**: App neu kompilieren
1. In Xcode: **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)
3. **Product** → **Run** (⌘R)
4. Die neue Warnung sollte erscheinen
5. Jetzt sollte die App in den Einstellungen erscheinen

### Problem: Hotkey funktioniert nicht

**Überprüfen Sie:**
```
1. Ist Circle Launcher in der Accessibility-Liste? ✅
2. Ist das Kontrollkästchen aktiviert? ✅
3. Haben Sie die App neu gestartet? ✅
4. Läuft die App? (Menü-Symbol im Menübereich sichtbar?) ✅
```

**Console-Log überprüfen:**
1. Öffnen Sie die **Console** App (Programme → Dienstprogramme → Konsole)
2. Filtern Sie nach "Circle Launcher"
3. Sie sollten sehen:
   - `✅ Accessibility permissions granted. Hotkey is active.` ← GUT!
   - `⚠️ Accessibility permissions not granted...` ← PROBLEM!

### Problem: Menü erscheint nicht

**Alternativer Test ohne Hotkey:**
1. Bearbeiten Sie `AppDelegate.swift`
2. Fügen Sie in `setupStatusBar()` hinzu:
```swift
menu.addItem(NSMenuItem(title: "Menü testen", action: #selector(toggleRadialMenu), keyEquivalent: "t"))
```
3. Neu kompilieren und ausführen
4. Klicken Sie auf das Menü-Symbol → "Menü testen"
5. Das Menü sollte erscheinen (auch ohne Accessibility-Berechtigung)

## 📱 Kontaktaufnahme

Wenn alles nicht funktioniert:

1. **Console.app** Log kopieren
2. **Systemeinstellungen** → Datenschutz & Sicherheit → Bedienungshilfen → Screenshot machen
3. Xcode-Version überprüfen: `xcodebuild -version`
4. macOS-Version überprüfen: **⌘** → Über diesen Mac

## 🎯 Alternative: Anderen Hotkey verwenden

Während Sie das Problem beheben, können Sie einen Menü-Hotkey verwenden:

In `AppDelegate.swift` → `setupStatusBar()`:
```swift
menu.addItem(NSMenuItem(title: "Launcher anzeigen", action: #selector(toggleRadialMenu), keyEquivalent: "l"))
```

Jetzt können Sie:
- **Menü-Symbol klicken** → "Launcher anzeigen" oder
- **⌘L drücken** (wenn das Menü offen ist)

## 📋 Zusammenfassung

Die wichtigsten Punkte:
1. ✅ Die App muss **einmal gestartet** werden, bevor sie in Accessibility erscheint
2. ✅ Sie müssen die App **nach** der Berechtigung **neu starten**
3. ✅ Bei Entwickler-Builds kann der Pfad kompliziert sein
4. ✅ Die Console.app zeigt hilfreiche Logs

## 🚀 Schnellhilfe-Checkliste

```
☐ App starten
☐ Warnung sehen (und auf "Später" klicken)
☐ Systemeinstellungen öffnen
☐ Datenschutz & Sicherheit → Bedienungshilfen
☐ Schloss öffnen 🔒
☐ Circle Launcher sollte nun in der Liste sein
☐ Kontrollkästchen aktivieren ✅
☐ App neu starten
☐ ⌥Space drücken
☐ Funktioniert! 🎉
```

Viel Erfolg! 🎯
