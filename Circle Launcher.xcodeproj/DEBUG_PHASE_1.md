# SYSTEMATISCHES DEBUGGING - Schritt für Schritt

## 🔍 Phase 1: Diagnose - Was ist der genaue Zustand?

### Schritt 1: Alle Targets auflisten

**Bitte führen Sie aus und senden Sie mir die Ausgabe:**

1. Öffnen Sie Xcode
2. Klicken Sie auf Ihr **Projekt** (oberster Eintrag im Navigator)
3. Schauen Sie links unter **TARGETS**

**Frage an Sie:**
- Wie viele Targets sehen Sie?
- Welche Namen haben sie?

Bitte liste sie auf, z.B.:
```
1. CircleLauncher
2. CircleLauncherTests
3. CircleLauncherUITests
```

---

### Schritt 2: Alle Info.plist Dateien finden

**Öffnen Sie Terminal und führen Sie aus:**

```bash
# Navigieren Sie zu Ihrem Projektordner
cd /Pfad/zu/Ihrem/Circle-Launcher-Projekt

# Finden Sie alle Info.plist Dateien
find . -name "Info.plist" -o -name "*-Info.plist" | grep -v "DerivedData" | grep -v ".git"
```

**Frage an Sie:**
- Wie viele Info.plist Dateien werden gefunden?
- In welchen Ordnern liegen sie?

---

### Schritt 3: Inhalt ALLER Info.plist prüfen

Für **jede** gefundene Info.plist:

```bash
# Ersetzen Sie PFAD durch den Pfad aus Schritt 2
cat ./PFAD/Info.plist | grep -A1 "CFBundleIdentifier"
```

**Frage an Sie:**
- Welche zeigt `$(PRODUCT_BUNDLE_IDENTIFIER)`?
- Welche zeigt `com.andre.CircleLauncher`?

---

### Schritt 4: Build Settings prüfen

1. Wählen Sie Ihr **Haupt-Target** (CircleLauncher)
2. Gehen Sie zu **Build Settings**
3. Filter entfernen (alle Settings zeigen)
4. Suchen Sie nach:

**PRODUCT_NAME:**
- Was steht dort? (Bitte exakt kopieren)

**PRODUCT_BUNDLE_IDENTIFIER:**
- Was steht dort? (Bitte exakt kopieren)

**INFOPLIST_FILE:**
- Was steht dort? (Bitte exakt kopieren)

---

### Schritt 5: Scheme prüfen

1. **Product** → **Scheme** → **Edit Scheme...**
2. Gehen Sie zu **Build** Tab
3. Screenshot oder Liste aller Einträge

**Frage an Sie:**
- Welche Targets sind AKTIVIERT (Häkchen)?
- In welcher Reihenfolge?

---

## 🛠️ Phase 2: Bereinigung basierend auf Diagnose

**Warten Sie mit Phase 2, bis Sie mir die Ergebnisse von Phase 1 gegeben haben!**

Dann kann ich Ihnen **exakt** sagen, was zu tun ist.

---

## 📝 Bitte senden Sie mir:

1. ✅ Liste aller Targets (Namen)
2. ✅ Liste aller Info.plist Dateien (Pfade)
3. ✅ Welche Info.plist hat `$(PRODUCT_BUNDLE_IDENTIFIER)`?
4. ✅ PRODUCT_NAME Wert aus Build Settings
5. ✅ PRODUCT_BUNDLE_IDENTIFIER Wert aus Build Settings
6. ✅ INFOPLIST_FILE Wert aus Build Settings
7. ✅ Welche Targets sind im Scheme aktiviert?

Mit diesen Informationen kann ich Ihnen **genau** sagen, wo das Problem liegt!

---

## 🎯 Wichtig

Bitte führen Sie **nur Phase 1** aus und senden Sie mir die Ergebnisse.
Dann debuggen wir **gemeinsam** weiter mit den richtigen Informationen!
