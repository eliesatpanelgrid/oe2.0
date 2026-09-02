#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/bitratemonitorpro/bitratemonitorpro.sh

# Configuration
#########################################
plugin="bitratemonitorpro"
rm="BitrateMonitorPro"
section="addons"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"
version=$(wget $git_url/version -qO- | awk 'NR==1')
plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"
targz_file="$plugin.tar.gz"
url="$git_url/$targz_file"
temp_dir="/tmp"

# Determine package manager
#########################################
if command -v dpkg &> /dev/null; then
package_manager="apt"
status_file="/var/lib/dpkg/status"
uninstall_command="apt-get purge --auto-remove -y"
else
package_manager="opkg"
status_file="/var/lib/opkg/status"
uninstall_command="opkg remove --force-depends"
fi

#check and_remove package old version
#########################################
check_and_remove_package() {
if [ -d $plugin_path ]; then
echo "> removing package old version please wait..."
sleep 3 
rm -rf $plugin_path > /dev/null 2>&1

if grep -q "$package" "$status_file"; then
echo "> Removing existing $package package, please wait..."
$uninstall_command $package > /dev/null 2>&1
fi
echo "*******************************************"
echo "*        Removal Completed Successfully   *"
echo "*            Maintained by Eliesat        *"
echo "*******************************************"
sleep 3
echo
exit 1
else
echo " " 
fi  }
check_and_remove_package

ERRORS=0
WARNINGS=0

# 1. Enigma2 presence
ENIGMA2_DIR="/usr/lib/enigma2/python"
if [ ! -d "$ENIGMA2_DIR" ]; then
    ERRORS=$((ERRORS + 1))
fi

# 2. Image type detection
IMAGE_NAME="Unknown"
if [ -f /etc/image-version ]; then
    IMAGE_NAME=$(head -1 /etc/image-version 2>/dev/null)
elif [ -f /etc/issue ]; then
    IMAGE_NAME=$(head -1 /etc/issue 2>/dev/null | sed 's/\\.*//g')
fi

# 3. Python version
PY_BIN=""
PY_VER=""
if command -v python3 >/dev/null 2>&1; then
    PY_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PY_BIN="python"
fi

if [ -n "$PY_BIN" ]; then
    PY_MAJOR=$($PY_BIN -c 'import sys; print(sys.version_info[0])' 2>/dev/null)
    if [ "$PY_MAJOR" = "3" ] || [ "$PY_MAJOR" = "2" ]; then
        PY_VER=$($PY_BIN -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null)
    else
        WARNINGS=$((WARNINGS + 1))
    fi
else
    ERRORS=$((ERRORS + 1))
fi

# 4. DVB tuner presence
TUNER_FOUND=0
if [ -d /dev/dvb ] && [ -n "$(ls -d /dev/dvb/adapter* 2>/dev/null)" ]; then
    TUNER_FOUND=1
elif [ -d /proc/stb/frontend ] && [ "$(ls -d /proc/stb/frontend/* 2>/dev/null | wc -l)" -gt 0 ]; then
    TUNER_FOUND=1
fi

if [ $TUNER_FOUND -eq 0 ]; then
    WARNINGS=$((WARNINGS + 1))
fi

# 5. Full HD skin verification
FHD_OK=0
SKIN_NAME="Unknown"
SKIN_PATH=""
SKIN_DIR=""

SETTINGS="/etc/enigma2/settings"

if [ -f "$SETTINGS" ]; then
    SKIN_PATH=$(grep "^config.skin.primary_skin=" "$SETTINGS" 2>/dev/null | head -1 | cut -d= -f2- | tr -d ' \r')
fi

if [ -n "$SKIN_PATH" ]; then
    SKIN_DIR=$(dirname "$SKIN_PATH")
    SKIN_NAME=$(basename "$SKIN_DIR")
    SKIN_LOWER=$(echo "$SKIN_NAME" | tr '[:upper:]' '[:lower:]')
    
    case "$SKIN_LOWER" in
        *fhd*|*fullhd*|*full_hd*|*full-hd*|*1080*|*uhd*|*4k*|*2160*)
            FHD_OK=1
            ;;
    esac

    if [ $FHD_OK -eq 0 ] && [ -f "$SKIN_PATH" ]; then
        MAX_WIDTH=$(grep -o 'size="[0-9]*[x,]' "$SKIN_PATH" 2>/dev/null | grep -o '[0-9]*' | sort -rn 2>/dev/null | head -1)
        if [ -n "$MAX_WIDTH" ] && [ "$MAX_WIDTH" -ge 1920 ] 2>/dev/null; then
            FHD_OK=1
        fi
    fi

    if [ $FHD_OK -eq 0 ]; then
        for SKIN_XML in "$SKIN_DIR/skin.xml" "$SKIN_DIR/skin_display.xml" "/usr/share/enigma2/$SKIN_NAME/skin.xml"; do
            if [ -f "$SKIN_XML" ]; then
                MAX_WIDTH=$(grep -o 'size="[0-9]*[x,]' "$SKIN_XML" 2>/dev/null | grep -o '[0-9]*' | sort -rn 2>/dev/null | head -1)
                if [ -n "$MAX_WIDTH" ] && [ "$MAX_WIDTH" -ge 1920 ] 2>/dev/null; then
                    FHD_OK=1
                    break
                fi
            fi
        done
    fi
fi

if [ $FHD_OK -eq 0 ] && [ -f "$SETTINGS" ]; then
    VID_MODE=$(grep "^config.av.videomode=" "$SETTINGS" 2>/dev/null | head -1 | cut -d= -f2- | tr -d ' \r')
    case "$VID_MODE" in
        *1080*|*2160*|*3840*|*1920*|*4k*|*4K*)
            FHD_OK=1
            ;;
    esac
fi

if [ $FHD_OK -eq 0 ]; then
    for PROC_VID in /proc/stb/video/videomode /proc/stb/video/current_resolution /proc/stb/video/resolution; do
        if [ -f "$PROC_VID" ]; then
            CUR_RES=$(cat "$PROC_VID" 2>/dev/null)
            case "$(echo "$CUR_RES" | tr '[:upper:]' '[:lower:]')" in
                *1080*|*2160*|*3840*|*1920*|*4k*)
                    FHD_OK=1
                    break
                    ;;
            esac
        fi
    done
fi

if [ $FHD_OK -eq 0 ] && [ -f "$SETTINGS" ]; then
    if grep -q "config.av.1080p=1" "$SETTINGS" 2>/dev/null; then
        FHD_OK=1
    fi
fi

if [ $FHD_OK -eq 0 ]; then
    ERRORS=$((ERRORS + 1))
fi

# Premium skin color check
PREMIUM_OK=0
if [ -n "$SKIN_DIR" ] && [ "$SKIN_DIR" != "." ]; then
    for SKIN_XML in "$SKIN_PATH" "$SKIN_DIR/skin.xml" "/usr/share/enigma2/$SKIN_NAME/skin.xml"; do
        if [ -f "$SKIN_XML" ]; then
            for COLOR in chselfg background3 cyan1 hellgreen grdd7 grdd grdl foreground2; do
                if grep -q "$COLOR" "$SKIN_XML" 2>/dev/null; then
                    PREMIUM_OK=$((PREMIUM_OK + 1))
                fi
            done
            break
        fi
    done
fi

if [ "$PREMIUM_OK" -lt 4 ]; then
    WARNINGS=$((WARNINGS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    exit 1
fi

#download & install dependencies
#######################################
# Detect OS
if command -v apt-get >/dev/null 2>&1; then
    OS="DreamOS"
    PM_UPDATE="apt-get update"
    PM_INSTALL="apt-get install -y"
else
    OS="Opensource"
    PM_UPDATE="opkg update"
    PM_INSTALL="opkg install"
fi

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    aarch64) DEVICE="arm64" ;;
    armv7l|armhf) DEVICE="arm" ;;
    mips|mipsel) DEVICE="mips" ;;
    sh4) DEVICE="sh4" ;;
    *) DEVICE="unknown" ;;
esac

# Detect python
PY=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null)

case "$PY" in
    3.9|3.10|3.11|3.12|3.13|3.14) ;;
    *) echo "> Python $PY is not supported"; exit 1 ;;
esac

# Required packages
DEPS=""

# Check if installed
is_installed() {
    if [ "$OS" = "DreamOS" ]; then
        dpkg -s "$1" >/dev/null 2>&1
    else
        opkg list-installed | grep -wq "$1"
    fi
}

# Install deps
if [ -z "$DEPS" ]; then
    :
else

echo "Updating package lists..."
$PM_UPDATE >/dev/null 2>&1
echo ""

for pkg in $DEPS; do
    if is_installed "$pkg"; then
        echo "[OK] $pkg already installed"
    else
        echo "[INSTALL] $pkg"
        if $PM_INSTALL $pkg >/dev/null 2>&1; then
            echo "[DONE] $pkg"
        else
            echo "[FAIL] $pkg"
        fi
    fi
done

fi

#download & install package
#########################################
print_message() {
echo "> [$(date +'%Y-%m-%d')] $1"
}
download_and_install_package() {
print_message "> Downloading $plugin-$version package  please wait ..."
sleep 3
wget --show-progress -qO $temp_dir/$targz_file --no-check-certificate $url
tar -xzf $temp_dir/$targz_file -C / > /dev/null 2>&1
extract=$?
rm -rf $temp_dir/$targz_file >/dev/null 2>&1

if [ $extract -eq 0 ]; then

  print_message "> $plugin-$version package installed successfully"
cleanup() {
[ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1
}
cleanup
print_message "> Maintained By ElieSatpanelgrid team"
echo
sleep 3
else
  print_message "> $plugin-$version package download failed"
  sleep 3
fi  }
download_and_install_package
