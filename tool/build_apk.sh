#!/usr/bin/env bash
set -euo pipefail

build_mode="${1:-debug}"
case "$build_mode" in
  debug|release) ;;
  *)
    echo "Usage: FINIK_API_KEY=... FINIK_BETA=true|false $0 [debug|release]" >&2
    exit 2
    ;;
esac

if [[ -z "${FINIK_API_KEY:-}" ]]; then
  echo "FINIK_API_KEY is required. Refusing to build an APK without payments." >&2
  exit 2
fi

case "${FINIK_BETA:-}" in
  true|false) ;;
  *)
    echo "FINIK_BETA must be explicitly set to true or false." >&2
    exit 2
    ;;
esac

api_base_url="${DOGO_API_BASE_URL:-https://safabackend21.pythonanywhere.com/api/}"
item_name_en="${FINIK_ITEM_NAME_EN:-Safa delivery payment}"

echo "Building $build_mode APK"
echo "API: $api_base_url"
echo "Finik beta: $FINIK_BETA"

flutter pub get
flutter build apk "--$build_mode" \
  --dart-define="DOGO_API_BASE_URL=$api_base_url" \
  --dart-define="FINIK_API_KEY=$FINIK_API_KEY" \
  --dart-define="FINIK_BETA=$FINIK_BETA" \
  --dart-define="FINIK_ITEM_NAME_EN=$item_name_en"

echo "APK: build/app/outputs/flutter-apk/app-$build_mode.apk"
