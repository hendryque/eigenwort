#!/bin/bash

# Records the film's clips and the README stills on the simulator. The app's
# DEBUG demo hooks drive every motion, so a re-record shows the same film.
# Needs Python with Pillow. Usage: Tools/film/record.sh ["iPhone 17 Pro"]
set -euo pipefail

NAME="${1:-iPhone 17 Pro}"
# By ID: a name can match a simulator whose runtime is gone as well.
SIM=$(xcrun simctl list devices available | /usr/bin/grep -F "    $NAME (" | /usr/bin/head -1 | /usr/bin/grep -oE '[0-9A-F-]{36}')
[ -n "$SIM" ] || { echo "No available simulator named $NAME" >&2; exit 1; }
BUNDLE="me.scott.folio"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FILM="$ROOT/Tools/film"
PUB="$FILM/public"
/bin/mkdir -p "$PUB/clips" "$PUB/stills" "$PUB/backdrops" "$PUB/fonts"

echo "Building for ${NAME}…"
cd "$ROOT/Folio"
xcodebuild -project Folio.xcodeproj -scheme Folio -configuration Debug -destination "id=$SIM" build >/dev/null
APP=$(xcodebuild -project Folio.xcodeproj -scheme Folio -configuration Debug -destination "id=$SIM" \
    -showBuildSettings 2>/dev/null | /usr/bin/awk '/ BUILT_PRODUCTS_DIR =/{print $3}' | /usr/bin/head -1)/Folio.app

xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" -b >/dev/null 2>&1 || true
xcrun simctl install "$SIM" "$APP"
xcrun simctl ui "$SIM" appearance light >/dev/null 2>&1 || true
# Nearby needs a place: the Met, on the edge of Central Park.
xcrun simctl privacy "$SIM" grant location "$BUNDLE" >/dev/null 2>&1 || true
xcrun simctl location "$SIM" set 40.7794,-73.9632 >/dev/null 2>&1 || true
xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --wifiBars 3 --dataNetwork wifi

# Always state the theme: the app keeps the last one used.
clip() {
    local name="$1" seconds="$2"; shift 2
    xcrun simctl terminate "$SIM" "$BUNDLE" >/dev/null 2>&1 || true
    xcrun simctl io "$SIM" recordVideo --codec=h264 --force "$PUB/clips/$name.mp4" >/dev/null 2>&1 &
    local recorder=$!
    sleep 1
    xcrun simctl launch "$SIM" "$BUNDLE" -screenshotFontScale 1 "$@" >/dev/null
    sleep "$seconds"
    kill -INT "$recorder"
    wait "$recorder" || true
    echo "  recorded $name"
}

still() {
    local name="$1"; shift
    xcrun simctl terminate "$SIM" "$BUNDLE" >/dev/null 2>&1 || true
    xcrun simctl launch "$SIM" "$BUNDLE" -screenshotFontScale 1 "$@" >/dev/null
    local n=0
    while [ $n -lt 100 ]; do
        xcrun simctl io "$SIM" screenshot "$PUB/stills/$name.png" >/dev/null 2>&1 || true
        n=$((n + 1))
    done
    echo "  captured $name"
}

DAY=(-screenshotTodayDate 2026-07-11)
# The tap waits until Today has prefetched its top articles, so the page opens at once.
clip today 13 -screenshotTheme light -screenshotTab today "${DAY[@]}" \
    -demoOpenArticle "Meurig ab Arthfael" -screenshotLanguage en -demoOpenAfter 7
clip nearby 12 -screenshotTheme light -screenshotTab nearby -demoSelectNearby 3 -demoSelectAfter 4
clip read 9 -screenshotTheme light -screenshotArticle Bauhaus -screenshotLanguage de \
    -screenshotScrollY 0 -demoScrollTo 1150 -demoScrollSeconds 4
clip themes 13 -screenshotTheme light -screenshotArticle "Metropolitan Museum of Art" -screenshotLanguage en \
    -screenshotScrollY 0 -demoCycleThemes 1.6

still today -screenshotTheme light -screenshotTab today "${DAY[@]}"
still typography -screenshotTheme light -screenshotArticle Bauhaus -screenshotLanguage de \
    -screenshotScrollY 1100 -screenshotReadDown 180
still debug -screenshotTheme debug -screenshotArticle "Metropolitan Museum of Art" -screenshotLanguage en \
    -screenshotScrollY 0
still gimmick -screenshotTheme gimmick -screenshotArticle "Metropolitan Museum of Art" -screenshotLanguage en \
    -screenshotScrollY 0
xcrun simctl launch "$SIM" "$BUNDLE" -screenshotTheme light >/dev/null 2>&1 || true
xcrun simctl status_bar "$SIM" clear

/usr/bin/env python3 "$FILM/backdrop.py" "$PUB/backdrops"
/bin/cp -f "$ROOT"/Folio/Resources/Fonts/EBGaramond-{Regular,Italic}.otf "$PUB/fonts/"
/bin/cp -f "$ROOT/Folio/Resources/Assets.xcassets/AppIcon.appiconset/icon-light.png" "$PUB/icon.png"
echo "Done. Render with: cd Tools/film && npm run film"
