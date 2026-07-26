#!/bin/sh
file_path="/etc/tuxbox/satellites.xml"
url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/xml/newsat.xml"

echo "> Downloading & Installing Satellites Frequencies File Please Wait..."
sleep 2

# Use curl if available (handles modern GitHub SSL better on Enigma2)
if command -v curl >/dev/null 2>&1; then
    curl -L -k -o "$file_path" "$url"
else
    # Fallback to wget without quiet mode to reveal errors
    wget --no-check-certificate -O "$file_path" "$url"
fi

# Check if file actually downloaded and isn't empty
if [ -s "$file_path" ]; then
    echo
    echo "> satellites.xml file is installed successfully"
    echo "> Maintained By ElieSatpanelgrid team"
    echo
else
    echo
    echo "> ERROR: Download failed or file is empty!"
    echo
fi

sleep 2