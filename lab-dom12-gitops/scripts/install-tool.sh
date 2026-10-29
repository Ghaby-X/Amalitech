#!/usr/bin/env bash
# Downloads a release archive, verifies it against a SHA-256 pinned in the
# workflow (not one fetched from the same release, which would only catch
# corruption, not tampering), and unpacks it into <dest-dir>.
#
# Usage: install-tool.sh <url> <sha256> <dest-dir>
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <url> <sha256> <dest-dir>" >&2
  exit 2
fi

url="$1" sha256="$2" dest="$3"
archive="$(mktemp -d)/$(basename "$url")"

curl --fail --silent --show-error --location --retry 3 --output "$archive" "$url"
echo "$sha256  $archive" | sha256sum --check --strict -

mkdir -p "$dest"
case "$archive" in
  *.tar.gz) tar -xzf "$archive" -C "$dest" ;;
  *.zip)    unzip -q "$archive" -d "$dest" ;;
  *)        echo "error: unsupported archive type: $archive" >&2; exit 1 ;;
esac
echo "installed $(basename "$url") into $dest"
