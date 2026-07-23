#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/footonsat/footonsat.sh

# Configuration
#########################################
plugin="footonsat"
rm="FootOnSat"
section="addons"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"
version=$(wget $git_url/version -qO- | awk 'NR==1')
plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"
targz_file="$plugin.tar.gz"
url="https://github.com/eliesatpanelgrid/oe2.0/releases/download/footonsat/footonsat.tar.gz"
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

#check and install dependencies
#########################################
# Detect OS
if [ -f /etc/apt/apt.conf ]; then
    OS="DreamOS"
    PM_UPDATE="apt-get update"
    PM_INSTALL="apt-get install -y"
    STATUS="/var/lib/dpkg/status"
else
    OS="Opensource"
    PM_UPDATE="opkg update"
    PM_INSTALL="opkg install"
    STATUS="/var/lib/opkg/status"
fi

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    aarch64) DEVICE="arm64" ;;
    armv7l)  DEVICE="arm" ;;
    mips*)   DEVICE="mips" ;;
    sh4)     DEVICE="sh4" ;;
    *)       DEVICE="unknown" ;;
esac

# Core system tools (same for PY2 and PY3)
DEPS="curl ffmpeg gstreamer1.0-plugins-bad-mpegtsmux"

# Detect Python version and assign appropriate python packages
if python --version 2>&1 | grep -q '^Python 3\.'; then
    echo "Python 3 environment detected."
    PY_DEPS="
    python3-requests
    python3-beautifulsoup4
    python3-pillow
    python3-six
    python3-sqlite3
    python3-ujson
    python3-difflib
    python3-threading
    python3-json
    python3-io
    python3-email
    python3-datetime
    "
else
    echo "Python 2 environment detected."
    PY_DEPS="
    python-requests
    python-beautifulsoup4
    python-imaging
    python-six
    python-sqlite3
    python-ujson
    python-difflib
    python-threading
    python-json
    python-io
    python-email
    python-datetime
    "
fi

DEPS="$DEPS $PY_DEPS"

# Enigma2 playback deps (Only for Opensource)
if [ "$OS" != "DreamOS" ]; then
    DEPS="$DEPS enigma2-plugin-systemplugins-serviceapp exteplayer3 alsa-utils-aplay"
fi

# DreamOS extra
if [ "$OS" = "DreamOS" ] && [ "$DEVICE" = "arm64" ]; then
    DEPS="$DEPS gdb"
fi

# Function to check if installed
is_installed() {
    grep -q "Package: $1$" "$STATUS" 2>/dev/null
}

MISSING_PKGS=""

# Check missing packages
for pkg in $DEPS; do
    if is_installed "$pkg"; then
        echo "[OK] $pkg"
    else
        echo "[MISSING] $pkg"
        MISSING_PKGS="$MISSING_PKGS $pkg"
    fi
done

# Install all missing packages in ONE fast batch command
if [ -n "$MISSING_PKGS" ]; then
    echo ""
    echo "Updating package lists..."
    $PM_UPDATE >/dev/null 2>&1
    
    echo "Installing missing dependencies:$MISSING_PKGS"
    $PM_INSTALL $MISSING_PKGS
fi

# Special fix for ujson on DreamOS if missing from feed
if [ "$OS" = "DreamOS" ] && ! is_installed "python3-ujson" && ! is_installed "python-ujson"; then
    echo ""
    echo "[FIX] Installing ujson manually..."

    cd /tmp || exit 1

    case "$DEVICE" in
        arm)
            wget -q https://raw.githubusercontent.com/fairbird/FootOnsat/main/Download/Pacakges/python/python-ujson_1.35-r0.0_armhf.deb
            ;;
        mips)
            wget -q https://raw.githubusercontent.com/fairbird/FootOnsat/main/Download/Pacakges/python/python-ujson_1.35-r0.0_mipsel.deb
            ;;
    esac

    if ls *.deb >/dev/null 2>&1; then
        dpkg -i --force-overwrite *.deb >/dev/null 2>&1
        apt-get install -f -y >/dev/null 2>&1
        rm -f *.deb
    fi
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
