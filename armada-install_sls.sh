#!/usr/bin/env bash
set -Eeuo pipefail
unset LD_AUDIT

LAUNCHER="/usr/libexec/armada/launch-steam"
LIB="$HOME/.local/share/SLSsteam/SLSsteam.so"
CONFIG="$HOME/.config/SLSsteam/config.yaml"
AUDIT='export LD_AUDIT="${HOME}/.local/share/SLSsteam/SLSsteam.so"'
EXEC='exec "${steam_arm}" \'

echo "=== SLSsteam ARM64 Installer ==="

# Find archive
ARCHIVE=""
for DIR in "$(dirname "$0")" "$HOME/Downloads" "/var/mnt/sdcard/Downloads"; do
    [[ -d "$DIR" ]] || continue
    ARCHIVE=$(find "$DIR" -maxdepth 3 -type f \
        -iname 'SLSsteam AArch64.7z' -print -quit 2>/dev/null || true)
    [[ -n "$ARCHIVE" ]] && break
done

[[ -n "$ARCHIVE" ]] || {
    echo "ERROR: SLSsteam AArch64.7z not found."
    exit 1
}

echo "Archive: $ARCHIVE"

# Find extractor
if command -v 7zz >/dev/null; then
    EXTRACTOR=7zz
elif command -v 7z >/dev/null; then
    EXTRACTOR=7z
elif command -v bsdtar >/dev/null; then
    EXTRACTOR=bsdtar
else
    echo "ERROR: Install 7z, 7zz or bsdtar first."
    exit 1
fi

# Extract to temporary directory
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [[ "$EXTRACTOR" == "bsdtar" ]]; then
    bsdtar -xf "$ARCHIVE" -C "$TMP"
else
    "$EXTRACTOR" x -y "-o$TMP" "$ARCHIVE" >/dev/null
fi

# Locate package files
SOURCE=$(find "$TMP" -type f \
    -path '*/bin/SLSsteam.so' -print -quit)

[[ -n "$SOURCE" ]] || {
    echo "ERROR: SLSsteam.so not found."
    exit 1
}

PACKAGE=$(dirname "$(dirname "$SOURCE")")
CONFIG_SOURCE="$PACKAGE/res/config.yaml"

[[ -s "$CONFIG_SOURCE" ]] || {
    echo "ERROR: config.yaml missing or empty."
    exit 1
}

file "$SOURCE" | grep -q 'ARM aarch64' || {
    echo "ERROR: Library is not AArch64."
    exit 1
}

# Install library
echo "Installing SLSsteam..."
mkdir -p "$(dirname "$LIB")"
install -m 755 "$SOURCE" "$LIB"

# Install configuration, preserving existing settings
mkdir -p "$(dirname "$CONFIG")"
if [[ ! -s "$CONFIG" ]]; then
    install -m 644 "$CONFIG_SOURCE" "$CONFIG"
else
    echo "Existing configuration preserved."
fi

# Check launcher before modifying
[[ -f "$LAUNCHER" ]] || {
    echo "ERROR: Armada launcher not found."
    exit 1
}

grep -Fqx "$EXEC" "$LAUNCHER" || {
    echo "ERROR: Expected Steam exec line not found. Launcher unchanged."
    exit 1
}

# Patch only if necessary
if sudo grep -Fqx "$AUDIT" "$LAUNCHER"; then
    echo "Launcher already configured."
else
    echo "Unlocking Armada..."
    sudo ostree admin unlock --hotfix

    BACKUP="$LAUNCHER.backup.$(date +%Y%m%d-%H%M%S)"
    sudo cp -a "$LAUNCHER" "$BACKUP"
    echo "Backup: $BACKUP"

    awk -v target="$EXEC" -v inject="$AUDIT" \
        '$0 == target {print inject} {print}' \
        "$LAUNCHER" > "$TMP/launcher.new"

    sudo tee "$LAUNCHER" < "$TMP/launcher.new" >/dev/null

    sudo grep -Fqx "$AUDIT" "$LAUNCHER" || {
        echo "ERROR: Launcher modification verification failed."
        exit 1
    }
fi

echo
echo "=== Installation complete ==="
file "$LIB"
sha256sum "$LIB"
ls -lh "$CONFIG"
sudo grep -n -B 2 -A 3 'LD_AUDIT' "$LAUNCHER"

echo "Restart Steam through Armada."
