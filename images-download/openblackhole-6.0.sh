#!/bin/bash

#configuration
#########################################
device=$(head -n 1 /etc/hostname)
image='openblackhole'
version='6.0'
today=$(date +%Y%m%d)

case $device in
pulse4k|pulse4kmini)
brand=abcom;;
osmini4k|osmio4kplus)
brand=edision;;
gbip4k|gbquad4k|gbtrio4k|gbtri4kpro|gbue4k)
brand=gigablue;;
novaler4kpro)
brand=novaler;;
sf8008|sfx6008|sx88v2|sx988)
brand=octagon;;
dual)
brand=qviart;;
ustym4kpro)
brand=uclan;;
vuduo2|vuduo4k|vuduo4kse|vusolo2|vusolo4kse|vusolo4k|vuultimo|vuultimo4k|vuuno4k|vuuno4kse|vuzero|vuzero4k)
brand=vuplus;;
zgemmah7|zgemmah11s|zgemmah82h|zgemmah9twinse|h7)
brand=zgemma;; 
*) echo "> your device is not supported"
exit 1
esac

#determine image name
#########################################
imgnm=$(curl -s "https://images.openbh.net/?b=$version%2F$brand%2F$device" | grep -o 'href="[^"]*\.zip"' | awk -F'"' '{print $2}'| sed 's/^.*openbh/openbh/' | sed '/recovery/d' | head -n 1)

if [ -z "$imgnm" ]; then
    echo "> Failed to find image name for $device"
    exit 1
fi

echo "> $imgnm image found ..."
sleep 2

url="https://images.openbh.net/builds/${version}/${brand}/${device}/${imgnm}"

#check mounted storage
#########################################
for ms in "/media/hdd" "/media/usb" "/media/mmc"
do
    if mount | grep -q "$ms"; then
        echo "> Mounted storage found at: $ms"
        mkdir -p "$ms/images" >/dev/null 2>&1
        break
    fi
done

if [ -z "$ms" ]; then
    echo "> Mount your external memory and try again"
    exit 1
fi
sleep 2

#download image to mounted storage
#########################################
echo "> Downloading $image-$version image to $ms/images please wait..."
sleep 2

wget -O "$ms/images/$imgnm" --user-agent="Mozilla/5.0" "$url"

filesize=$(stat -c%s "$ms/images/$imgnm" 2>/dev/null || echo 0)

if [ -f "$ms/images/$imgnm" ] && [ "$filesize" -gt 10000000 ]; then
    echo "> Download of $image-$version image to $ms/images is finished"
else
    echo "> Download failed! Downloaded file size was only $filesize bytes."
    if [ "$filesize" -gt 0 ] && [ "$filesize" -lt 50000 ]; then
        echo "> Server response:"
        head -n 10 "$ms/images/$imgnm"
    fi
    rm -f "$ms/images/$imgnm"
    exit 1
fi
sleep 2

#copy image to multiboot upload folders
#########################################
for dir in "/media/hdd/ImagesUpload/" "/media/hdd/open-multiboot-upload/" "/media/hdd/OPDBootUpload/" "/media/hdd/EgamiBootUpload/"
do
    if [ -d "$dir" ] ; then
        echo "> $dir folder found ..."
        echo "> copying image to $dir folder please wait ..."
        cp "$ms/images/$imgnm" "$dir" >/dev/null 2>&1
    fi
done

echo "> Eliesat enjoy..."
