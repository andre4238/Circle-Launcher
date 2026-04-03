# App als Background-Agent (kein Dock-Icon)

## ✅ Ihre App ist bereits korrekt konfiguriert!

Circle Launcher ist als **Background-Agent** eingerichtet und erscheint **NICHT im Dock** beim Starten.

---

## 🔧 Aktuelle Konfiguration

### In `Info.plist` steht:

```xml
<key>LSUIElement</key>
<true/>
```

**Das bedeutet:**
- ✅ **Kein Dock-Icon** beim Starten
- ✅ **Kein App-Icon in der Menu Bar** (nur Status Item)
- ✅ **Kein "Force Quit" über ⌘⌥⎋** (App erscheint nicht in Liste)
- ✅ **Läuft im Hintergrund** wie ein System-Tool
- ✅ **Perfekt für Launcher/Utility Apps**

---

## 🎯 Wie Ihre App funktioniert

### Beim Start:
1. App startet unsichtbar (kein Dock-Icon)
2. Menu Bar Icon erscheint (🔲 Grid-Symbol)
3. Globaler Hotkey (⌥⌘) wird registriert
4. App läuft im Hintergrund

### Sichtbare UI-Elemente:
- ✅ Menu Bar Status Item (oben rechts)
- ✅ Radiales Menü (bei ⌥⌘)
- ✅ Settings Window (über Menu Bar)

### NICHT sichtbar:
- ❌ Kein Dock-Icon
- ❌ Kein Hauptfenster
- ❌ Nicht in ⌘⇥ App-Switcher

---

## 📋 Alternative Optionen (falls gewünscht)

### Option 1: LSUIElement (aktuell) ✅ EMPFOHLEN

```xml
<key>LSUIElement</key>
<true/>
```

**Verhalten:**
- Kein Dock-Icon
- Nur Menu Bar Icon
- App im Hintergrund
- **Perfekt für Ihr Launcher!**

**Vorteile:**
- ✅ Unauffällig
- ✅ Läuft immer im Hintergrund
- ✅ Nimmt keinen Platz im Dock
- ✅ Professionell für Utility-Apps

---

### Option 2: LSBackgroundOnly (sehr versteckt)

```xml
<key>LSBackgroundOnly</key>
<true/>
```

**Verhalten:**
- Kein Dock-Icon
- KEIN Menu Bar Icon möglich
- Komplett unsichtbar
- **NICHT empfohlen** (keine UI mehr!)

**Nachteile:**
- ❌ Kein Menu Bar Icon
- ❌ Kein Zugriff auf Settings
- ❌ Nur über Hotkey nutzbar

---

### Option 3: Normaler App-Modus (sichtbar)

```xml
<key>LSUIElement</key>
<false/>
<!-- ODER einfach den Key entfernen -->
```

**Verhalten:**
- Dock-Icon erscheint
- In App-Switcher (⌘⇥)
- Normales App-Verhalten

**Nachteile:**
- ❌ Dock-Icon nimmt Platz weg
- ❌ Nicht ideal für Background-Launcher

---

## 🎨 Programmgesteuert Dock-Icon ändern (Advanced)

Falls Sie das Dock-Icon zur Laufzeit zeigen/verstecken möchten:

### In `AppDelegate.swift`:

```swift
// Dock-Icon VERSTECKEN
NSApp.setActivationPolicy(.accessory)
// ODER noch unsichtbarer:
NSApp.setActivationPolicy(.prohibited)

// Dock-Icon ANZEIGEN
NSApp.setActivationPolicy(.regular)
```

**Beispiel - Toggle beim Öffnen der Settings:**

```swift
@objc private func openSettings() {
    // Zeige Dock-Icon wenn Settings öffnen
    NSApp.setActivationPolicy(.regular)
    
    if settingsWindow == nil {
        // ... Settings erstellen ...
    }
    
    settingsWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}

// Verstecke Dock-Icon wenn Settings schließen
func windowWillClose(_ notification: Notification) {
    if let window = notification.object as? NSWindow, window === settingsWindow {
        settingsWindow = nil
        
        // Verstecke Dock-Icon wieder
        NSApp.setActivationPolicy(.accessory)
    }
}
```

**Aber**: Das ist kompliziert und meist unnötig!

---

## 🚀 Ihr aktuelles Setup (PERFEKT!)

### Info.plist:
```xml
<key>LSUIElement</key>
<true/>
```

### Verhalten:
- ✅ Kein Dock-Icon beim Start
- ✅ Menu Bar Icon vorhanden (🔲)
- ✅ Hotkey funktioniert (⌥⌘)
- ✅ Settings über Menu Bar erreichbar
- ✅ Professionell und unauffällig

### Perfekt für:
- ✅ Launcher
- ✅ Utility-Tools
- ✅ Background-Services
- ✅ Menu Bar Apps

---

## 🔍 Überprüfen der aktuellen Konfiguration

### In Xcode:

1. Öffnen Sie Ihr Target
2. Gehen Sie zum **Info** Tab
3. Suchen Sie nach: **Application is agent (UIElement)**
4. Sollte auf **YES** stehen

**Oder** in `Info.plist` Quellcode:

```xml
<key>LSUIElement</key>
<true/>
```

---

## 🧪 Testen

### Test 1: App starten
```
1. ⌘R in Xcode
2. App startet
✅ Kein Dock-Icon erscheint
✅ Nur Menu Bar Icon sichtbar (oben rechts)
```

### Test 2: App-Switcher
```
1. App läuft
2. Drücken Sie ⌘⇥ (App-Switcher)
✅ Circle Launcher erscheint NICHT in der Liste
```

### Test 3: Force Quit
```
1. Drücken Sie ⌘⌥⎋ (Force Quit)
✅ Circle Launcher erscheint NICHT in der Liste
```

### Test 4: Activity Monitor
```
1. Öffnen Sie Activity Monitor
2. Suchen Sie "Circle Launcher"
✅ Sollte als Prozess sichtbar sein
✅ Aber nicht als "Application" markiert
```

---

## 📝 Zusammenfassung

### Ihre aktuelle Konfiguration:

| Setting | Wert | Effekt |
|---------|------|--------|
| **LSUIElement** | `true` | Kein Dock-Icon ✅ |
| **Menu Bar Icon** | Ja | Status Item sichtbar ✅ |
| **Hotkey** | ⌥⌘ | Funktioniert ✅ |
| **Settings** | Via Menu | Erreichbar ✅ |

### Verhalten:

```
Start → Kein Dock-Icon → Nur Menu Bar Icon → Läuft im Hintergrund
         ✅                ✅                    ✅
```

---

## 💡 Häufige Fragen

### Q: Warum erscheint manchmal doch ein Dock-Icon?

**A:** Mögliche Ursachen:
1. ❌ LSUIElement ist nicht `true` in Info.plist
2. ❌ Info.plist wird nicht geladen (Build Settings prüfen)
3. ❌ Xcode cached alte Version (Clean Build!)

**Lösung:**
```
1. Info.plist prüfen: LSUIElement = true
2. Product → Clean Build Folder (⇧⌘K)
3. Product → Run (⌘R)
```

---

### Q: Kann ich das Dock-Icon temporär anzeigen?

**A:** Ja, mit:
```swift
NSApp.setActivationPolicy(.regular)  // Zeigen
NSApp.setActivationPolicy(.accessory)  // Verstecken
```

Aber meist unnötig!

---

### Q: Wie beende ich die App ohne Dock-Icon?

**A:** Mehrere Möglichkeiten:
1. ✅ Menu Bar Icon → Quit
2. ✅ Activity Monitor → Circle Launcher → Quit
3. ✅ Terminal: `killall "Circle Launcher"`
4. ✅ Xcode Stop Button (⌘.)

---

### Q: Ist das der Standard für Launcher-Apps?

**A:** Ja! Viele professionelle Tools nutzen das:
- ✅ Alfred
- ✅ Raycast
- ✅ Spotlight (System)
- ✅ Bartender
- ✅ Rectangle

Alle ohne Dock-Icon!

---

## ✅ Bestätigung

**Ihre App ist korrekt konfiguriert!**

- ✅ `LSUIElement = true` ist die richtige Einstellung
- ✅ Kein Dock-Icon ist gewollt und professionell
- ✅ Menu Bar Icon für Zugriff vorhanden
- ✅ Perfekt für einen Launcher wie Circle Launcher!

**Sie müssen NICHTS ändern!** 🎉

---

## 🔄 Falls Sie es DOCH im Dock wollen (nicht empfohlen)

### In Info.plist ändern:

```xml
<!-- ALT - Kein Dock-Icon -->
<key>LSUIElement</key>
<true/>

<!-- NEU - Mit Dock-Icon -->
<key>LSUIElement</key>
<false/>
```

**Oder** die Zeile komplett entfernen.

**Aber**: Das ist untypisch für Launcher-Apps!

---

## 🎯 Empfehlung

**Behalten Sie die aktuelle Konfiguration!**

```xml
<key>LSUIElement</key>
<true/>
```

Das ist:
- ✅ Standard für Launcher-Apps
- ✅ Professionell
- ✅ Unauffällig
- ✅ Benutzerfreundlich (nimmt keinen Dock-Platz)

---

**Alles ist perfekt eingerichtet!** ✨

Ihre App verhält sich genau so, wie ein moderner macOS Launcher sollte:
- Unsichtbar im Hintergrund
- Erreichbar über Hotkey (⌥⌘)
- Settings über Menu Bar
- Kein überflüssiges Dock-Icon

👍 Gut gemacht!
