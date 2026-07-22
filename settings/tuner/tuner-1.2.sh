#!/bin/sh

tuner=tuner-1.2

echo "> Downloading diseqc 1.2 tuner config file ..."
wget -qO /tmp/$tuner "https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/tuner/$tuner"

echo "> Installing diseqc 1.2 tuner settings ..."
    echo
    echo "> $tuner Channels Lists are installed successfully"
    echo "> Maintained By ElieSatpanelgrid team"
    sleep 2

# Check if systemd is available (DreamOS / Debian)
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    systemctl stop enigma2
    sleep 1
    
    # Modify settings while Enigma2 is stopped
    sed -i '/config.Nims.0/d' /etc/enigma2/settings
    grep "config.Nims.*" /tmp/$tuner >> /etc/enigma2/settings
    rm -f /tmp/$tuner >/dev/null 2>&1
    
    systemctl start enigma2
else
    # 1. Modify settings first
    sed -i '/config.Nims.0/d' /etc/enigma2/settings
    grep "config.Nims.*" /tmp/$tuner >> /etc/enigma2/settings
    rm -f /tmp/$tuner >/dev/null 2>&1
    
    # 4. Restart Enigma2 (init 4 -> init 3 forces clean reload without abrupt kill)
    init 4
    sleep 1
    init 3
fi

exit 0
