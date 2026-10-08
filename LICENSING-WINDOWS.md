# Circle Launcher für Windows – Lizenzschlüssel-Abfrage (Anleitung für Claude Code)

**Auftrag:** Baue in die Windows-Version von Circle Launcher dieselbe Lizenzabfrage ein, die die macOS-Direktvariante hat.
Ohne gültigen Lizenzschlüssel darf die App nicht benutzbar sein. Eine Lizenz gilt dauerhaft (Lifetime) und für genau
**ein Gerät**.

Dieses Dokument beschreibt das Verhalten und die Server-Schnittstelle vollständig. Es ist unabhängig von Sprache und
UI-Framework der Windows-App geschrieben; die Referenz-Implementierung ist die Mac-App (Swift):

- `Circle Launcher/Licensing/LicenseService.swift` – Server-Aufrufe, Speicherung, Gerätekennung
- `Circle Launcher/Licensing/Licensing.swift` – Zustand (gesperrt / freigeschaltet)
- `Circle Launcher/Licensing/LicenseWindow.swift` – Lizenzfenster und Abschnitt „License“ der Einstellungen
- `Circle Launcher/AppDelegate.swift` – Einbindung in den App-Start (Abschnitte `#if DIRECT`)
- `Circle LauncherTests/LicenseTests.swift` – Tests, inklusive nachgebildetem Server
- `DIRECT.md` – Überblick über die Mac-Direktvariante

Die Beispiel-Antworten unten zeigen das echte Antwortformat des Servers (Stand 5. Oktober 2026); IDs einzelner
Lizenzen sind durch Platzhalter ersetzt.

---

## 1. Überblick

Der Lizenzserver ist ein selbst gehosteter **Keygen CE**. Er existiert bereits und wird **nicht** verändert. Die App
braucht kein Geheimnis: Sie authentifiziert sich ausschließlich mit dem Lizenzschlüssel, den der Kunde eingibt.

Feste Werte (in den Code der App übernehmen):

| Was | Wert |
|---|---|
| Basis-URL | `https://license.streamwriter.studio/v1/accounts/10a81245-58c2-4480-b8e8-8bc14427097e` |
| Produkt „Circle Launcher“ | `ec4ff285-95cd-4a21-8bae-73633ba79a3e` |
| Richtlinie „Circle Launcher Lifetime“ | `6e440612-07aa-4811-aa17-cc7b1f495f20` |
| Medientyp (Content-Type und Accept) | `application/vnd.api+json` |
| Timeout je Anfrage | 10 Sekunden |
| Offline-Karenz | 14 Tage |

Die Domain heißt `streamwriter.studio`, weil derselbe Server auch StreamWriter Studio bedient. Das ist richtig so.

**Niemals** einen Admin-Token, ein Passwort oder einen anderen Server-Schlüssel in die App einbauen. Die App braucht
keinen und darf keinen enthalten.

### Ablauf in einem Satz

Schlüssel validieren → falls dieses Gerät noch nicht registriert ist, registrieren → erneut validieren → bei `VALID`
Schlüssel speichern und App freischalten.

---

## 2. Server-Schnittstelle

Alle Anfragen: HTTPS, Header `Accept: application/vnd.api+json`. Bei Anfragen mit Body zusätzlich
`Content-Type: application/vnd.api+json`. Antworten nie cachen.

### 2.1 Validieren (ohne Authentifizierung)

```
POST {Basis}/licenses/actions/validate-key
```
```json
{ "meta": { "key": "<SCHLÜSSEL>",
            "scope": { "fingerprint": "<GERÄTEKENNUNG>",
                       "product": "ec4ff285-95cd-4a21-8bae-73633ba79a3e" } } }
```

Die Antwort hat immer HTTP 200. Entscheidend sind `meta.valid` (Bool) und `meta.code` (String).

Gültiger Schlüssel, aber dieses Gerät ist nicht registriert:
```json
{
  "data": {
    "id": "<LIZENZ-ID>",
    "type": "licenses",
    "attributes": { "key": "<SCHLÜSSEL>", "expiry": null, "status": "ACTIVE", "suspended": false, "maxMachines": 1 },
    "relationships": {
      "product": { "data": { "type": "products", "id": "ec4ff285-95cd-4a21-8bae-73633ba79a3e" } },
      "policy":  { "data": { "type": "policies", "id": "6e440612-07aa-4811-aa17-cc7b1f495f20" } }
    }
  },
  "meta": { "valid": false, "code": "FINGERPRINT_SCOPE_MISMATCH",
            "detail": "fingerprint is not activated (does not match any associated machines)" }
}
```

Unbekannter Schlüssel:
```json
{ "data": null, "meta": { "valid": false, "code": "NOT_FOUND", "detail": "does not exist" } }
```

Aus der Antwort lesen:

- `meta.valid`, `meta.code`
- `data.id` – die Lizenz-ID (wird zum Registrieren gebraucht); fehlt bei `NOT_FOUND`
- `data.relationships.policy.data.id` – die Richtlinie der Lizenz

### 2.2 Bedeutung von `meta.code`

| Code | Bedeutung | Was die App tut |
|---|---|---|
| `VALID` | Lizenz gilt für dieses Gerät | freischalten |
| `NO_MACHINE`, `NO_MACHINES` | Lizenz ist auf noch keinem Gerät aktiv | Gerät registrieren (2.3), erneut validieren |
| `FINGERPRINT_SCOPE_MISMATCH` | Lizenz ist aktiv, aber nicht auf diesem Gerät | Gerät registrieren (2.3) – der Server lehnt ab, wenn das Limit erreicht ist |
| `NOT_FOUND` | Schlüssel existiert nicht | Fehler „Schlüssel unbekannt“ |
| `PRODUCT_SCOPE_MISMATCH` | Schlüssel gehört zu einem anderen Produkt | Fehler „falsches Produkt“ |
| `SUSPENDED`, `BANNED` | Lizenz gesperrt | Fehler „gesperrt“ |
| `EXPIRED` | abgelaufen (kommt bei Lifetime nicht vor) | Fehler „abgelaufen“ |
| `TOO_MANY_MACHINES` | mehr Geräte als erlaubt | Fehler „bereits auf anderem Gerät“ |
| alles andere | unerwartet | Fehler mit dem Code im Text |

### 2.3 Gerät registrieren („aktivieren“)

```
POST {Basis}/machines
Authorization: License <SCHLÜSSEL>
```
```json
{ "data": {
    "type": "machines",
    "attributes": { "fingerprint": "<GERÄTEKENNUNG>", "platform": "Windows", "name": "<COMPUTERNAME>" },
    "relationships": { "license": { "data": { "type": "licenses", "id": "<LIZENZ-ID aus 2.1>" } } }
} }
```

| HTTP | Bedeutung | Was die App tut |
|---|---|---|
| 201 | registriert; `data.id` ist die Maschinen-ID | Maschinen-ID merken, erneut validieren |
| 422 mit Code, der `TAKEN`, `ALREADY` oder `CONFLICT` enthält | dieses Gerät ist schon registriert | als Erfolg werten, erneut validieren |
| 422 mit `MACHINE_LIMIT_EXCEEDED` | Lizenz ist schon auf einem anderen Gerät aktiv | Fehler „bereits auf anderem Gerät“ |
| 401 | Schlüssel wird nicht akzeptiert | Fehler „Schlüssel unbekannt“ |
| 5xx | Serverproblem | wie „Server nicht erreichbar“ behandeln |

Echte Antwort beim zweiten Gerät (HTTP 422):
```json
{ "errors": [ { "title": "Unprocessable resource",
                "detail": "machine count has exceeded maximum allowed for license (1)",
                "code": "MACHINE_LIMIT_EXCEEDED" } ] }
```
Die Fehlercodes stehen in `errors[].code`.

### 2.4 Gerät abmelden („deaktivieren“)

Damit der Kunde auf einen anderen Rechner umziehen kann.

1. Maschinen-ID bestimmen: die beim Registrieren gemerkte ID; falls nicht vorhanden, über die Liste:
   ```
   GET {Basis}/machines?license=<LIZENZ-ID>
   Authorization: License <SCHLÜSSEL>
   ```
   In `data[]` den Eintrag suchen, dessen `attributes.fingerprint` die eigene Gerätekennung ist; dessen `id` nehmen.
2. Löschen:
   ```
   DELETE {Basis}/machines/<MASCHINEN-ID>
   Authorization: License <SCHLÜSSEL>
   ```
   HTTP 200, 204 oder 404 gelten als Erfolg.
3. Erst **nach** Erfolg Schlüssel und Merkdaten lokal löschen und die App wieder sperren. Ist der Server nicht
   erreichbar, bleibt alles, wie es ist, und der Nutzer bekommt eine Fehlermeldung (sonst wäre die Lizenz weiter an das
   Gerät gebunden, obwohl die App sie vergessen hat).

---

## 3. Regeln der App

### 3.1 Nur Circle-Launcher-Schlüssel zählen (zwei Prüfungen)

1. Im Scope der Validierung immer `product` = Circle-Launcher-Produkt-ID senden. Der Server antwortet dann für fremde
   Schlüssel mit `PRODUCT_SCOPE_MISMATCH`.
2. Zusätzlich in der App prüfen: `data.relationships.policy.data.id` muss `6e440612-07aa-4811-aa17-cc7b1f495f20` sein.
   Ist die Richtlinie eine andere **oder fehlt sie**, gilt der Schlüssel als „falsches Produkt“ – auch wenn der Server
   `valid: true` meldet. Dann **nicht** registrieren (sonst würde ein fremder Schlüssel an dieses Gerät gebunden).

Hintergrund: Auf dem Server liegen auch die Lizenzen von StreamWriter Studio, StreamWriter YT und Editavo PDF. Diese Schlüssel dürfen
Circle Launcher nicht freischalten.

### 3.2 Gerätekennung (Fingerprint)

Eine stabile, anonyme Kennung des Rechners. Vorgabe für Windows:

1. `MachineGuid` lesen: Registry `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`, Wert `MachineGuid`.
   **In der 64-Bit-Ansicht lesen** (`KEY_WOW64_64KEY` bzw. `RegistryView.Registry64`), sonst liefert ein 32-Bit-Prozess
   nichts.
2. Kennung = SHA-256 über den UTF-8-Text `com.asystems.circlelauncher:<MachineGuid>`, als 64 Hex-Zeichen in Kleinbuchstaben.
3. Lässt sich die MachineGuid nicht lesen: einmalig eine zufällige UUID erzeugen, in den Einstellungen der App
   speichern und stattdessen verwenden.

Die rohe MachineGuid verlässt den Rechner nie; gesendet wird nur der Hash. Die Kennung muss über App-Updates und
Neustarts gleich bleiben – sonst hält der Server das Gerät für ein neues und lehnt wegen des Limits ab.

Als `name` den Computernamen senden (`COMPUTERNAME`), als `platform` den Text `Windows`.

Folge für Kunden: Eine Lizenz gilt für **ein** Gerät insgesamt. Wer sie auf dem Mac aktiviert hat, muss sie dort
deaktivieren, bevor sie unter Windows funktioniert – und umgekehrt.

### 3.3 Schlüssel-Eingabe bereinigen

Vor jeder Verwendung: in Großbuchstaben wandeln, alle Leerzeichen und Zeilenumbrüche entfernen und typografische
Striche durch `-` ersetzen (U+2010, U+2011, U+2012, U+2013, U+2014, U+2212). Mail-Programme und Textfelder machen aus
Bindestrichen gern Gedankenstriche. Ist das Ergebnis leer: Fehler „Bitte Schlüssel eingeben“, kein Server-Aufruf.

Form eines Schlüssels: `XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-V3` (Hex-Zeichen). Die Form **nicht** in der App erzwingen –
nur bereinigen und den Server entscheiden lassen.

### 3.4 Lokal speichern

| Was | Wo |
|---|---|
| Lizenzschlüssel | geschützt: Windows-Anmeldeinformationsverwaltung (Credential Manager, Ziel z. B. `com.asystems.circlelauncher.license`) oder per DPAPI (`CryptProtectData`, Benutzerbereich) verschlüsselte Datei. **Nicht** im Klartext in Registry oder Konfigurationsdatei. |
| Zeitpunkt der letzten Bestätigung durch den Server | normale App-Einstellungen |
| Maschinen-ID | normale App-Einstellungen |

Den Schlüssel erst speichern, **nachdem** der Server ihn mit `VALID` bestätigt hat.

### 3.5 Ablauf beim Start

```
kein Schlüssel gespeichert                → GESPERRT (Lizenzfenster, ohne Fehlermeldung)
Schlüssel gespeichert → bestätigen (3.6):
    VALID                                 → FREI; „letzte Bestätigung“ = jetzt
    Server nicht erreichbar:
        letzte Bestätigung ≤ 14 Tage her  → FREI (Offline-Karenz)
        sonst                             → GESPERRT, Meldung „Server nicht erreichbar“
    jede andere Antwort                   → GESPERRT, passende Meldung
```

„Nicht erreichbar“ heißt: Netzwerkfehler, Timeout, HTTP 5xx oder eine Antwort, die kein gültiges JSON mit `meta` ist.
Die Karenz gilt nur dafür. Sagt der Server ausdrücklich „ungültig“ (z. B. Lizenz gelöscht oder gesperrt), wird sofort
gesperrt – auch innerhalb der 14 Tage.

Ein Zeitpunkt der letzten Bestätigung, der in der Zukunft liegt (Systemuhr verstellt), zählt nicht als Karenz.

### 3.6 Bestätigen (gemeinsame Funktion für Start und Eingabe)

```
v = validieren(schlüssel)
wenn nicht v.valid und v.code ∈ {NO_MACHINE, NO_MACHINES, FINGERPRINT_SCOPE_MISMATCH} und v.lizenzId vorhanden:
    gerätRegistrieren(schlüssel, v.lizenzId)        // Fehler → Ergebnis ist dieser Fehler
    v = validieren(schlüssel)
wenn v.valid:
    letzteBestätigung = jetzt
    Ergebnis GÜLTIG
sonst:
    Ergebnis ABGELEHNT(v.code)
```

`validieren` enthält die Richtlinien-Prüfung aus 3.1: Bei fremder oder fehlender Richtlinie setzt es `valid = false` und
`code = WRONG_PRODUCT`. Dadurch wird für fremde Schlüssel nie registriert.

Die Selbstheilung beim Start ist gewollt: Wurde das Gerät serverseitig abgemeldet (z. B. vom Support), registriert die
App es beim nächsten Start neu, solange das Limit es erlaubt.

### 3.7 Eingabe eines Schlüssels

Bereinigen (3.3) → bestätigen (3.6) → bei GÜLTIG speichern und freischalten, sonst Fehlermeldung anzeigen und gesperrt
bleiben. Ohne Netzwerk kann kein neuer Schlüssel eingegeben werden (keine Karenz für nie bestätigte Schlüssel).

---

## 4. Lizenzfenster (Paywall)

Anforderungen – so verhält sich die Mac-App:

- Erscheint beim Start, wenn die App gesperrt ist, und nach dem Deaktivieren in den Einstellungen.
- **Lässt sich nicht schließen**: kein Schließen-Knopf, Alt+F4 und Esc schließen es nicht. Verlassen nur über einen
  gültigen Schlüssel oder den Knopf „Beenden“ (beendet die App).
- Solange die App gesperrt ist, funktioniert **nichts** vom Launcher: Die Tastenkombination öffnet das Kreismenü
  nicht, das Einstellungsfenster lässt sich nicht öffnen, und das Symbol im Infobereich (Tray) bietet nur
  „Lizenz eingeben …“ (holt das Lizenzfenster nach vorn) und „Beenden“. Die Sperre gehört an die Stelle, an der das
  Kreismenü geöffnet wird – nicht nur ins Fenster –, damit kein zweiter Weg (Hotkey, Tray, Autostart) daran vorbeiführt.
- Circle Launcher läuft im Hintergrund ohne Hauptfenster. Das Lizenzfenster muss deshalb selbst in den Vordergrund
  kommen (auch beim Autostart mit Windows) und in der Taskleiste sichtbar sein, sonst sieht der Kunde nur, dass die
  Tastenkombination „nicht geht“.
- Wird die Lizenz im laufenden Betrieb ungültig (Deaktivieren in den Einstellungen), ein offenes Kreismenü und das
  Einstellungsfenster schließen und das Lizenzfenster zeigen.
- Inhalt: App-Icon, Titel, kurzer Hinweis, Eingabefeld (Monospace-Schrift, keine Autokorrektur), Knopf „Aktivieren“
  (Standard-Knopf, Enter löst aus; deaktiviert bei leerem Feld und während der Prüfung), Fehlermeldung in Rot,
  Hinweistext zu Gerät und Datenübertragung, Knopf „Lizenz kaufen …“ (öffnet
  `https://a-systems.io/en/software/circle-launcher` im Browser), Knopf „Beenden“.
- Während der Prüfung: Fortschrittsanzeige im Knopf, Eingabefeld gesperrt, kein zweiter gleichzeitiger Versuch.
- Nach Erfolg schließt sich das Fenster von selbst und die App startet normal.

### ⚠️ Der Fehler, der auf dem Mac passiert ist – unbedingt vermeiden

In der ersten Mac-Version passierte beim Klick auf „Aktivieren“ **nichts**. Ursache: Das modale Fenster wurde so
gestartet, dass die App währenddessen keine asynchronen Aufgaben mehr ausführte – der Klick stieß die Prüfung an, sie
lief aber nie los.

Für Windows heißt das:

- Die Netzwerk-Anfrage **nie** synchron im UI-Thread ausführen und nie mit `.Result`/`.Wait()`/`GetAwaiter().GetResult()`
  auf sie warten (Deadlock bzw. eingefrorenes Fenster).
- Asynchron ausführen (`await`), und das Ergebnis über den normalen Weg des Frameworks zurück in den UI-Thread bringen.
- Sicherstellen, dass der modale Dialog die Nachrichtenschleife bzw. den Dispatcher weiterlaufen lässt.
- Das mit einem Test absichern, der **durch das offene, modale Fenster hindurch** aktiviert (siehe Abschnitt 7,
  Punkt 9). Ein Test nur der Lizenz-Logik hätte den Fehler nicht gefunden – genau das war auf dem Mac der Fall.

### ⚠️ Zweiter Fehler vom Mac: „Deaktivieren“ tat nichts

In der Mac-Version reagierte zunächst der Knopf „Lizenz deaktivieren“ in den Einstellungen nicht. Ursache: Der Knopf
rief die Funktion über einen Umweg auf (das zentrale App-Objekt), der zur Laufzeit ins Leere lief – ohne Fehlermeldung.

Für Windows heißt das:

- Der Knopf ruft die Lizenz-Logik **direkt** auf (eine zentrale Instanz, z. B. Singleton oder per Dependency Injection),
  nicht über Fenster- oder App-Objekte, die `null` sein können.
- Die Oberfläche **beobachtet** den Lizenzzustand (Ereignis/Observable): Wechselt er auf „gesperrt“, schließt sie
  Einstellungen und Kreismenü und zeigt das Lizenzfenster. Der Knopf selbst öffnet und schließt keine Fenster.
- Schlägt das Deaktivieren fehl (kein Netzwerk), erscheint die Meldung „Die Lizenz konnte nicht deaktiviert werden.“
- Mit einem Test absichern, der den Knopf in den echten Einstellungen auslöst (Abschnitt 7, Punkt 11).

---

## 5. Einstellungen

Ein Abschnitt „Lizenz“:

- der gespeicherte Schlüssel, maskiert: erste 4 und letzte 4 Zeichen, dazwischen „…“
- Hinweis: „Die Lizenz ist an dieses Gerät gebunden. Um sie auf einem anderen Gerät zu verwenden, deaktiviere sie hier
  zuerst.“
- Knopf „Lizenz auf diesem Gerät deaktivieren“ mit Sicherheitsabfrage → Ablauf 2.4 → danach erscheint wieder das
  Lizenzfenster.

---

## 6. Texte

Die Oberfläche der Mac-App ist nur englisch; die englische Spalte enthält ihre Texte wörtlich (statt „Mac“ steht hier
„device“). Die deutsche Spalte ist für den Fall gedacht, dass die Windows-App deutsch lokalisiert ist (Anrede: du):

| Fall | Deutsch | Englisch |
|---|---|---|
| Titel | Circle Launcher aktivieren | Activate Circle Launcher |
| Untertitel | Gib deinen Lizenzschlüssel ein, um Circle Launcher auf diesem PC zu verwenden. | Enter your license key to use Circle Launcher on this PC. |
| Platzhalter | Lizenzschlüssel | License key |
| Knopf | Aktivieren | Activate |
| Hinweis | Eine Lizenz gilt dauerhaft für ein Gerät. Für die Prüfung wird der Schlüssel zusammen mit einer anonymen Gerätekennung an den Lizenzserver gesendet. | A license is valid permanently for one device. To check it, the key is sent to the license server together with an anonymous device identifier. |
| Kaufen | Lizenz kaufen … | Buy a License … |
| Beenden | Beenden | Quit |
| leer | Bitte gib einen Lizenzschlüssel ein. | Please enter a license key. |
| `NOT_FOUND` | Dieser Lizenzschlüssel ist nicht bekannt. Bitte prüfe die Eingabe. | This license key is not known. Please check what you entered. |
| falsches Produkt | Dieser Lizenzschlüssel gehört zu einem anderen Produkt und gilt nicht für Circle Launcher. | This license key belongs to a different product and is not valid for Circle Launcher. |
| Gerätelimit | Diese Lizenz ist bereits auf einem anderen Gerät aktiviert. Deaktiviere sie dort in den Einstellungen oder wende dich an den Support. | This license is already activated on another device. Deactivate it there in Settings or contact support. |
| gesperrt | Diese Lizenz wurde gesperrt. Bitte wende dich an den Support. | This license has been suspended. Please contact support. |
| abgelaufen | Diese Lizenz ist abgelaufen. | This license has expired. |
| nicht erreichbar | Der Lizenzserver ist nicht erreichbar. Bitte prüfe die Internetverbindung und versuche es erneut. | The license server cannot be reached. Please check your internet connection and try again. |
| sonstiges | Die Lizenz konnte nicht bestätigt werden (%CODE%). | The license could not be confirmed (%CODE%). |

Zuordnung der Codes zu den Meldungen (Groß-/Kleinschreibung ignorieren, „enthält“-Vergleich):
`NOT_FOUND` → unbekannt · `PRODUCT_SCOPE`, `POLICY_SCOPE`, `WRONG_PRODUCT` → falsches Produkt ·
`TOO_MANY`, `MACHINE_LIMIT` → Gerätelimit · `SUSPENDED`, `BANNED` → gesperrt · `EXPIRED` → abgelaufen ·
sonst → sonstiges mit Code.

---

## 7. Tests (Pflicht)

Den Server in den automatisierten Tests **nachbilden** (HTTP-Schicht austauschbar machen), nicht den echten Server
benutzen. Speicher und Uhrzeit ebenfalls austauschbar machen. Mindestens diese Fälle:

1. Erste Aktivierung: validieren → `NO_MACHINES` → registrieren (201) → validieren → `VALID`. Schlüssel gespeichert,
   letzte Bestätigung gesetzt. Geprüft: Scope enthält `fingerprint` **und** `product`; die Validierung trägt keinen
   `Authorization`-Header; das Registrieren trägt `Authorization: License <Schlüssel>`.
2. Nächster Start: eine einzige Validierung, kein erneutes Registrieren.
3. Schlüssel eines anderen Produkts (fremde Richtlinie): abgelehnt als „falsches Produkt“, **kein** Registrieren,
   nichts gespeichert.
4. Unbekannter Schlüssel, leere Eingabe, gesperrte Lizenz: jeweils abgelehnt, nichts gespeichert.
5. Zweites Gerät mit demselben Schlüssel: `FINGERPRINT_SCOPE_MISMATCH` → Registrieren → 422 `MACHINE_LIMIT_EXCEEDED` →
   „Gerätelimit“.
6. Deaktivieren: Maschine gelöscht, Schlüssel vergessen; danach lässt sich derselbe Schlüssel auf einem anderen Gerät
   aktivieren. Ohne Netzwerk schlägt das Deaktivieren fehl und der Schlüssel bleibt gespeichert.
7. Offline: 13 Tage nach der letzten Bestätigung → frei; 15 Tage → gesperrt. Neuer Schlüssel ohne Netzwerk → abgelehnt.
   Lizenz serverseitig gelöscht → beim nächsten erreichbaren Start gesperrt, auch innerhalb der Karenz.
8. Eingabe mit Leerzeichen, Kleinbuchstaben und Gedankenstrichen wird akzeptiert.
9. **Durch das offene Lizenzfenster aktivieren:** Fenster modal öffnen, einen falschen Schlüssel absenden (Fenster
   bleibt offen, Fehlermeldung), dann den richtigen (Fenster schließt, App frei). Dieser Test muss fehlschlagen, wenn
   die Prüfung im modalen Zustand nicht ausgeführt wird.
10. Das Lizenzfenster hat keinen Schließen-Knopf und reagiert nicht auf Esc/Alt+F4. Solange die App gesperrt ist,
    öffnet die Tastenkombination das Kreismenü nicht.
11. **Deaktivieren über die Einstellungen:** In der freigeschalteten App den Knopf im Einstellungsfenster auslösen →
    Maschine auf dem (nachgebildeten) Server gelöscht, Einstellungen geschlossen, Lizenzfenster offen, Hotkey gesperrt.

Entwickler-Builds und Testläufe dürfen die Abfrage überspringen können (z. B. nur im Debug-Build über ein
Startargument und automatisch im Testlauf). Im Release-Build darf es **keinen** Weg an der Abfrage vorbei geben.

### Probe gegen den echten Server

Zum Schluss einmal von Hand mit einem echten Schlüssel prüfen (bindet den Schlüssel an den Test-PC):

- Lizenz erzeugen: Admin-Panel `https://license.streamwriter.studio/admin/` → Produkt **Circle Launcher**, oder auf dem
  Server `/opt/keygen/circle-launcher/new-license.sh`.
- In der fertigen, installierten App eingeben und aktivieren. Neustart: App bleibt frei.
- Denselben Schlüssel auf einem zweiten Gerät (oder dem Mac) eingeben: Meldung „bereits auf einem anderen Gerät“.
- In den Einstellungen deaktivieren, danach auf dem zweiten Gerät aktivieren: funktioniert.

**Keine Schlüssel echter Kunden zum Testen verwenden** und keine StreamWriter-Schlüssel „zur Probe“ validieren: Jede
Validierung schreibt auf dem Server einen Zeitstempel an die Lizenz.

---

## 8. Nicht Teil dieser Aufgabe

- Am Lizenzserver, am Admin-Panel oder an den Richtlinien wird nichts geändert. Die Windows-App nutzt dasselbe Produkt
  und dieselbe Richtlinie wie die Mac-App.
- Kein eigener Kauf in der App; „Lizenz kaufen …“ öffnet nur die Website.
- Kein Update-Hinweis (Appcast): Den hat auch die Mac-Version von Circle Launcher nicht.
- Der Kauf und der Versand der Schlüssel (Digistore o. Ä.) sind noch nicht eingerichtet; Schlüssel werden bis dahin von
  Hand im Admin-Panel erzeugt.

## 9. Datenschutz-Hinweis

An den Lizenzserver gehen: der Lizenzschlüssel, der Hash der Gerätekennung und der Computername. Das gehört in die
Datenschutzerklärung und – wie in der Mac-App – als kurzer Hinweis ins Lizenzfenster.
