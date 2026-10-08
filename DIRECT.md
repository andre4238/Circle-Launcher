# Circle Launcher – Direktvariante (.dmg)

Neben der App-Store-Version gibt es eine Direktvariante für den Verkauf über a-systems.io. Beide entstehen aus
demselben Code; der Unterschied ist die Compiler-Bedingung `DIRECT`.

| | App Store | Direkt (.dmg) |
|---|---|---|
| Xcode-Schema | `Circle Launcher` | `Circle Launcher Direct` |
| Konfigurationen | `Debug`, `Release` | `Debug-Direct`, `Release-Direct` |
| Freischaltung | Kauf im App Store | Lizenzschlüssel (Lifetime, 1 Mac) |
| Netzwerk | keines | nur der Lizenzserver |
| Lizenzcode im Programm | nein | ja |

Der gesamte Lizenzcode steht in `#if DIRECT` (`Circle Launcher/Licensing/`). Die App-Store-Variante enthält davon
nichts – geprüft am Release-Build: keine Lizenzserver-Adresse im Programm, keine Netzwerkberechtigung.

## Verhalten der Direktvariante

- Start: Der im Schlüsselbund gespeicherte Schlüssel wird beim Lizenzserver bestätigt. Wurde er in den letzten
  14 Tagen bestätigt, ist die App sofort nutzbar (auch bevor das Netzwerk nach dem Anmelden steht); die Prüfung läuft
  dann im Hintergrund und sperrt die App wieder, falls der Server die Lizenz ablehnt.
- Ohne gültigen Schlüssel erscheint das Lizenzfenster. Es hat keinen Schließen-Knopf. Solange die App gesperrt ist,
  öffnen der Hotkey und „Settings...“ nur dieses Fenster; verlassen lässt es sich mit einem gültigen Schlüssel oder
  über „Quit“.
- Eingabe: Der Schlüssel wird validiert und dieser Mac als Gerät der Lizenz registriert. Ist die Lizenz schon auf
  einem anderen Mac aktiv, lehnt der Server ab.
- Settings → General → License → „Deactivate License on This Mac“ gibt die Lizenz für einen anderen Mac frei.
- Menü der Menüleiste: zusätzlicher Punkt „License...“.

Übertragen werden: Lizenzschlüssel, ein SHA-256-Hash der Hardware-UUID (die UUID selbst nicht) und der Gerätename.

## Lizenzserver

Der vorhandene Keygen-CE-Server (`license.streamwriter.studio`), der auch StreamWriter Studio und Editavo PDF bedient:

- Produkt `Circle Launcher` – `ec4ff285-95cd-4a21-8bae-73633ba79a3e`
- Richtlinie `Circle Launcher Lifetime` – `6e440612-07aa-4811-aa17-cc7b1f495f20` (kein Ablauf, 1 Gerät)

Es zählen nur Schlüssel dieser Richtlinie; Schlüssel anderer Produkte werden abgelehnt und nicht an den Mac gebunden.

Lizenzen erzeugen:

- Admin-Panel `https://license.streamwriter.studio/admin/` → Produkt **Circle Launcher** (Einzel-Lizenz oder Bundle).
  Für Circle Launcher versendet das Panel keine Schlüssel-Mail (die Mail-Vorlage ist die von StreamWriter).
- oder auf dem Server: `ssh root@212.227.215.194 /opt/keygen/circle-launcher/new-license.sh [Anzahl] [E-Mail]`

## Tests

```sh
xcodebuild test -project "Circle Launcher.xcodeproj" -scheme "Circle Launcher Direct" -only-testing:"Circle LauncherTests"
```

`LicenseTests` prüft die Lizenzlogik gegen einen nachgebildeten Server (Aktivierung, falsches Produkt, zweites Gerät,
Deaktivieren, Offline-Karenz, Sperren nach Widerruf, Lizenzfenster, Schlüsselbund).

Probe in der echten App gegen den echten Server (nur Debug-Direct; gibt das Ergebnis aus und beendet sich, der
Schlüssel bleibt nicht auf dem Mac gespeichert, wird aber auf dem Server an diesen Mac gebunden):

```sh
".../Debug-Direct/CircleLauncher.app/Contents/MacOS/CircleLauncher" -CircleAutoActivate <Schlüssel>
```

## DMG bauen

```sh
Scripts/release_dmg.sh            # Version aus dem Xcode-Projekt
```

Baut `Release-Direct`, signiert mit Developer ID (per Zertifikat-Hash), notarisiert über das Keychain-Profil
`streamwriter`, staplet und prüft mit Gatekeeper. Ergebnis:
`~/dmg_release/circle-launcher-<Version>/CircleLauncher-<Version>.dmg`.

Im Schema „Circle Launcher Direct“ ist der Address Sanitizer bewusst ausgeschaltet (er würde sonst mit in die App
gepackt). Jede veröffentlichte Version braucht einen neuen DMG-Dateinamen, weil Cloudflare `.dmg` pro Name cacht.

## Offen

- Die DMG liegt nur lokal; sie ist noch nicht auf dem Server und nicht auf der Website verlinkt.
- „Buy a License …“ im Lizenzfenster öffnet den Katalog `https://a-systems.io/en/software`
  (`LicenseServer.purchasePage`), bis es eine Produktseite für Circle Launcher gibt.
- Kein Update-Hinweis (Appcast) in der Direktvariante.
