#!/bin/sh

tuner="tuner-1.1"
tmp_file="/tmp/$tuner"
settings_file="/etc/enigma2/settings"

echo "> Downloading diseqc 1.2 tuner config file ..."
wget -qO "$tmp_file" "https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/tuner/$tuner"

# Verify download was successful and non-empty
if [ ! -s "$tmp_file" ]; then
    echo "> Error: Failed to download tuner config file."
    exit 1
fi

echo "> Stopping Enigma2 to apply changes..."
# Gracefully stop Enigma2
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    systemctl stop enigma2.service
else
    init 4
fi

# Give process time to completely exit and release locks
sleep 3

echo "> Installing diseqc 1.2 tuner settings ..."
sed -i '/config.Nims.0/d' "$settings_file"
grep "config.Nims.*" "$tmp_file" >> "$settings_file"
rm -f "$tmp_file" >/dev/null 2>&1

echo "> Starting Enigma2..."
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    systemctl reset-failed enigma2.service >/dev/null 2>&1
    systemctl start enigma2.service
else
    init 3
fi

echo
echo "> $tuner installed successfully"
echo "> Maintained By ElieSatpanelgrid team"
echo
sleep 2

exit 0
