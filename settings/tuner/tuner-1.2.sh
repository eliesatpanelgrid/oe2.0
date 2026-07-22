#!/bin/sh

tuner=tuner-1.2

echo "> Downloading diseqc 1.2 tuner config file ..."
wget -qO /tmp/$tuner "https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/tuner/$tuner"

echo "> Installing diseqc 1.2 tuner settings ..."

# Check if systemd is available (DreamOS / Debian)
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    echo "> DreamOS detected. Stopping Enigma2..."
    systemctl stop enigma2
    sleep 2
    
    # Modify settings while Enigma2 is stopped
    sed -i '/config.Nims.0/d' /etc/enigma2/settings
    grep "config.Nims.*" /tmp/$tuner >> /etc/enigma2/settings
    rm -rf /tmp/$tuner > /dev/null 2>&1
    
    echo "> Restarting Enigma2..."
    systemctl start enigma2
else
    echo "> Open-source image detected..."
    # Kill Enigma2 dirty to prevent memory overwrite
    killall -9 enigma2
    sleep 1
    
    sed -i '/config.Nims.0/d' /etc/enigma2/settings
    grep "config.Nims.*" /tmp/$tuner >> /etc/enigma2/settings
    rm -rf /tmp/$tuner > /dev/null 2>&1
    
    echo "> Restarting Enigma2..."
    init 3
fi

exit 0
