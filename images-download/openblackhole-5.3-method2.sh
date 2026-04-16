#!/bin/bash

device=$(head -n 1 /etc/hostname)
image='openblackhole'
version='5.3'
today=$(date +%Y%m%d)

case $device in
pulse4k|pulse4kmini|osmini4k|osmio4kplus|gbip4k|gbquad4k|gbtrio4k|gbtri4kpro|gbue4k|novaler4kpro|sf8008|sfx6008|sx88v2|sx988|dual|ustym4kpro|vuduo2|vuduo4k|vuduo4kse|vusolo2|vusolo4kse|vusolo4k|vuultimo|vuultimo4k|vuuno4k|vuuno4kse|vuzero|vuzero4k|zgemmah7|zgemmah11s|zgemmah82h|zgemmah9twinse|h7) 

#check mounted storage
msp=("/media/hdd" "/media/usb" "/media/usb")

for ms in "${msp[@]}"; do
if [ -d "$ms" ]; then
echo ""
break
fi
done

if [ -z "$ms" ]; then
echo "> Mount your external memory and try again"
exit 1
else

#check images path
if [ -d $ms/images ]; then
echo ""
else
echo ""
mkdir $ms/images
fi


echo '> Downloading '$image'-'$version' image to '$ms'/images please wait...'
sleep 7s

url=https://images.openbh.net/latest/5.3/$device
wget -O $ms/images/openbh-5.3-$device-"$today"_multi.zip $url

for dir in "/media/hdd/ImagesUpload/" "/media/hdd/open-multiboot-upload/" "/media/hdd/OPDBootUpload/" "/media/hdd/EgamiBootUpload/"
do
echo ""
if [ -d $dir ] ; then
cp $ms/images/$imgnm $dir >/dev/null 2>&1
fi
done

echo '> Download '$image'-'$version' to '$ms'/images finished 
> Eliesat enjoy... '
sleep 3s 
fi

;;
*) echo "> your device is not supported"
esac

exit 0