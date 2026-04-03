# Feature: Einstellbare Circle-Größe

## ✨ Neue Funktion

Benutzer können jetzt die Größe des radialen Circles in den Einstellungen manuell anpassen!

---

## 🎯 Was wurde hinzugefügt

### 1. Neuer "Appearance" Tab in Settings

- ✅ TabView mit zwei Tabs: **Apps** und **Appearance**
- ✅ Slider zur Anpassung der Circle-Größe (60-150px Radius)
- ✅ Quick-Buttons: Small, Medium, Large, Extra Large
- ✅ Live-Vorschau der aktuellen Größe
- ✅ Reset-Button für Standard-Größe

### 2. UserDefaults Integration

- ✅ Einstellung wird automatisch gespeichert
- ✅ Einstellung überlebt App-Neustart
- ✅ Standard: 80px Radius (wie vorher)

### 3. Dynamische RadialMenuView

- ✅ Liest Größe aus UserDefaults
- ✅ Alle Größen proportional angepasst
- ✅ Funktioniert mit allen Radien (60-150px)

---

## 📱 Wie es aussieht

### Appearance Tab:

```
┌─────────────────────────────────────────┐
│ Appearance Settings                     │
│ Customize the look and size...          │
├─────────────────────────────────────────┤
│                                         │
│ Circle Size                    80 px   │
│ [----●--------------------------]       │
│                                         │
│ [Small] [Medium] [Large] [Extra Large] │
│                                         │
│ Adjust the radius of the circle where  │
│ app icons are positioned                │
│                                         │
│ ℹ️ Preview Info                         │
│ Current size: Small                     │
│ Total diameter: 240 px                  │
│                                         │
├─────────────────────────────────────────┤
│ 💡 Tip: Larger circles...    [Reset]   │
└─────────────────────────────────────────┘
```

---

## 🎛️ Einstellungen

### Radius-Bereich:
```
Minimum: 60px  (Extra Small)
Maximum: 150px (Extra Large)
Standard: 80px (Small)
Schritte: 5px
```

### Voreingestellte Größen:

| Button | Radius | Total Size | Beschreibung |
|--------|--------|------------|--------------|
| **Small** | 60px | 200×200 | Kompakt, für wenige Apps |
| **Medium** | 80px | 240×240 | Standard (default) |
| **Large** | 120px | 320×320 | Geräumig, für viele Apps |
| **Extra Large** | 150px | 380×380 | Maximum Platz |

---

## 🔧 Technische Details

### 1. SettingsView.swift

#### Neue Properties:
```swift
@AppStorage("circleRadius") private var circleRadius: Double = 80.0
```

#### Neuer Tab:
```swift
TabView {
    appsTab.tabItem { Label("Apps", systemImage: "app.badge") }
    appearanceTab.tabItem { Label("Appearance", systemImage: "slider.horizontal.3") }
}
```

#### Appearance Tab UI:
- Slider mit Wertebereich 60-150
- Quick-Select Buttons
- Live-Preview Info
- Reset Button

---

### 2. RadialMenuView.swift

#### Von static zu dynamic:
```swift
// VORHER (static)
private let radius: CGFloat = 80
private let centerCircleRadius: CGFloat = 30
private let itemSize: CGFloat = 50

// NACHHER (dynamic)
@AppStorage("circleRadius") private var circleRadius: Double = 80.0

private var centerCircleRadius: CGFloat {
    circleRadius * 0.375  // Proportional
}

private var itemSize: CGFloat {
    circleRadius * 0.625  // Proportional
}

private var frameSize: CGFloat {
    circleRadius * 3.75  // Proportional
}

private var backgroundSize: CGFloat {
    circleRadius * 2 + 80  // Blur-Ring
}
```

#### Proportionale Verhältnisse:
- `centerCircleRadius = radius × 0.375` (war 30/80)
- `itemSize = radius × 0.625` (war 50/80)
- `frameSize = radius × 3.75` (war 300/80)
- `backgroundSize = radius × 2 + 80`

---

### 3. AppDelegate.swift

#### Dynamische Panel-Größe:
```swift
private func setupRadialMenuPanel() {
    let circleRadius = UserDefaults.standard.double(forKey: "circleRadius")
    let radius = circleRadius > 0 ? circleRadius : 80.0
    let panelSize = radius * 3.75  // Gleiche Berechnung wie RadialMenuView
    
    let panel = RadialMenuPanel(
        contentRect: NSRect(x: 0, y: 0, width: panelSize, height: panelSize),
        // ...
    )
}
```

---

## 📊 Größen-Tabelle

| Radius | Center Circle | Item Size | Frame Size | Background |
|--------|---------------|-----------|------------|------------|
| 60px   | 22.5px        | 37.5px    | 225×225    | 200×200    |
| 80px   | 30px          | 50px      | 300×300    | 240×240    |
| 100px  | 37.5px        | 62.5px    | 375×375    | 280×280    |
| 120px  | 45px          | 75px      | 450×450    | 320×320    |
| 150px  | 56.25px       | 93.75px   | 562×562    | 380×380    |

---

## 🎨 Beschreibungen

Die Größe wird automatisch beschrieben:

```swift
private var sizeDescription: String {
    switch circleRadius {
    case ..<70:   return "Extra Small"
    case 70..<90: return "Small"
    case 90..<110: return "Medium"
    case 110..<130: return "Large"
    default:      return "Extra Large"
    }
}
```

---

## 🧪 Testing

### Test 1: Settings öffnen
```
1. ⌘R zum Starten
2. Menu Bar Icon klicken → Settings
3. "Appearance" Tab öffnen
✅ Slider sollte sichtbar sein
✅ Standard: 80px
```

### Test 2: Größe ändern
```
1. Appearance Tab öffnen
2. Slider auf 120px schieben
3. Settings schließen
4. ⌥⌘ drücken (Launcher öffnen)
✅ Menü sollte größer sein
```

### Test 3: Quick-Select Buttons
```
1. "Small" Button klicken → 60px
2. "Medium" Button klicken → 80px
3. "Large" Button klicken → 120px
4. "Extra Large" Button klicken → 150px
✅ Wert ändert sich sofort
```

### Test 4: Reset
```
1. Größe auf 150px ändern
2. "Reset to Default" Button klicken
✅ Sollte zurück auf 80px gehen
```

### Test 5: Persistenz
```
1. Größe auf 120px ändern
2. App beenden (⌘Q)
3. App neu starten
4. ⌥⌘ drücken
✅ Menü sollte immer noch 120px sein
```

---

## 💾 UserDefaults Key

```swift
Key: "circleRadius"
Type: Double
Default: 80.0
Range: 60.0 - 150.0
```

---

## 🎯 Verwendung

### Für Benutzer:

1. **Settings öffnen** (Menu Bar Icon → Settings)
2. **"Appearance" Tab** wählen
3. **Slider verschieben** oder Quick-Button klicken
4. **Änderung sofort sichtbar** beim nächsten Öffnen (⌥⌘)

### Tipps:
- 💡 **Small (60-80px)**: Gut für wenige Apps (3-6)
- 💡 **Medium (80-100px)**: Optimal für normale Nutzung (6-8 Apps)
- 💡 **Large (100-130px)**: Gut für viele Apps (8-10+)
- 💡 **Extra Large (130-150px)**: Maximum, für sehr viele Apps

---

## 📝 Geänderte Dateien

### 1. **SettingsView.swift**
- ✅ `@AppStorage("circleRadius")` hinzugefügt
- ✅ TabView mit Apps & Appearance
- ✅ `appsTab` View erstellt
- ✅ `appearanceTab` View erstellt
- ✅ `sizeDescription` computed property
- ✅ Slider mit Bereich 60-150
- ✅ Quick-Select Buttons
- ✅ Reset Button

### 2. **RadialMenuView.swift**
- ✅ `@AppStorage("circleRadius")` hinzugefügt
- ✅ Static `radius`, `centerCircleRadius`, `itemSize` entfernt
- ✅ Computed properties hinzugefügt (proportional)
- ✅ `frameSize` und `backgroundSize` computed
- ✅ Alle Berechnungen verwenden jetzt `circleRadius`

### 3. **AppDelegate.swift**
- ✅ `setupRadialMenuPanel()` liest aus UserDefaults
- ✅ Dynamische Panel-Größe basierend auf Einstellung

---

## 🔄 Proportionale Skalierung

Alle Elemente skalieren proportional:

```
Bei Radius = 80px (Standard):
- Center Circle = 30px (37.5%)
- Item Size = 50px (62.5%)
- Frame = 300×300 (375%)
- Background = 240×240

Bei Radius = 120px (Large):
- Center Circle = 45px (37.5%)
- Item Size = 75px (62.5%)
- Frame = 450×450 (375%)
- Background = 320×320

Alles bleibt proportional! ✅
```

---

## 🎨 UI-Details

### Slider:
- Thumb-Farbe: Accent Color
- Track: System Standard
- Live-Update beim Verschieben

### Quick Buttons:
- Style: `.bordered`
- Layout: Horizontal Stack
- Font: `.caption`
- Sofortige Wertänderung

### Info Section:
- Icon: `circle` SF Symbol
- Monospace Font für px-Werte
- Farbe: `.blue` für Hervorhebung

---

## 🚀 Vorteile

1. ✅ **Benutzerfreundlich**: Einfache Slider-Steuerung
2. ✅ **Flexibel**: Jeder Radius zwischen 60-150px
3. ✅ **Persistent**: Einstellung wird gespeichert
4. ✅ **Proportional**: Alles skaliert harmonisch
5. ✅ **Visual Feedback**: Live-Vorschau der Größe
6. ✅ **Quick Access**: Preset-Buttons für schnelle Änderung

---

## 🎯 Zusammenfassung

**Neue Features:**
- ✅ Appearance Tab in Settings
- ✅ Slider für Circle-Größe (60-150px)
- ✅ Quick-Select Buttons
- ✅ Live-Vorschau
- ✅ Reset-Button
- ✅ Persistente Speicherung
- ✅ Proportionale Skalierung

**Benutzer können jetzt:**
- 🎨 Circle-Größe selbst einstellen
- 🔄 Zwischen Presets wechseln
- 💾 Einstellung wird automatisch gespeichert
- 📏 Von mini (60px) bis riesig (150px)

**Perfekt für verschiedene Nutzungsszenarien!** 🚀✨

---

**Datum**: 03.04.26
**Status**: ✅ Vollständig implementiert und getestet
