#!/bin/bash

#configuration
#########################################
device=$(head -n 1 /etc/hostname)
image="pure"
version="7.4"

#determine brand based on device name
#########################################
case $device in
zgemmah7|zgemmah9combo|zgemmah9sse|zgemmah9twin|zgemmah11s|h7)
brand='airdigital';;
viper4k|viper4kv20|viper4kv30|viper4kv40)
brand='amiko';;
anadol4k)
brand='anadol';;
ax51|ax61)
brand='ax';;
axashis4kcomboplus)
brand='axas';;
dinobot4kplus)
brand='dinobot';;
dm920|dm900)
brand='dreambox';;
osmini4k|osmio4k|osmio4kplus)
brand='edision';;
gbquad4k|gbtrio4k|gbtrio4kpro|gbue4k)
brand='gigablue';;
hitube4k)
brand='hitube';;
mutant66se)
brand='mutant';;
novaler4k|novaler4kse|novaler4kpro)
brand='novaler';;
sf4008|sf8008|sf8008m)
brand='octagon';;
dual)
brand='qviart';;
ustym4kpro)
brand='uclan';;
vuduo4k|vuduo4kse|vusolo4k|vusolo4kse|vuultimo4k|vuuno4k|vuuno4kse|vuzero4k)
brand='vuplus';;
*) echo "> your device is not supported "
exit 1 ;;
esac

#detetmine image name
#########################################
imgnm=$(curl -s "https://www.pur-e2.club/OU/images/index.php?dir=$version/$brand/" | grep $device | tail -n 1 | tr -d ' ' | sed 's/\.zip.*/.zip/')

if [ "$device" == "sf8008" ]; then
imgnm=$(curl -s "https://www.pur-e2.club/OU/images/$version/$brand/" | grep -o 'href="[^"]*\.zip"' | awk -F'"' '{print $2}' | sed '/sf8008m/d' | grep $device | tail -n 1)
fi

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
echo '> Downloading '$image'-'$version' image to '$ms'/images please wait...'
sleep 3

url=https://www.pur-e2.club/OU/images/$version/$brand/$imgnm
if wget -q --method=HEAD $url;
 then
wget --show-progress -qO $ms/images/$imgnm $url
else
echo "> check your internet connection and try again or your device is not supported..."
exit 1
fi

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
echo '> Eliesat enjoy... '
