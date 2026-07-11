#!/bin/bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <Tidy.app> <output.dmg> [volume name]" >&2
  exit 64
fi

app_path="$1"
output_path="$2"
volume_name="${3:-Tidy}"

if [[ ! -d "$app_path" ]]; then
  echo "App bundle not found: $app_path" >&2
  exit 66
fi

mkdir -p "$(dirname "$output_path")"
staging_directory="$(mktemp -d)"
trap 'rm -rf "$staging_directory"' EXIT

ditto "$app_path" "$staging_directory/Tidy.app"
ln -s /Applications "$staging_directory/Applications"

hdiutil create \
  -volname "$volume_name" \
  -srcfolder "$staging_directory" \
  -ov \
  -format UDZO \
  "$output_path"
