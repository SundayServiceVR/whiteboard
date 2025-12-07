#!/usr/bin/env bash
set -euo pipefail

API_URL="https://nextevent-diczrrhb6a-uc.a.run.app/"
OUTPUT_FILE="lineup_poster.png"
TMP_FILE="lineup_poster_download"

echo "Fetching JSON from ${API_URL}..." >&2
json=$(curl -fsSL "${API_URL}")

# Extract lineup_poster_url using jq if available, otherwise use a simple sed/grep fallback
if command -v jq >/dev/null 2>&1; then
  lineup_url=$(printf '%s' "${json}" | jq -r '.lineup_poster_url')
else
  # Very small/naive JSON parser: look for "lineup_poster_url":"..."
  lineup_url=$(printf '%s' "${json}" | sed -n 's/.*"lineup_poster_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

if [ -z "${lineup_url:-}" ] || [ "${lineup_url}" = "null" ]; then
  echo "Error: lineup_poster_url not found in JSON" >&2
  exit 1
fi

echo "Downloading lineup poster from ${lineup_url}..." >&2
curl -fsSL "${lineup_url}" -o "${TMP_FILE}"

if command -v convert >/dev/null 2>&1; then
  echo "Normalizing image to PNG using ImageMagick..." >&2
  # Force conversion to PNG regardless of input type
  convert "${TMP_FILE}" "${OUTPUT_FILE}"
  rm -f "${TMP_FILE}"
else
  echo "ImageMagick not found; using downloaded file as-is." >&2
  mv -f "${TMP_FILE}" "${OUTPUT_FILE}"
fi

echo "Saved lineup poster to ${OUTPUT_FILE}" >&2
