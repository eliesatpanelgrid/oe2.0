#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/motor/saleh-motor.sh


#configuration
#######################################
motor=saleh-motor
targz_file=$motor.tar.gz
url=https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/motor/$targz_file

# Remove unnecessary files and folders
#######################################
[ -d "/CONTROL" ] && rm -r /CONTROL >/dev/null 2>&1
rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1

# Downloading channels lists file
#######################################
echo "> Downloading "$motor" Channels Lists  Please Wait ..."
sleep 3
wget --show-progress $url -qP /tmp

if [ ! -f /tmp/$targz_file ]; then
    echo "> Error: "$motor" package download failed!"
    exit 1
fi

# DreamOS and Service Detection
#######################################
is_dreamos=false
service_name=""

if [ -f /usr/bin/systemctl ]; then
    if systemctl is-active --quiet dreambox-enigma2; then
        is_dreamos=true
        service_name="dreambox-enigma2"
    elif systemctl is-active --quiet enigma2; then
        is_dreamos=true
        service_name="enigma2"
    fi
fi

# Stop Enigma2 if DreamOS is detected to protect memory cache
#######################################
if [ "$is_dreamos" = true ]; then
    echo
    echo "> DreamOS ($service_name) detected. Safely stopping Enigma2 to prevent cache overwrite..."
    systemctl stop $service_name
    sleep 2
fi

echo
echo "> Removing old channels list..."
rm -rf /etc/enigma2/lamedb /etc/enigma2/*list /etc/enigma2/*.tv /etc/enigma2/*.radio /etc/tuxbox/*.xml >/dev/null 2>&1

# Extracting channels lists file
#######################################
cd /tmp
set -e
sleep 3
echo "> Extracting new channels list..."
tar -xzf $targz_file -C /
set +e
rm -f $targz_file

# Restart Enigma2 or reload service list
#######################################
if [ "$is_dreamos" = true ]; then
    echo "> Starting Enigma2..."
    systemctl start $service_name
else
   echo "> Reloading service list..."
   wget -qO - http://127.0.0.1/web/servicelistreload?mode=0 > /dev/null 2>&1
   wget -qO - http://127.0.0.1/web/servicelistreload?mode=4 > /dev/null 2>&1
   sleep 2
fi

echo
echo "> "$motor" Channels Lists are installed successfully"
echo "> Maintained By ElieSatpanelgrid team"
echo