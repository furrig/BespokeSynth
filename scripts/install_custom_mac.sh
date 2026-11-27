#!/bin/bash
# Builds a self-contained Bespoke from this branch and installs it as
# "/Applications/BespokeSynth Custom.app", alongside the official BespokeSynth.app.
#
# Nothing is installed system-wide: python.org's Python 3.10.0 (the same one the official
# build bundles) is unpacked into ignore/python-3.10 and copied into the app by
# BESPOKE_PORTABLE. Everything else lives in ignore/build-app.
#
# usage: scripts/install_custom_mac.sh        (JOBS=<n> to change build parallelism, default 10)

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
JOBS="${JOBS:-10}"
BUILD_DIR="$REPO/ignore/build-app"
PY_DIR="$REPO/ignore/python-3.10"
PY_PKG_URL="https://www.python.org/ftp/python/3.10.0/python-3.10.0post2-macos11.pkg"
PY_FW="$PY_DIR/Python.framework/Versions/3.10"
APP_NAME="BespokeSynth Custom"
APP_ID="com.ryanchallinor.bespokesynth.custom"
DEST="/Applications/$APP_NAME.app"
export MACOSX_DEPLOYMENT_TARGET=13.0 # juceaide fails on the macOS 26 SDK without it

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

# --- 1. python.org Python 3.10.0, unpacked (not installed) -------------------------------
if [ ! -x "$PY_FW/bin/python3.10" ]; then
   step "Unpacking python.org Python 3.10.0 into ignore/python-3.10"
   mkdir -p "$PY_DIR"
   PKG="$PY_DIR/$(basename "$PY_PKG_URL")"
   [ -f "$PKG" ] || curl -fL -o "$PKG" "$PY_PKG_URL"
   pkgutil --check-signature "$PKG" | grep -q "Developer ID Installer: Ned Deily" \
      || { echo "unexpected signature on $PKG"; exit 1; }
   rm -rf "$PY_DIR/expanded" "$PY_DIR/Python.framework"
   pkgutil --expand-full "$PKG" "$PY_DIR/expanded"
   mv "$PY_DIR/expanded/Python_Framework.pkg/Payload" "$PY_DIR/Python.framework"
   rm -rf "$PY_DIR/expanded"
   chmod -R u+w "$PY_DIR/Python.framework"

   # the framework expects to live in /Library/Frameworks: point it at where it is now,
   # so the build can run it and BESPOKE_PORTABLE can relink it into the app
   OLD=/Library/Frameworks/Python.framework/Versions/3.10/Python
   install_name_tool -id "$PY_FW/Python" "$PY_FW/Python" 2>/dev/null
   for b in "$PY_FW/bin/python3.10" "$PY_FW/Resources/Python.app/Contents/MacOS/Python"; do
      install_name_tool -change "$OLD" "$PY_FW/Python" "$b" 2>/dev/null
   done
   for b in "$PY_FW/Python" "$PY_FW/bin/python3.10" "$PY_FW/Resources/Python.app/Contents/MacOS/Python"; do
      codesign -f -s - "$b" 2>/dev/null
   done
   "$PY_FW/bin/python3.10" -c "import sys; print('python', sys.version.split()[0], 'ok')"
fi

# --- 2. configure + build --------------------------------------------------------------
if [ ! -f "$BUILD_DIR/CMakeCache.txt" ]; then
   step "Configuring ignore/build-app"
   cmake -B "$BUILD_DIR" -S "$REPO" -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release \
      -DBESPOKE_PORTABLE=ON \
      -DBESPOKE_PYTHON_ROOT="$PY_FW" \
      -DPython_EXECUTABLE="$PY_FW/bin/python3.10"
fi

step "Building with -j$JOBS"
cmake --build "$BUILD_DIR" --config Release -j"$JOBS"

BUILT="$BUILD_DIR/Source/BespokeSynth_artefacts/Release/BespokeSynth.app"
[ -d "$BUILT/Contents/Frameworks/Python.framework" ] || { echo "Python was not bundled into $BUILT"; exit 1; }

# --- 3. install as "BespokeSynth Custom.app" -------------------------------------------
step "Installing $DEST"
STAGE="$(mktemp -d)/$APP_NAME.app"
ditto "$BUILT" "$STAGE"

# BESPOKE_PORTABLE relinks the bundled python executables without re-signing them, so on
# Apple Silicon they get killed at launch, and its ensurepip/pip install jedi steps fail
# silently. Re-sign them, then install jedi (script autocomplete) ourselves.
STAGE_PY="$STAGE/Contents/Frameworks/Python.framework/Versions/3.10"
install_name_tool -id /Library/Frameworks/Python.framework/Versions/3.10/Python "$STAGE_PY/Python" 2>/dev/null # same id as the official app
for b in "$STAGE_PY/Python" "$STAGE_PY/bin/python3.10" "$STAGE_PY/Resources/Python.app/Contents/MacOS/Python"; do
   codesign -f -s - "$b" 2>/dev/null
done
export PYTHONNOUSERSITE=1 # ignore ~/Library/Python/3.10, so packages land in the bundle
"$STAGE_PY/bin/python3.10" -m ensurepip --default-pip
# the bundled python has no working ssl (like the official app's), so it can't reach PyPI:
# fetch the same versions the official app ships with the system python, install them offline
WHEELS="$REPO/ignore/python-wheels"
if ! ls "$WHEELS"/jedi-*.whl "$WHEELS"/parso-*.whl >/dev/null 2>&1; then
   /usr/bin/python3 -m pip download --disable-pip-version-check --only-binary=:all: --no-deps --python-version 3.10 \
      -d "$WHEELS" jedi==0.20.0 parso==0.8.7
fi
"$STAGE_PY/bin/python3.10" -m pip install --disable-pip-version-check --no-warn-script-location \
   --no-index --find-links "$WHEELS" jedi==0.20.0
"$STAGE_PY/bin/python3.10" -c "import jedi, sys; assert jedi.__file__.startswith(sys.prefix), jedi.__file__; print('jedi', jedi.__version__, 'bundled ok')"

PLIST="$STAGE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$PLIST" 2>/dev/null \
   || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $APP_NAME" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $APP_ID" "$PLIST"

# editing Info.plist breaks the signature: re-sign the whole bundle ad-hoc
codesign --force --deep -s - "$STAGE"
codesign --verify --deep "$STAGE"

if pgrep -fq "$DEST/Contents/MacOS/"; then
   echo "$APP_NAME is running: quit it and run this script again"
   exit 1
fi
rm -rf "$DEST"
mv "$STAGE" "$DEST"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST"

step "Done: $DEST"
