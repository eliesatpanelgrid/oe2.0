#!/bin/bash

# =========================
# CONFIGURATION
# =========================
image="egami"
version="11.0"
device=$(head -n 1 /etc/hostname)
site="https://image.egami-image.com/$version"

# =========================
# FALLBACK TABLE (SCRIPT 1)
# =========================
fallback_url=""
fallback_imgnm=""

get_fallback() {
    case "$device" in
        dm900)
            fallback_url="https://github.com/eliesat/Images/releases/download/V11.0-r1/egami-11.0-r1-dm900-20250826_mmc.zip"
            fallback_imgnm="egami-11.0-r1-dm900-20250826_mmc.zip"
            ;;
        dm920)
            fallback_url="https://github.com/eliesat/Images/releases/download/V11.0-r1/egami-11.0-r1-dm920-20250826_mmc.zip"
            fallback_imgnm="egami-11.0-r1-dm920-20250826_mmc.zip"
            ;;
        gbquad4k)
            fallback_url="https://github.com/eliesat/Images/releases/download/V11.0-r1/egami-11.0-r1-gbquad4k-20250825_usb.zip"
            fallback_imgnm="egami-11.0-r1-gbquad4k-20250825_usb.zip"
            ;;
        gbquad4kpro)
            fallback_url="https://github.com/eliesat/Images/releases/download/V11.0-r1/egami-11.0-r1-gbquad4kpro-20250824_usb.zip"
            fallback_imgnm="egami-11.0-r1-gbquad4kpro-20250824_usb.zip"
            ;;
        ax51)
            fallback_url="https://github.com/eliesat/Images/releases/download/v11-r5/egami-11.0-r5-ax51-20251027_multi.zip"
            fallback_imgnm="egami-11.0-r5-ax51-20251027_multi.zip"
            ;;
        sf4008) fallback_url="https://github.com/eliesat/Images/releases/download/v11-r5/egami-11.0-r5-sf4008-20251023_usb.zip"
            fallback_imgnm="-11.0-r5-sf4008-20251023_usb.zip"
            ;;
        sf8008) fallback_url="https://github.com/eliesat/Images/releases/download/V11.0-r1/egami-11.0-r1-sf8008-20250825_mmc.zip"
            fallback_imgnm="egami-11.0-r1-sf8008-20250825_mmc.zip"
            ;;
        vuduo4k) fallback_url="https://github.com/eliesat/Images/releases/download/V11.0-r1/egami-11.0-r1-vuduo4k-20250825_usb.zip"
            fallback_imgnm="egami-11.0-r1-sf8008-20250825_mmc.zip"
            ;;
        vuduo4kse) fallback_url="https://github.com/eliesat/Images/releases/download/V11.0-r1/egami-11.0-r1-vuduo4kse-20250825_usb.zip"
            fallback_imgnm="egami-11.0-r1-vuduo4kse-20250825_usb.zip"
            ;;
        vusolo4k) fallback_url="https://github.com/eliesat/Images/releases/download/V11.0-r1/egami-11.0-r1-vusolo4k-e2s-20250825_usb.zip"
            fallback_imgnm="egami-11.0-r1-vusolo4k-e2s-20250825_usb.zip"
            ;;
        vuultimo4k) fallback_url="https://github.com/eliesat/Images/releases/download/V11.0-r1/egami-11.0-r1-vuultimo4k-20250825_usb.zip"
            fallback_imgnm="egami-11.0-r1-vuultimo4k-20250825_usb.zip"
            ;;
        vuuno4kse) fallback_url="https://github.com/eliesat/Images/releases/download/V11.0-r1/egami-11.0-r1-vuuno4kse-20250825_usb.zip"
            fallback_imgnm="egami-11.0-r1-vuuno4kse-20250825_usb.zip"
            ;;
        vuuno4k) fallback_url="https://github.com/eliesat/Images/releases/download/v11-r5/egami-11.0-r5-vuuno4k-20251024_usb.zip"
            fallback_imgnm="egami-11.0-r5-vuuno4k-20251024_usb.zip"
            ;;
        vuzero4k) fallback_url="https://github.com/eliesat/Images/releases/download/V11.0-r1/egami-11.0-r1-vuzero4k-20250826_usb.zip"
            fallback_imgnm="-11.0-r1-vuzero4k-20250826_usb.zip"
            ;;
        *)
            return 1
            ;;
    esac
}

# =========================
# PRIMARY METHOD
# =========================
imgnm=$(curl -s "$site"/index.php?open="$device" \
    | grep "$image"-"$version" \
    | sed 's/^.*egami/egami/' \
    | grep 'multi' \
    | cut -f1 -d"<" \
    | tail -n 1)

if [ -n "$imgnm" ]; then
    echo "> $imgnm image found ..."
    sleep 5
fi

# =========================
# STORAGE CHECK
# =========================
for ms in "/media/hdd" "/media/usb" "/media/mmc"
do
    if mount | grep $ms >/dev/null 2>&1; then
        mkdir "$ms"/images >/dev/null 2>&1
        break
    fi
done

if [ -z "$ms" ]; then
    echo "> Mount your external memory and try again"
    exit 1
fi

sleep 3

# =========================
# DOWNLOAD PRIMARY
# =========================
download_primary() {
    echo "> Mounted storage found at: $ms"
    sleep 3
    echo "> Downloading $image-$version image to $ms/images please wait..."
    sleep 3

    url="$site/$device/$imgnm"

    if wget -q --method=HEAD "$url"; then
        wget --show-progress -qO "$ms"/images/"$imgnm" "$url"
        return 0
    else
        return 1
    fi
}

# =========================
# MAIN FLOW
# =========================
if [ -n "$imgnm" ] && download_primary; then
    echo "> Download of $image-$version image finished ..."
else

    if get_fallback; then
        echo "> $fallback_imgnm image found ..."
    sleep 3
    echo "> Mounted storage found at: $ms"
    sleep 3
    echo "> Downloading $image-$version image to $ms/images please wait..."
    sleep 3
        wget --show-progress -qO "$ms"/images/"$fallback_imgnm" "$fallback_url"
        echo "> Download of fallback image finished"
    else
        echo "> Your device is not supported yet"
        echo ""
        echo "> Supported devices:"
        echo "- dm900"
        echo "- dm920"
        echo "- sf4008"
        echo "- sf8008"
        echo "- gbquad4k"
        echo "- gbquad4kpro"
        echo "- mutant51"
        echo "- vuduo4k"
        echo "- vuduo4kse"
        echo "- vusolo4k"
        echo "- vuultimo4k"
        echo "- vuuno4kse"
        echo "- vuuno4k"
        echo "- vuzero4k"
        echo ""
        echo "> Novaler devices:"
        echo "- novaler4k"
        echo "- novaler4kse"
        echo "- novaler4kpro"
        echo ""
        echo "> Zgemma devices:"
        echo "- zgemma h17 combo"
        echo "- zgemma h11s"
        echo "- zgemma h9se"
        echo "- zgemma h9.2se"
        echo "- zgemma h9.2s"
        echo "- zgemma h9.2h"
        echo "- zgemma h9.t"
        echo "- zgemma h9.s"
        echo "- zgemma h9 combo"
        echo "- zgemma h9 twin"
        echo "- zgemma h7 "
        echo "- zgemma h8.2h"
        exit 1
    fi
fi

# =========================
# MULTIBOOT COPY
# =========================
for dir in "/media/hdd/ImagesUpload/" "/media/hdd/open-multiboot-upload/" "/media/hdd/OPDBootUpload/" "/media/hdd/EgamiBootUpload/"
do
    echo ""
    if [ -d "$dir" ]; then
        echo "> $dir folder found ..."
        sleep 1
        echo "> copying image to $dir folder please wait ..."
        sleep 1

        if [ -n "$imgnm" ] && [ -f "$ms/images/$imgnm" ]; then
            cp "$ms/images/$imgnm" "$dir" >/dev/null 2>&1
        else
            cp "$ms/images/$fallback_imgnm" "$dir" >/dev/null 2>&1
        fi
    fi
done

echo "> Eliesat enjoy..."
