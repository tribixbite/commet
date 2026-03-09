#!/data/data/com.termux/files/usr/bin/bash

# Commet - Build and Install Script for Termux ARM64
# Handles aapt2 compatibility (native ARM64 binary vs qemu wrapper)
# Usage: ./build-on-termux.sh [--release] [--install] [--clean]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_TYPE="debug"
INSTALL=false
CLEAN=""

for arg in "$@"; do
    case "$arg" in
        --release) BUILD_TYPE="release" ;;
        --install) INSTALL=true ;;
        --clean) CLEAN="clean" ;;
        *) echo "Usage: $0 [--release] [--install] [--clean]"; exit 1 ;;
    esac
done

echo "=== Commet Termux Build ==="
echo "  Type:  $BUILD_TYPE"
echo "  Java:  $(java -version 2>&1 | head -1)"

# --- Resolve aapt2 binary ---
# Priority: 1) bundled native ARM64  2) Termux pkg  3) fail
AAPT2_BUNDLED="$SCRIPT_DIR/tools/aapt2-arm64/aapt2"
if [ -x "$AAPT2_BUNDLED" ] && "$AAPT2_BUNDLED" version &>/dev/null; then
    AAPT2_BIN="$AAPT2_BUNDLED"
    echo "  AAPT2: $AAPT2_BIN (native ARM64)"
elif command -v aapt2 &>/dev/null && aapt2 version &>/dev/null 2>&1; then
    AAPT2_BIN="$(which aapt2)"
    echo "  AAPT2: $AAPT2_BIN (Termux pkg)"
else
    echo ""
    echo "Error: No working aapt2 found."
    echo "  Option 1: Place a static ARM64 aapt2 at tools/aapt2-arm64/aapt2"
    echo "  Option 2: pkg install aapt2  (requires qemu-x86_64 + x86_64 libs)"
    echo ""
    echo "  To get a native ARM64 aapt2, extract from an Android SDK build-tools"
    echo "  package for linux-aarch64, or build from AOSP source."
    exit 1
fi

# Verify gradle.properties has the right aapt2 path
GRADLE_PROPS="$SCRIPT_DIR/android/gradle.properties"
if ! grep -q "android.aapt2FromMavenOverride=$AAPT2_BIN" "$GRADLE_PROPS" 2>/dev/null; then
    echo "  Updating gradle.properties with aapt2 path..."
    sed -i "s|android.aapt2FromMavenOverride=.*|android.aapt2FromMavenOverride=$AAPT2_BIN|" "$GRADLE_PROPS"
fi

echo ""
echo "Building $BUILD_TYPE APK (arm64-v8a only)..."

# Flutter build with Termux-optimized settings
flutter build apk \
    --target-platform android-arm64 \
    --"$BUILD_TYPE" \
    2>&1 | tee "$SCRIPT_DIR/build-$BUILD_TYPE.log"

# Find output APK
APK_DIR="$SCRIPT_DIR/build/app/outputs/flutter-apk"
if [ "$BUILD_TYPE" = "release" ]; then
    APK="$APK_DIR/app-release.apk"
else
    APK="$APK_DIR/app-debug.apk"
fi

if [ -f "$APK" ]; then
    SIZE=$(du -h "$APK" | cut -f1)
    echo ""
    echo "=== BUILD SUCCESS ==="
    echo "  APK:  $APK ($SIZE)"

    if $INSTALL && command -v adb &>/dev/null; then
        echo ""
        echo "Installing via adb..."
        adb install -r "$APK"
        echo "Launching..."
        adb shell am start -n chat.commet.commetapp.debug/chat.commet.commetapp.MainActivity 2>/dev/null \
            || adb shell am start -n chat.commet.commetapp/chat.commet.commetapp.MainActivity 2>/dev/null \
            || echo "  (launch manually)"
    fi
else
    echo ""
    echo "=== BUILD FAILED ==="
    echo "Check build-$BUILD_TYPE.log for details"
    exit 1
fi
