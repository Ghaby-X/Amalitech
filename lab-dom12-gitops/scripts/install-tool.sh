#!/usr/bin/env bash
# Downloads a release archive, verifies it against a SHA-256 pinned in the
# workflow (not one fetched from the same release, which would only catch
# corruption, not tampering), and unpacks it into <dest-dir>. A release that
# is a bare binary rather than an archive is installed as <binary-name>.
#
# Usage: install-tool.sh <url> <sha256> <dest-dir> [binary-name]
set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "usage: $0 <url> <sha256> <dest-dir> [binary-name]" >&2
  exit 2
fi

url="$1" sha256="$2" dest="$3" binary="${4:-}"
archive="$(mktemp -d)/$(basename "$url")"

curl --fail --silent --show-error --location --retry 3 --output "$archive" "$url"
echo "$sha256  $archive" | sha256sum --check --strict -

mkdir -p "$dest"
case "$archive" in
  *.tar.gz) tar -xzf "$archive" -C "$dest" ;;
  *.zip)    unzip -q "$archive" -d "$dest" ;;
  *)
    if [[ -z "$binary" ]]; then
      echo "error: $(basename "$url") isn't an archive - pass a binary name to install it as" >&2
      exit 1
    fi
    install -m 0755 "$archive" "$dest/$binary"
    ;;
esac
echo "installed $(basename "$url") into $dest"
