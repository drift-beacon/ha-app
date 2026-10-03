#!/bin/bash
set -euo pipefail

# Runs in the server's source tree and in the add-on repository; both carry the same copy.
usage() {
  echo "Usage: bump-server.sh set|s <version>"
  echo "       bump-server.sh increment|inc|i <major|maj|minor|min|patch|p>"
}

if [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$ROOT/Dockerfile" ] && [ -f "$ROOT/package.json" ]; then
  DOCKERFILE="$ROOT/Dockerfile"
  CONFIG_FILE="$ROOT/config.yaml"
  VERSION_FILE="$ROOT/package.json"
  REPOSITORY="source"
elif [ -f "$ROOT/drift-beacon/Dockerfile" ]; then
  DOCKERFILE="$ROOT/drift-beacon/Dockerfile"
  CONFIG_FILE="$ROOT/drift-beacon/config.yaml"
  REPOSITORY="add-on"
else
  echo "No Drift Beacon add-on packaging found under $ROOT" >&2
  exit 1
fi

CURRENT_VERSION="$(sed -n 's|^ARG SERVER_IMAGE=ghcr\.io/rshallam/drift-beacon-server:\(.*\)$|\1|p' "$DOCKERFILE")"
if ! [[ "$CURRENT_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Current server version must be MAJOR.MINOR.PATCH, got: ${CURRENT_VERSION:-<empty>}" >&2
  exit 1
fi
MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"

case "$1" in
  increment|inc|i)
    case "$2" in
      major|maj) VERSION="$((10#$MAJOR + 1)).0.0" ;;
      minor|min) VERSION="${MAJOR}.$((10#$MINOR + 1)).0" ;;
      patch|p) VERSION="${MAJOR}.${MINOR}.$((10#$PATCH + 1))" ;;
      *) echo "Invalid increment part: $2" >&2; usage; exit 1 ;;
    esac
    ;;
  set|s) VERSION="$2" ;;
  *) echo "Unknown command: $1" >&2; usage; exit 1 ;;
esac

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must be MAJOR.MINOR.PATCH, got: $VERSION" >&2
  exit 1
fi
# Validate every destination before changing any of them.
if ! grep -Eq '^version: "[0-9]+\.[0-9]+\.[0-9]+"$' "$CONFIG_FILE"; then
  echo "Could not find the add-on version in $CONFIG_FILE" >&2
  exit 1
fi
if [ "$REPOSITORY" = source ] && ! grep -Eq 'ghcr.io/rshallam/drift-beacon-server:[0-9]+\.[0-9]+\.[0-9]+' "$VERSION_FILE"; then
  echo "Could not find the artifact push tag in $VERSION_FILE" >&2
  exit 1
fi

# Portable across BSD and GNU sed, preserving existing file modes and formatting.
TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT
replace() {
  sed "$1" "$2" > "$TEMP_FILE"
  cat "$TEMP_FILE" > "$2"
}
replace "s|^ARG SERVER_IMAGE=.*|ARG SERVER_IMAGE=ghcr.io/rshallam/drift-beacon-server:${VERSION}|" "$DOCKERFILE"
replace "s|^version: .*|version: \"${VERSION}\"|" "$CONFIG_FILE"
if [ "$REPOSITORY" = source ]; then
  replace "s|ghcr.io/rshallam/drift-beacon-server:[^ \"]*|ghcr.io/rshallam/drift-beacon-server:${VERSION}|g" "$VERSION_FILE"
fi

echo "Bumped $REPOSITORY server and release metadata to ${VERSION}"
