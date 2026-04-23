#!/bin/sh

############################################
# Detect mounted storage (priority order)
############################################
STORAGE_PATHS="/media/hdd /media/usb /usr/share/enigma2"
MS=""

for path in $STORAGE_PATHS; do
    if [ -d "$path" ]; then
        MS="$path"
        echo "> Mounted storage found at: $MS"
        break
    fi
done

############################################
# Ensure picon directory exists
############################################
if [ -n "$MS" ] && [ ! -d "$MS/picon" ]; then
    mkdir -p "$MS/picon"
fi

echo
echo "> Downloading & installing picons please wait..."
sleep 1

############################################
# Package information
############################################
PLUGIN="picons"
VERSION="all"
ARCHIVE="${PLUGIN}-${VERSION}.tar.gz"
URL="https://github.com/eliesatpanelgrid/oe2.0/releases/download/picons-all/picons-all.tar.gz"
DEST="$MS/picon/$ARCHIVE"

############################################
# Download and extract
############################################
wget -q --show-progress --no-check-certificate -O "$DEST" "$URL"

tar -xzf "$DEST" -C "$MS/picon" >/dev/null 2>&1
EXTRACT_STATUS=$?

rm -f "$DEST" >/dev/null 2>&1

############################################
# Result
############################################
echo
if [ "$EXTRACT_STATUS" -eq 0 ]; then
    echo "> $PLUGIN-$VERSION package installed successfully"
else
    echo "> $PLUGIN-$VERSION package installation failed"
fi

sleep 3