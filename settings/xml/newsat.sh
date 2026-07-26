#!/bin/sh
file_path="/etc/tuxbox/satellites.xml"

echo "> Downloading & Installing Satellites Frequencies File Please Wait..."
sleep 3

if [ -f "$file_path" ]; then
    echo "> Removing old version please wait..."
    sleep 3
    rm -f "$file_path" > /dev/null 2>&1
fi

wget --show-progress -qO /etc/tuxbox/satellites.xml https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/xml/newsat.xml

echo
echo "> satellites.xml file installed successfully"
echo "> Maintained By ElieSatpanelgrid team"
echo
sleep 2