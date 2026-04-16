#!/bin/bash

#configuration
#########################################
mydevice="zgemmah7"
device=$(head -n 1 /etc/hostname)
image='openvix'
version='image'
date="$(date +%Y%m%d)"

#detetmine image name
#########################################
img=$(curl -s "https://www.openvix.co.uk/index.php/downloads/zgemma-images/zgemma-h7/" | grep -o "$mydevice/.*\.zip" | awk '{print $1}' | sed 's/^.*openvix/openvix/' | sed 's/\.release.*/.release/')

if [[ $img == *"openvix"* ]]; then
imgnm="$img"-"$device"_"$date".zip
echo "> "$imgnm" image found ..."
sleep 5
else
imgnm=openvix-6.6-"$device"_"$date".zip
echo "> "$imgnm" image found ..."
sleep 5
fi

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

if wget -q --method=HEAD http://www.openvix.co.uk/openvix-builds/current.php?open=$device;
 then
wget --show-progress -qO $ms/images/$imgnm http://www.openvix.co.uk/openvix-builds/current.php?open=$device
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