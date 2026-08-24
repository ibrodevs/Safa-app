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
preflight_url="${api_base_url%/}/payments/finik/config/"

echo "Building $build_mode APK"
echo "API: $api_base_url"
echo "Finik beta: $FINIK_BETA"

python3 - "$preflight_url" "$FINIK_BETA" "$FINIK_API_KEY" <<'PY'
import hashlib
import json
import sys
import urllib.request

url, expected_beta_raw, api_key = sys.argv[1:]
expected_beta = expected_beta_raw == "true"
try:
    # Cloudflare rejects Python urllib's default User-Agent with error 1010.
    # Identify this as the Safa build preflight while keeping the request
    # read-only and explicitly asking for the JSON configuration endpoint.
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0 SafaBuild/1.0",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=15) as response:
        config = json.load(response)
except Exception as exc:
    raise SystemExit(f"Finik backend preflight failed ({url}): {exc}")

expected_fingerprint = hashlib.sha256(api_key.encode()).hexdigest()[:16]
problems = []
purposes = set(config.get("paymentPurposes") or [])
if int(config.get("paymentFlowVersion") or 0) < 3:
    problems.append("backend payment flow is outdated")
if not {"shipment", "amanat"}.issubset(purposes):
    problems.append("backend does not support every Finik payment purpose")
if config.get("configured") is not True:
    problems.append("Finik is not configured on backend")
if config.get("beta") is not expected_beta:
    problems.append("FINIK_BETA differs between APK and backend")
if not expected_beta and config.get("testAmount") is not None:
    problems.append("production backend still uses FINIK_TEST_AMOUNT")
if config.get("keyFingerprint") != expected_fingerprint:
    problems.append("FINIK_API_KEY differs between APK and backend")
if not str(config.get("callbackUrl") or "").startswith("https://"):
    problems.append("backend callbackUrl is not public HTTPS")
if problems:
    raise SystemExit("Finik backend preflight failed: " + "; ".join(problems))

print("Finik backend preflight: OK")
PY

flutter pub get
flutter build apk "--$build_mode" \
  --dart-define="DOGO_API_BASE_URL=$api_base_url" \
  --dart-define="FINIK_API_KEY=$FINIK_API_KEY" \
  --dart-define="FINIK_BETA=$FINIK_BETA" \
  --dart-define="FINIK_ITEM_NAME_EN=$item_name_en"

echo "APK: build/app/outputs/flutter-apk/app-$build_mode.apk"
shasum -a 256 "build/app/outputs/flutter-apk/app-$build_mode.apk"
