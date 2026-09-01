#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/tvgarden/tvgarden.sh

# Configuration
#########################################
plugin="tvgarden"
rm="TVGarden"
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

if [ ! -f /usr/bin/enigma2 ]; then
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    exit 1
fi

if ! opkg list-installed | grep -q "gstreamer"; then
    :
fi

TVGARDEN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/TVGarden"
if [ ! -d "$TVGARDEN_DIR" ]; then
    mkdir -p "$TVGARDEN_DIR"
fi

CONFIG_DIR="/etc/enigma2/tvgarden"
if [ -d "$CONFIG_DIR" ]; then
    BACKUP_DIR="/tmp/tvgarden_backup_$(date +%Y%m%d_%H%M%S)"
    cp -r "$CONFIG_DIR" "$BACKUP_DIR"
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
DEPS="python3-requests
python3-six
python3-json
python3-html
python3-compression
python3-threading
python3-multiprocessing
python3-shell
python3-core
python3-codecs
python3-netclient
python3-image
ffmpeg
gstplayer
exteplayer3
enigma2-plugin-systemplugins-serviceapp"

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

TVGARDEN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/TVGarden"
LOCALE_DIR="/usr/lib/enigma2/python/Plugins/Extensions/TVGarden/locale"
ICONS_DIR="/usr/lib/enigma2/python/Plugins/Extensions/TVGarden/icons"
CACHE_DIR="/tmp/tvgarden_cache"

chmod -R 755 "$TVGARDEN_DIR"
chown -R root:root "$TVGARDEN_DIR"

if [ -d "$LOCALE_DIR" ]; then
    for lang_dir in "$LOCALE_DIR"/*/; do
        if [ -d "$lang_dir" ]; then
            lang=$(basename "$lang_dir")
            msgfmt -o "/usr/lib/enigma2/python/Plugins/Extensions/TVGarden/locale/$lang/LC_MESSAGES/tvgarden.mo" \
                   "$LOCALE_DIR/$lang/LC_MESSAGES/tvgarden.po" 2>/dev/null || true
        fi
    done
fi

mkdir -p "$CACHE_DIR"
mkdir -p "/etc/enigma2/tvgarden/favorites"
chmod 777 "$CACHE_DIR"

SKINS_DIR="/usr/share/enigma2"
if [ -d "$TVGARDEN_DIR/skins" ]; then
    for skin in "$TVGARDEN_DIR/skins"/*/; do
        skin_name=$(basename "$skin")
        ln -sf "$skin" "$SKINS_DIR/TVGarden_$skin_name" 2>/dev/null || true
    done
fi

if [ -f /usr/lib/enigma2/python/Plugins/Extensions/TVGarden/plugin.py ]; then
    python3 -c "
import sys
sys.path.insert(0, '/usr/lib/enigma2/python/Plugins')
from Plugins.Plugin import PluginDescriptor
import os
plugin_path = '/usr/lib/enigma2/python/Plugins/Extensions/TVGarden'
if os.path.exists(plugin_path):
    pass
" 2>/dev/null || true
fi

BACKUP_PATTERN="/tmp/tvgarden_backup_*"
LATEST_BACKUP=$(ls -td $BACKUP_PATTERN 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ] && [ -d "$LATEST_BACKUP" ]; then
    cp -r "$LATEST_BACKUP"/* "/etc/enigma2/tvgarden/" 2>/dev/null || true
    rm -rf "$LATEST_BACKUP"
fi

find "/tmp" -name "tvgarden_*" -type f -mtime +7 -delete 2>/dev/null || true

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
