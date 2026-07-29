#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/skins/aifury/fury.sh

# Configuration
#########################################
plugin="fury"
plugin2="fury-fhd"
plugin3="aifury"
rm="Fury-FHD"
section="skins"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"
version=$(wget $git_url/version -qO- | awk 'NR==1')
plugin_path="/usr/share/enigma2/$rm"
package="enigma2-plugin-extensions-$plugin"
package2="enigma2-plugin-extensions-$plugin2"
packagee="enigma2-plugin-extensions-$plugin2"

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
rm -rf /usr/lib/enigma2/python/Plugins/Extensions/Fury  > /dev/null 2>&1
rm -rf /usr/share/enigma2/Fury-FHD  > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/fury* > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/Converter/fury* > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/Renderer/fury* > /dev/null 2>&1

if grep -q "$package" "$status_file"; then
echo "> Removing existing $package package, please wait..."
$uninstall_command $package > /dev/null 2>&1
$uninstall_command $package2 > /dev/null 2>&1
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

BASE_URL="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/skins/aifury"

TMP_DIR="/tmp/aifury_install"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || exit 1

PYTHON_VER=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
fi

[ -z "$PYTHON_VER" ] && { rm -rf "$TMP_DIR"; exit 1; }

ARCH=$(uname -m)
case "$ARCH" in
    aarch64*) SYS_ARCH="aarch64" ;;
    armv7*|armv8*|arm*) SYS_ARCH="arm" ;;
    mips*) SYS_ARCH="mipsel" ;;
    *)
        if opkg print-architecture | grep -q "aarch64"; then
            SYS_ARCH="aarch64"
        elif opkg print-architecture | grep -q -E "cortexa15hf|cortexa9hf|arm"; then
            SYS_ARCH="arm"
        else
            SYS_ARCH="mipsel"
        fi
        ;;
esac

if [ "$SYS_ARCH" = "aarch64" ]; then
    if [ "$PYTHON_VER" != "3.13" ] && [ "$PYTHON_VER" != "3.14" ]; then
        SYS_ARCH="arm"
    fi
fi

PART2_FILE="aifury_py${PYTHON_VER}_${SYS_ARCH}.ipk"

echo "> Downloading $plugin-$version package  please wait ..."
sleep 3

if wget --show-progress -q "$BASE_URL/$PART2_FILE" -O "$TMP_DIR/$PART2_FILE" && [ -s "$TMP_DIR/$PART2_FILE" ]; then
    if opkg install "$TMP_DIR/$PART2_FILE" --force-overwrite --force-reinstall >/dev/null 2>&1; then
        if wget --show-progress -q "$BASE_URL/aifury.ipk" -O "$TMP_DIR/aifury.ipk" && [ -s "$TMP_DIR/aifury.ipk" ]; then
            if opkg install "$TMP_DIR/aifury.ipk" --force-overwrite --force-reinstall >/dev/null 2>&1; then
                rm -rf "$TMP_DIR"
               echo "> $plugin-$version package installed successfully"
                echo "> Maintained By ElieSatpanelgrid team"
                echo
                sleep 3
                exit 0
            fi
        fi
    fi
fi

rm -rf "$TMP_DIR"
echo "> AI-Fury package download failed"
sleep 3
exit 1