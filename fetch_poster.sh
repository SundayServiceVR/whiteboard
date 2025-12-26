#!/usr/bin/env bash
set -euo pipefail

# Usage: fetch_poster.sh <json_path> <output_file>
# Example: fetch_poster.sh ".lineup_poster_url" "lineup_poster.png"
# Example: fetch_poster.sh ".event.reconciled.host.host_poster_path" "host_poster.png"

if [ $# -ne 2 ]; then
  echo "Usage: $0 <json_path> <output_file>" >&2
  echo "Example: $0 '.lineup_poster_url' 'lineup_poster.png'" >&2
  exit 1
fi

JSON_PATH="$1"
OUTPUT_FILE="$2"
API_URL="https://nextevent-diczrrhb6a-uc.a.run.app/"
DEFAULT_POSTER="/assets/S4-Default-Normal.png"
TMP_FILE="${OUTPUT_FILE}_download"

echo "Fetching JSON from ${API_URL}..." >&2
json=$(curl -fsSL "${API_URL}")

# Extract poster URL using jq if available, otherwise use a simple sed/grep fallback
if command -v jq >/dev/null 2>&1; then
  poster_url=$(printf '%s' "${json}" | jq -r "${JSON_PATH}")
else
  # Fallback JSON parser: extract the last key name from the path
  field_name=$(echo "${JSON_PATH}" | sed 's/.*\.\([^.]*\)$/\1/')
  poster_url=$(printf '%s' "${json}" | sed -n "s/.*\"${field_name}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p")
fi

if [ -z "${poster_url:-}" ] || [ "${poster_url}" = "null" ]; then
  echo "Warning: ${JSON_PATH} not found in JSON, using default poster" >&2
  poster_url="${DEFAULT_POSTER}"
fi

echo "Downloading poster from ${poster_url}..." >&2
if ! curl -fsSL "${poster_url}" -o "${TMP_FILE}"; then
  echo "Error downloading poster, using default poster" >&2
  curl -fsSL "${DEFAULT_POSTER}" -o "${TMP_FILE}"
fi

if command -v convert >/dev/null 2>&1; then
  echo "Normalizing image to PNG using ImageMagick..." >&2
  # Force conversion to PNG regardless of input type
  convert "${TMP_FILE}" "${OUTPUT_FILE}"
  rm -f "${TMP_FILE}"
else
  echo "ImageMagick not found; using downloaded file as-is." >&2
  mv -f "${TMP_FILE}" "${OUTPUT_FILE}"
fi

echo "Saved poster to ${OUTPUT_FILE}" >&2
