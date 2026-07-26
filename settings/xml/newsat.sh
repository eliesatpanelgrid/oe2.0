#!/bin/sh
file_path="/etc/tuxbox/satellites.xml"
url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/xml/newsat.xml"
file_path2="/etc/enigma2/satellites.xml"
if [ -f $file_path2 ]; then
echo "> Removing file old version please wait..."
sleep 3 
rm -rf $file_path2 > /dev/null 2>&1
fi

echo "> Downloading & Installing Satellites Frequencies File Please Wait..."
sleep 2

if command -v wget >/dev/null 2>&1; then
    wget -q --show-progress --no-check-certificate -O "$file_path" "$url"
else
    curl -L -k -o "$file_path" "$url"
fi

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