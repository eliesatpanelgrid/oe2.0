#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/tuner/tuner-1.3.sh

tuner=tuner-1.3
#Downloading tuner config file
echo "> Downloading diseqc 1.3 tuner config file ..."
sleep 3
wget -qO /tmp/$tuner "https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/tuner/$tuner"

#Setup the  tuner
echo "> Installing  diseqc 1.3 tuner settings ..."
sleep 3
echo "> your device will restart now please wait..."
sleep 1
sed -i '/config.Nims.0/d' /etc/enigma2/settings
grep "config.Nims.*" /tmp/$tuner >> /etc/enigma2/settings
rm -rf /tmp/$tuner > /dev/null 2>&1
sleep 1

# Restart Enigma2 service or kill enigma2 based on the system type
if [ -f /etc/apt/apt.conf ]; then
sleep 2
systemctl restart enigma2
else
sleep 2
killall -9 enigma2
fi
