#!/bin/bash

#configuration
#######################################
device=$(head -n 1 /etc/hostname)
image='openhdf'
version='6.5'
date="$(date +%Y%m%d)"

#detetmine image name
#########################################
imgnm=$(curl -s "https://v65.hdfreaks.cc/$device"/ | grep $device | grep -o 'href="[^"]*\.zip"' | sed 's/\.zip.*/.zip/' | sed 's/^.*openhdf/openhdf/' | head -n 1)
echo "> "$imgnm" image found ..."
sleep 5

#check mounted storage
#########################################
for ms in "/media/hdd" "/media/usb" "/media/mmc"
do
    if mount|grep $ms >/dev/null 2>&1; then
    echo "> Mounted storage found at: $ms"
    mkdir "$ms"/images >/dev/null 2>&1
    break
    fi
done

if [ -z "$ms" ]; then
echo "> Mount your external memory and try again"
exit 1
fi
sleep 3

#download image to mounted storage
#########################################
echo "> Downloading "$image"-"$version" to "$ms"/images please wait..."
sleep 3

if wget -q --method=HEAD https://v65.hdfreaks.cc/current.php?open=$device;
 then
wget --show-progress -qO $ms/images/$imgnm https://v65.hdfreaks.cc/current.php?open=$device
else
echo "> check your internet connection and try again or your device is not supported..."
exit 1
fi

echo "> Download of "$image"-"$version"  to "$ms"/images is finished"
sleep 3

#copy image to multiboot upload folders
#########################################
for dir in "/media/hdd/ImagesUpload/" "/media/hdd/open-multiboot-upload/" "/media/hdd/OPDBootUpload/" "/media/hdd/EgamiBootUpload/"
do
if [ -d $dir ] ; then
echo "> "$dir" folder found ..."
sleep 1
echo "> copying image to "$dir" folder please wait ..."
sleep 1
cp $ms/images/$imgnm $dir >/dev/null 2>&1
fi
done

echo "> Eliesat enjoy..."
