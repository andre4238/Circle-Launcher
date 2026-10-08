#!/bin/bash
# Builds the direct (.dmg) variant of Circle Launcher: configuration Release-Direct (licence-key
# check, network access), Developer ID signature, hardened runtime, notarised and stapled.
# Same flow as the StreamWriter Studio and Editavo PDF releases: sign by certificate hash,
# notarise with the keychain profile "streamwriter".
#
# Usage: Scripts/release_dmg.sh            (version from the Xcode project)
#        Scripts/release_dmg.sh 1.2.0      (override version)
# Result: ~/dmg_release/circle-launcher-<version>/CircleLauncher-<version>.dmg
#
# The App Store build is NOT made by this script (scheme "Circle Launcher", configuration Release).
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

HASH="140C5A3C2B15BF02A91F9BE097DB47B148899286"   # Developer ID Application (by hash because of the "é")
TEAM="XG5FB25GS8"
PROFILE="streamwriter"
PROJECT="Circle Launcher.xcodeproj"
SCHEME="Circle Launcher Direct"
SETTINGS=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release-Direct -showBuildSettings 2>/dev/null)
VER="${1:-$(echo "$SETTINGS" | awk -F' = ' '/^ *MARKETING_VERSION =/{print $2; exit}')}"
BUILD="${2:-$(echo "$SETTINGS" | awk -F' = ' '/^ *CURRENT_PROJECT_VERSION =/{print $2; exit}')}"
WORK="$HOME/dmg_release/circle-launcher-$VER"
DD="$WORK/DD"
APP="$DD/Build/Products/Release-Direct/CircleLauncher.app"
DMG="$WORK/CircleLauncher-$VER.dmg"

echo "▶ Circle Launcher $VER ($BUILD) – Direktvariante"
xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1 || { echo "FEHLER: Notarisierungs-Profil '$PROFILE' nicht nutzbar (Apple-Vertrag?)"; exit 1; }
rm -rf "$WORK"; mkdir -p "$WORK"

echo "▶ 1) xcodebuild build (Release-Direct)…"
xcodebuild build -project "$PROJECT" -scheme "$SCHEME" -configuration Release-Direct \
  -derivedDataPath "$DD" -destination 'generic/platform=macOS' -enableAddressSanitizer NO \
  CODE_SIGN_IDENTITY="$HASH" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="$TEAM" PROVISIONING_PROFILE_SPECIFIER="" \
  MARKETING_VERSION="$VER" CURRENT_PROJECT_VERSION="$BUILD" \
  2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | tail -20
[ -d "$APP" ] || { echo "FEHLER: App nicht gebaut"; exit 1; }
[ "$(defaults read "$APP/Contents/Info" CFBundleShortVersionString)" = "$VER" ] || { echo "FEHLER: Version im Bundle stimmt nicht"; exit 1; }
[ -z "$(find "$APP/Contents" -iname "*asan*" 2>/dev/null)" ] || { echo "FEHLER: Address Sanitizer im Release"; exit 1; }
# (grep direkt auf die Datei – eine Pipe mit grep -q würde unter pipefail fälschlich scheitern)
grep -aq "license.streamwriter.studio" "$APP/Contents/MacOS/CircleLauncher" || { echo "FEHLER: Lizenzprüfung fehlt im Programm (nicht mit DIRECT gebaut?)"; exit 1; }

echo "▶ 2) Inside-out signieren (Hardened Runtime, Zeitstempel)…"
codesign -d --entitlements - --xml "$APP" > "$WORK/app.entitlements" 2>/dev/null
/usr/libexec/PlistBuddy -c "Delete :com.apple.security.get-task-allow" "$WORK/app.entitlements" 2>/dev/null || true
[ "$(/usr/libexec/PlistBuddy -c "Print :com.apple.security.app-sandbox" "$WORK/app.entitlements" 2>/dev/null)" = "true" ] || { echo "FEHLER: Sandbox-Entitlement fehlt"; exit 1; }
[ "$(/usr/libexec/PlistBuddy -c "Print :com.apple.security.network.client" "$WORK/app.entitlements" 2>/dev/null)" = "true" ] || { echo "FEHLER: Netzwerk-Entitlement fehlt"; exit 1; }
find "$APP/Contents" \( -name "*.dylib" -o -name "*.framework" \) -print0 2>/dev/null | while IFS= read -r -d '' nested; do
  codesign --force --sign "$HASH" --timestamp --options runtime "$nested"
done
codesign --force --sign "$HASH" --timestamp --options runtime --entitlements "$WORK/app.entitlements" "$APP"
codesign --verify --deep --strict "$APP" && echo "  ✓ codesign verify OK"

echo "▶ 3) App notarisieren…"
ditto -c -k --keepParent "$APP" "$WORK/app.zip"
xcrun notarytool submit "$WORK/app.zip" --keychain-profile "$PROFILE" --wait 2>&1 | tee "$WORK/notary-app.log" | grep -E "id:|status:" | tail -3
grep -q "status: Accepted" "$WORK/notary-app.log" || { echo "FEHLER: App nicht notarisiert (Log: $WORK/notary-app.log)"; exit 1; }
xcrun stapler staple "$APP" >/dev/null && echo "  ✓ App gestapelt"

echo "▶ 4) DMG bauen…"
STAGE="$WORK/stage"; rm -rf "$STAGE"; mkdir -p "$STAGE"
ditto "$APP" "$STAGE/Circle Launcher.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Install Circle Launcher" -srcfolder "$STAGE" -ov -format UDZO -imagekey zlib-level=9 "$DMG" >/dev/null
rm -rf "$STAGE"
codesign --sign "$HASH" --timestamp "$DMG"

echo "▶ 5) DMG notarisieren + staplen…"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait 2>&1 | tee "$WORK/notary-dmg.log" | grep -E "id:|status:" | tail -3
grep -q "status: Accepted" "$WORK/notary-dmg.log" || { echo "FEHLER: DMG nicht notarisiert (Log: $WORK/notary-dmg.log)"; exit 1; }
xcrun stapler staple "$DMG" >/dev/null && echo "  ✓ DMG gestapelt"

echo "▶ 6) Finale Prüfung…"
spctl -a -t exec -vvv "$APP" 2>&1 | head -3
xcrun stapler validate "$DMG" | tail -1
spctl -a -t open --context context:primary-signature -vvv "$DMG" 2>&1 | head -2
rm -rf "$DD/Build/Intermediates.noindex" "$WORK/app.zip"
echo "✅ FERTIG: $DMG ($(du -h "$DMG" | cut -f1))"
