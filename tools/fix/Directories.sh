#!/bin/sh

URL="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/tools/fix/Directories.pyc"
DEST="/usr/lib/enigma2/python/Tools"
FILE="Directories.pyc"
TMP="/tmp/$FILE"

echo "> Downloading and installing  $FILE please wait..."
sleep 3

if command -v wget >/dev/null 2>&1; then
    wget -q -O "$TMP" "$URL"
elif command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$TMP" "$URL"
else
    echo "Error: wget or curl is required."
    exit 1
fi

if [ ! -f "$TMP" ]; then
    echo "Download failed."
    exit 1
fi

mkdir -p "$DEST"

if [ -f "$DEST/$FILE" ]; then
    rm -f "$DEST/$FILE"
fi

mv -f "$TMP" "$DEST/$FILE"
chmod 644 "$DEST/$FILE"

sync

echo "> Done: $FILE updated successfully."
echo "> Restart E2 to apply changes..."
sleep 3