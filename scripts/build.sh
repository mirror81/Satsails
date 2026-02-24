#!/bin/bash
set -e

PACKAGE="com.satsails.Satsails"
APK_DEST="/home/andre/Documents/Satsails/build"
BUILD_MODE="debug"
UNINSTALL=false
PUBLISH=false

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --release) BUILD_MODE="release" ;;
    --debug)   BUILD_MODE="debug" ;;
    --publish)  PUBLISH=true ;;
    -u)        UNINSTALL=true ;;
  esac
done

cd "$(dirname "$0")/.."

if [ "$PUBLISH" = true ]; then
  # Increment versionCode in pubspec.yaml
  CURRENT_CODE=$(grep -oP '(?<=\+)\d+' pubspec.yaml | head -1)
  NEW_CODE=$((CURRENT_CODE + 1))
  sed -i "s/+${CURRENT_CODE}/+${NEW_CODE}/" pubspec.yaml
  echo "Version code incremented: $CURRENT_CODE -> $NEW_CODE"

  echo "Building App Bundle for publish..."
  flutter build appbundle --release

  AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
  mkdir -p "$APK_DEST"
  cp "$AAB_PATH" "$APK_DEST/"
  echo "AAB copied to $APK_DEST/app-release.aab"
  exit 0
fi

echo "Building $BUILD_MODE APK..."
flutter build apk --$BUILD_MODE

mkdir -p "$APK_DEST"
cp "build/app/outputs/flutter-apk/app-$BUILD_MODE.apk" "$APK_DEST/"

echo "$BUILD_MODE APK copied to $APK_DEST/app-$BUILD_MODE.apk"

if [ "$UNINSTALL" = true ]; then
  echo "Uninstalling $PACKAGE..."
  adb uninstall "$PACKAGE" || true
fi

echo "Installing APK..."
adb install -r "$APK_DEST/app-$BUILD_MODE.apk"
