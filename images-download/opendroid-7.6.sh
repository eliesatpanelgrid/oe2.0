#!/bin/bash

#########################################
# CONFIGURATION
#########################################
device=$(head -n 1 /etc/hostname)
image="opendroid"
version="7.6"
#########################################
# SHOW AVAILABLE VERSIONS
#########################################
versions=$(curl -s "https://opendroid.org/json.php?box=$device" \
| grep -o 'OpenDROID ([^)]*)' \
| sed 's/OpenDROID (//;s/)//' \
| cut -d. -f1,2 \
| sort -u)

echo "> Available versions:"
echo "$versions"
echo "---------------------------------"
#########################################
# DETERMINE BRAND
#########################################
case "$device" in
    vuzero4k|vusolo4k|vuuno4k|vuuno4kse|vuduo4k|vuduo4kse|vuultimo4k)
        u1="Vu%2B"
        ext="_usb.zip"
        ;;
    gbx34k|gbtrio4k|gbtrio4kpro|gbip4k|gbue4k|gbquad4k)
        u1="GigaBlue"
        ext="_mmc.zip"
        ;;
    sf8008|sf4008|sf8008m)
        u1="Octagon"
        ext="_mmc.zip"
        ;;
    ustym4kpro|ustym4kottpremium)
        u1="uClan"
        ext="_mmc.zip"
        ;;
    *)
        echo "> Your device is not supported"
        exit 1
        ;;
esac

#########################################
# GET IMAGE NAME
#########################################
img=$(curl -s "https://opendroid.org/json.php?box=$device" \
| grep "\"OpenDROID ($version.)\"" -A 20 \
| grep '"link"' \
| sed 's/.*"link":"\([^"]*\)".*/\1/' \
| sed 's#\\/#/#g' \
| awk -F/ '{print $NF}' \
| sed 's/\.zip.*/.zip/' \
| sort \
| tail -n 1)

if [ -z "$img" ]; then
    echo "> Failed to get image name"
    exit 1
fi

echo "> Image found: $img"
sleep 2

#########################################
# FIND MOUNTED STORAGE
#########################################
found_mount=""

for m in "/media/hdd" "/media/usb" "/media/mmc"
do
    if mount | grep -q "$m"; then
        echo "> Mounted storage found at: $m"
        mkdir -p "$m/images"
        found_mount="$m"
        break
    fi
done

if [ -z "$found_mount" ]; then
    echo "> Mount your external memory and try again"
    exit 1
fi

ms="$found_mount"
sleep 2

#########################################
# DOWNLOAD IMAGE
#########################################
url="https://opendroid.org/$version/$u1/$device/$img"

echo "> Downloading $image-$version..."
sleep 2

if wget --spider -q "$url"; then
    wget --show-progress -qO "$ms/images/$img" "$url"
else
    echo "> Download failed: check internet or device support"
    exit 1
fi

echo "> Download completed"
sleep 2

#########################################
# COPY TO MULTIBOOT FOLDERS
#########################################
for dir in \
    "/media/hdd/ImagesUpload/" \
    "/media/hdd/open-multiboot-upload/" \
    "/media/hdd/OPDBootUpload/" \
    "/media/hdd/EgamiBootUpload/"
do
    if [ -d "$dir" ]; then
        echo "> Copying image to $dir"
        cp "$ms/images/$img" "$dir" >/dev/null 2>&1
    fi
done

#########################################
# DONE
#########################################
echo "> Eliesat enjoy"