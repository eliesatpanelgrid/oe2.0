#!/bin/sh

tuner=tuner-1.2

echo "> Downloading diseqc 1.2 tuner config file ..."
wget -qO /tmp/$tuner "https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/tuner/$tuner"

echo "> Installing diseqc 1.2 tuner settings ..."

# Check if systemd is available (DreamOS / Debian)
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    # DreamOS / Systemd handling
    systemctl stop enigma2
    sleep 1
    
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
    # Standard Enigma2 (OpenATV / OpenPLi / etc.)
    # 1. Stop Enigma2 clean to prevent overwrite
    init 4
    sleep 2
    
    # 2. Modify settings while stopped
    sed -i '/config.Nims.0/d' /etc/enigma2/settings
    grep "config.Nims.*" /tmp/$tuner >> /etc/enigma2/settings
    rm -f /tmp/$tuner >/dev/null 2>&1
    
    # 3. Print messages while GUI is down
    echo
    echo "> $tuner Channels Lists are installed successfully"
    echo "> Maintained By ElieSatpanelgrid team"
    echo
    sleep 2
    
    # 4. Restart Enigma2
    init 3
fi

exit 0
