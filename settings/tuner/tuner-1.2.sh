#!/bin/sh

tuner="tuner-1.2"
tmp_file="/tmp/$tuner"
settings_file="/etc/enigma2/settings"

echo "> Downloading diseqc 1.2 tuner config file ..."
wget -qO "$tmp_file" "https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/tuner/$tuner"

if [ ! -s "$tmp_file" ]; then
    echo "> Error: Failed to download tuner config file."
    exit 1
fi

echo "> Stopping Enigma2 to apply changes..."
# Gracefully stop Enigma2 across both systemd (DreamOS/Gemini) and SysVinit
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    systemctl stop enigma2
else
    init 4
fi
sleep 3

echo "> Installing diseqc 1.2 tuner settings ..."
# Modify settings while Enigma2 is completely stopped
sed -i '/config.Nims.0/d' "$settings_file"
grep "config.Nims.*" "$tmp_file" >> "$settings_file"
rm -f "$tmp_file" >/dev/null 2>&1

echo "> Starting Enigma2..."
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    systemctl start enigma2
else
    init 3
fi

echo
echo "> $tuner installed successfully"
echo "> Maintained By ElieSatpanelgrid team"
echo

exit 0
