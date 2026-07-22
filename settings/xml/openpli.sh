#!/bin/sh
file_path="/etc/enigma2/satellites.xml"
echo "> Downloading & Installing Satellites Frequencies File Please Wait..."
sleep 3

if [ -f $file_path ]; then
echo "> Removing file old version please wait..."
sleep 3 
rm -rf $file_path > /dev/null 2>&1
fi

wget --show-progress -qO /etc/tuxbox/satellites.xml "https://raw.githubusercontent.com/OpenPLi/tuxbox-xml/master/xml/satellites.xml"

echo
    echo "> satellite.xml file is installed successfully"
    echo "> Maintained By ElieSatpanelgrid team"
    echo
    sleep 2