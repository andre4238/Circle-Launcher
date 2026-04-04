# Appearance Customization - Icon Size & App Names

## Übersicht

Circle Launcher bietet jetzt umfassende Anpassungsmöglichkeiten für das Erscheinungsbild:

- ✅ **Circle Radius** - Abstand der Icons vom Zentrum (60-150 px)
- ✅ **Icon Size** - Größe der App-Icons (20-64 px)  ← NEU
- ✅ **Show App Names** - Namen ein/aus schalten  ← NEU

## Neue Features

### 1. Icon Size (Icon-Größe)

**Bereich:** 20-64 Pixel
**Standard:** 32 Pixel

#### Preset-Größen:
- **Small** (24 px) - Minimalistisch, mehr Platz
- **Medium** (32 px) - Standard, ausgewogen
- **Large** (48 px) - Gut lesbar, prominenter
- **Extra Large** (64 px) - Maximal sichtbar

#### Verwendung:
```swift
@AppStorage("iconSize") private var iconSize: Double = 32.0
```

Die Icon-Größe wird in `AppItemView` verwendet:
```swift
Image(nsImage: app.icon)
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: iconSize, height: iconSize)
```

### 2. Show App Names (Namen anzeigen)

**Typ:** Boolean Toggle
**Standard:** true (An)

#### Optionen:
- **✅ An** - Namen werden unter Icons angezeigt
- **❌ Aus** - Nur Icons, minimalistischer Look

#### Verwendung:
```swift
@AppStorage("showAppNames") private var showAppNames: Bool = true
```

Im `AppItemView`:
```swift
if showAppName {
    Text(app.name)
        .font(.caption2)
        .fontWeight(isHovered ? .bold : .semibold)
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.7), radius: 2)
        .lineLimit(1)
        .frame(maxWidth: 70)
}
```

## Implementation Details

### Geänderte Dateien

#### 1. RadialMenuView.swift
**Änderungen:**
- Neue `@AppStorage` Properties für `iconSize` und `showAppNames`
- Parameter an `AppItemView` weitergegeben
- Dynamische Anpassung der Icon-Größe

**Code:**
```swift
struct RadialMenuView: View {
    @AppStorage("circleRadius") private var circleRadius: Double = 80.0
    @AppStorage("iconSize") private var iconSize: Double = 32.0        // NEU
    @AppStorage("showAppNames") private var showAppNames: Bool = true  // NEU
    
    var body: some View {
        // ...
        AppItemView(
            app: app,
            isHovered: hoveredIndex == index,
            iconSize: iconSize,      // NEU
            showAppName: showAppNames // NEU
        )
    }
}
```

#### 2. AppItemView (in RadialMenuView.swift)
**Änderungen:**
- Neue Parameter `iconSize` und `showAppName`
- Dynamische Icon-Größe
- Bedingte Anzeige von App-Namen

**Code:**
```swift
struct AppItemView: View {
    let app: AppItem
    let isHovered: Bool
    let iconSize: Double      // NEU
    let showAppName: Bool     // NEU
    
    var body: some View {
        VStack(spacing: 3) {
            Image(nsImage: app.icon)
                .frame(width: iconSize, height: iconSize)  // Dynamisch
            
            if showAppName {  // Bedingt
                Text(app.name)
                    // ...
            }
        }
    }
}
```

#### 3. SettingsView.swift
**Änderungen:**
- Neue `@AppStorage` Properties
- Neue Sections im Appearance Tab:
  - Icon Size Section mit Slider und Presets
  - App Names Section mit Toggle
- Erweiterter "Reset All to Default" Button

**Code:**
```swift
struct SettingsView: View {
    @AppStorage("circleRadius") private var circleRadius: Double = 80.0
    @AppStorage("iconSize") private var iconSize: Double = 32.0        // NEU
    @AppStorage("showAppNames") private var showAppNames: Bool = true  // NEU
    
    // Appearance Tab erweitert mit:
    // - Icon Size Slider (20-64 px)
    // - Show App Names Toggle
}
```

## UI Layout - Appearance Tab

```
┌────────────────────────────────────────┐
│ Appearance Settings                    │
│ Customize the look and size...         │
├────────────────────────────────────────┤
│                                        │
│ Circle Radius                          │
│ ┌────────────────────────────────────┐ │
│ │ Circle Size              80 px     │ │
│ │ [Slider: 60───●───150]             │ │
│ │ [Small][Medium][Large][Extra Large]│ │
│ └────────────────────────────────────┘ │
│                                        │
│ Icon Size                         ← NEW│
│ ┌────────────────────────────────────┐ │
│ │ Icon Size                32 px     │ │
│ │ [Slider: 20───●───64]              │ │
│ │ [Small][Medium][Large][Extra Large]│ │
│ └────────────────────────────────────┘ │
│                                        │
│ App Names                         ← NEW│
│ ┌────────────────────────────────────┐ │
│ │ [Toggle] Show App Names            │ │
│ │ Display app names below icons      │ │
│ │                                    │ │
│ │ 📝 Names are visible               │ │
│ └────────────────────────────────────┘ │
│                                        │
│ Preview Info                           │
│ ┌────────────────────────────────────┐ │
│ │ Current size: Medium               │ │
│ │ Total diameter: 240 px             │ │
│ └────────────────────────────────────┘ │
├────────────────────────────────────────┤
│ 💡 Tip: Customize the look...          │
│                [Reset All to Default]  │
└────────────────────────────────────────┘
```

## Anwendungsfälle

### Minimalist Setup
```
Circle Radius: 60 px (Small)
Icon Size: 24 px (Small)
Show App Names: OFF
```
**Ergebnis:** Kompakt, clean, nur Icons

### Balanced Setup (Standard)
```
Circle Radius: 80 px (Medium)
Icon Size: 32 px (Medium)
Show App Names: ON
```
**Ergebnis:** Ausgewogen, gut lesbar

### Power User Setup
```
Circle Radius: 120 px (Large)
Icon Size: 48 px (Large)
Show App Names: ON
```
**Ergebnis:** Viel Platz, große Icons, optimal für viele Apps

### Accessibility Setup
```
Circle Radius: 150 px (Extra Large)
Icon Size: 64 px (Extra Large)
Show App Names: ON
```
**Ergebnis:** Maximum visibility, perfekt für Barrierefreiheit

## UserDefaults Keys

Alle Einstellungen werden in UserDefaults gespeichert:

| Key | Type | Default | Range |
|-----|------|---------|-------|
| `circleRadius` | Double | 80.0 | 60-150 |
| `iconSize` | Double | 32.0 | 20-64 |
| `showAppNames` | Bool | true | true/false |

## Testing

### Icon Size testen:
1. Öffne Settings → Appearance
2. Bewege Icon Size Slider
3. Öffne Launcher (⌥⌘)
4. Icons sollten neue Größe haben

### App Names testen:
1. Öffne Settings → Appearance
2. Toggle "Show App Names" aus
3. Öffne Launcher (⌥⌘)
4. Nur Icons sollten sichtbar sein (keine Namen)

### Kombinationen testen:
- Kleine Icons + Namen aus = Minimalist
- Große Icons + Namen an = Accessibility
- Medium alles = Balanced

## Performance

### Auswirkungen:
- ✅ **Icon Size**: Keine Performance-Auswirkung
- ✅ **Show App Names**: Minimal (Text-Rendering gespart wenn aus)
- ✅ **Alle Einstellungen**: Live ohne Neustart wirksam

### Memory:
- Größere Icons: Gleicher Memory (Icons werden scaled, nicht neu geladen)
- Namen ausblenden: Minimal weniger Memory

## Best Practices

### Do's ✅
- Teste verschiedene Kombinationen für deinen Workflow
- Nutze "Reset All to Default" bei Problemen
- Größere Icons bei vielen Apps für bessere Erkennbarkeit
- Namen ausblenden für cleanen Look bei wenigen, bekannten Apps

### Don'ts ❌
- Icon Size nicht zu klein (<24 px) - schwer zu treffen
- Icon Size nicht zu groß (>64 px) - Icons können pixelig werden
- Nicht zu viele Apps mit kleinem Circle Radius - überfüllt

## Zukünftige Erweiterungen

Mögliche zusätzliche Features:

- [ ] Custom Farben für Icons
- [ ] Icon-Stile (Rounded, Square)
- [ ] Schriftart für Namen
- [ ] Schriftgröße für Namen
- [ ] Schatten-Intensität anpassen
- [ ] Background-Blur-Stärke
- [ ] Animation-Geschwindigkeit
- [ ] Hover-Vergrößerungsfaktor

## Changelog

### Version 1.0.0 (04.04.2026)
- ✅ Icon Size Einstellung hinzugefügt (20-64 px)
- ✅ Show App Names Toggle hinzugefügt
- ✅ 4 Preset-Größen für Icons
- ✅ Live-Preview der Einstellungen
- ✅ "Reset All to Default" Button
- ✅ Status-Anzeige für Namen (visible/icons only)

---

**Appearance Customization ist jetzt vollständig! 🎨**

Nutzer können jetzt Circle Launcher vollständig an ihren Workflow anpassen!
