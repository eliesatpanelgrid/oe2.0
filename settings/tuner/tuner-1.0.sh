#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/tuner/tuner-1.0.sh

tuner=tuner-1.0

echo "> Downloading diseqc 1.0 tuner config file ..."
wget -qO /tmp/$tuner "https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/tuner/$tuner"

echo "> Installing diseqc 1.0 tuner settings ..."

echo
    echo "> $tuner Channels Lists are installed successfully"
    echo "> Maintained By ElieSatpanelgrid team"
    echo
    sleep 2

# Check if running under systemd (DreamOS / Debian / OE-Alliance with systemd)
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    systemctl stop enigma2
    sleep 2
    
    # Modify settings safely while Enigma2 is offline
    sed -i '/config.Nims.0/d' /etc/enigma2/settings
    grep "config.Nims.*" /tmp/$tuner >> /etc/enigma2/settings
    rm -f /tmp/$tuner >/dev/null 2>&1
    
    echo
    echo "> $tuner Channels Lists are installed successfully"
    echo "> Maintained By ElieSatpanelgrid team"
    echo
    sleep 2
    
    systemctl start enigma2
else
    # Stop Enigma2 safely without overwriting settings
    init 4
    sleep 2
    
    sed -i '/config.Nims.0/d' /etc/enigma2/settings
    grep "config.Nims.*" /tmp/$tuner >> /etc/enigma2/settings
    rm -f /tmp/$tuner >/dev/null 2>&1
    
    echo
    echo "> $tuner Channels Lists are installed successfully"
    echo "> Maintained By ElieSatpanelgrid team"
    echo
    sleep 2
    
    init 3
fi

exit 0
