#!/bin/sh

if [ -f /etc/image-version ]; then
    IMAGE_NAME=$(grep -i "^creator=" /etc/image-version | cut -d"=" -f2 | xargs)
    IMAGE_VERSION=$(grep -i "^version=" /etc/image-version | head -n1 | cut -d"=" -f2 | xargs)
elif [ -f /etc/issue ]; then
    IMAGE_NAME=$(head -n1 /etc/issue | awk '{print $1}')
    IMAGE_VERSION=$(head -n1 /etc/issue | awk '{print $2}')
else
    IMAGE_NAME="Unknown"
    IMAGE_VERSION="Unknown"
fi

###########################################
# Validate image (OpenATV only)
###########################################
case "$IMAGE_NAME" in
    openATV|OpenATV)
    wget -q "--no-check-certificate" https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/images-backup/openatv-settings.sh -O - | /bin/sh
        ;;
    *)
        echo "> Unsupported image: $IMAGE_NAME"
        echo "> Please install OpenATV and try again..."
        exit 1
        ;;
esac

###########################################
# Done
###########################################
sleep 1
