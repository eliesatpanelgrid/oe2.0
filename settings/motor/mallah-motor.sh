#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/motor/mallah-motor.sh


#configuration
#######################################
motor=mallah-motor
targz_file=$motor.tar.gz
url=https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/settings/motor/$targz_file

# Remove unnecessary files and folders
#######################################
[ -d "/CONTROL" ] && rm -r /CONTROL >/dev/null 2>&1
rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1

#downloading channels lists file
#######################################
echo "> Downloading "$motor" Channels Lists  Please Wait ..."
sleep 3
wget --show-progress $url -qP /tmp

#removing old channels lists file
#######################################
rm -rf /etc/enigma2/lamedb /etc/enigma2/*list /etc/enigma2/*.tv /etc/enigma2/*.radio  /etc/tuxbox/*.xml >/dev/null 2>&1

#extracting channels lists file
#######################################
cd /tmp
set -e
sleep 3
echo
tar -xzf $targz_file -C /
set +e
rm -f $targz_file

# Restart Enigma2 service or kill enigma2 based on the system
#######################################
if [ -f /etc/opkg/opkg.conf ];then
echo "> "$motor" Channels Lists are installed successfully"
echo "> Maintained By ElieSatpanelgrid team"
echo
wget -qO - http://127.0.0.1/web/servicelistreload?mode=0 > /dev/null 2>&1
sleep 2
else
echo "> "$motor" package download failed"
fi