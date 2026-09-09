cat << 'EOF' > /tmp/get_vuplus.sh
#!/bin/bash

# Configuration
#########################################
hostname=$(head -n 1 /etc/hostname)
echo $hostname
image='vuplus-image'

# Map hostname to code.vuplus.de folder string
#########################################
case "$hostname" in
    # 4K / ARM Models
    vuduo4kse)             folder="VU%2B%20Duo4K%20SE" ;;
    vuduo4klite)           folder="VU%2B%20Duo4K%20Lite" ;;
    vuduo4k)               folder="VU%2B%20Duo4K" ;;
    vuuno4kse)             folder="VU%2B%20Uno4K%20SE" ;;
    vuuno4k)               folder="VU%2B%20Uno4K" ;;
    vusolo4k)              folder="VU%2B%20Solo4K" ;;
    vuzero4k)              folder="VU%2B%20Zero4K" ;;
    vuultimo4k|vuultim4k)  folder="VU%2B%20Ultimo4K" ;;
    
    # HD / Legacy Models
    vusolose)              folder="VU%2B%20Solo%20SE" ;;
    vuduo2)                folder="VU%2B%20Duo2" ;;
    vusolo2)               folder="VU%2B%20Solo2" ;;
    vuzero)                folder="VU%2B%20Zero" ;;
    vuultimo)              folder="VU%2B%20Ultimo" ;;
    vuduo|bm750)           folder="VU%2B%20Duo" ;;
    vusolo)                folder="VU%2B%20Solo" ;;
    vuuno)                 folder="VU%2B%20Uno" ;;
    
    # Fallback default
    *)                     folder="VU%2B%20${hostname}" ;;
esac

# Determine latest image file and URL
#########################################
echo "> Fetching image info for $hostname..."
target_dir_url="https://code.vuplus.de/download/flashimages/${folder}/"

# Fetch directory listing, sort by timestamp numerically, and grab the NEWEST _usb.zip image
imgnm=$(curl -sL "$target_dir_url" | grep -o 'vuplus-image-[^"]*_usb\.zip' | sort -V | tail -n 1)

if [ -z "$imgnm" ]; then
    echo "> Error: Could not find image for device $hostname on code.vuplus.de."
    rm -f "$0"
    exit 1
fi

url="${target_dir_url}${imgnm}"

echo "> Found newest image: $imgnm"
echo "> Download URL: $url"

# Check mounted storage
#########################################
for ms in "/media/hdd" "/media/usb" "/media/mmc"
do
    if mount | grep -q "$ms" ; then
        echo "> Mounted storage found at: $ms"
        mkdir -p "$ms/images" >/dev/null 2>&1
        break
    fi
done

if [ -z "$ms" ]; then
    echo "> Mount your external memory and try again"
    rm -f "$0"
    exit 1
fi

# Download image to mounted storage
#########################################
echo "> Downloading $image to $ms/images, please wait..."
echo "$url" > /tmp/url.txt

wget --no-check-certificate --show-progress -qO "$ms/images/$imgnm" "$url"

if [ $? -eq 0 ] && [ -s "$ms/images/$imgnm" ]; then
    echo "> Download finished: $ms/images/$imgnm"
else
    echo "> Download failed!"
    rm -f "$0"
    exit 1
fi

# Copy image to multiboot upload folders
#########################################
for dir in "/media/hdd/ImagesUpload/" "/media/hdd/open-multiboot-upload/" "/media/hdd/OPDBootUpload/" "/media/hdd/EgamiBootUpload/"
do
    if [ -d "$dir" ] ; then
        echo "> Copying image to $dir..."
        cp "$ms/images/$imgnm" "$dir" >/dev/null 2>&1
    fi
done

echo "> Eliesat enjoy..."

# Clean up script itself
rm -f "$0"
EOF
chmod +x /tmp/get_vuplus.sh
/tmp/get_vuplus.sh