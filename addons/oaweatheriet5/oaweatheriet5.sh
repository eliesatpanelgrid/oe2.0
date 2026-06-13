#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/oaweatheriet5/oaweatheriet5.sh

# Configuration
#########################################
plugin="oaweatheriet5"
rm="OAWeatheriet5"
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

PLUGIN_PATH="/usr/lib/enigma2/python/Plugins/Extensions/OAWeatheriet5"

if [ -x "/etc/init.d/oaweatheriet5" ]; then
    /etc/init.d/oaweatheriet5 stop >/dev/null 2>&1 || true
fi

if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-units 2>/dev/null | grep -q "oaweatheriet5"; then
        systemctl stop oaweatheriet5 >/dev/null 2>&1 || true
        systemctl disable oaweatheriet5 >/dev/null 2>&1 || true
    fi
fi

if [ -d "$PLUGIN_PATH/logs" ]; then
    rm -f "$PLUGIN_PATH/logs/"* >/dev/null 2>&1 || true
fi
find "$PLUGIN_PATH" -name "*.pyo" -exec rm -f {} \; >/dev/null 2>&1 || true
find "$PLUGIN_PATH" -name "*.pyc" -exec rm -f {} \; >/dev/null 2>&1 || true
find "$PLUGIN_PATH" -name "__pycache__" -type d -exec rm -rf {} \; >/dev/null 2>&1 || true

rm -f /tmp/diskcputemp.log >/dev/null 2>&1 || true
rm -f /tmp/oaweatheriet5* >/dev/null 2>&1 || true

sync >/dev/null 2>&1 || true

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

CURRENT_PKG="enigma2-plugin-extensions-oaweatheriet5"
REPLACES_PKG="enigma2-plugin-extensions-oaweatheriet5"
PLUGIN_PATH="/usr/lib/enigma2/python/Plugins/Extensions/OAWeatheriet5"

if [ "$CURRENT_PKG" != "$REPLACES_PKG" ]; then
    if command -v opkg >/dev/null 2>&1; then
        if opkg list-installed 2>/dev/null | grep -q "^$REPLACES_PKG "; then
            echo "Removing conflicting opkg package: $REPLACES_PKG"
            opkg remove --force-depends "$REPLACES_PKG" >/dev/null 2>&1 || opkg remove "$REPLACES_PKG" >/dev/null 2>&1 || true
        fi
    fi
fi

if [ "$CURRENT_PKG" != "$REPLACES_PKG" ]; then
    if command -v dpkg >/dev/null 2>&1; then
        if dpkg -l 2>/dev/null | awk '{print $2}' | grep -qx "$REPLACES_PKG"; then
            dpkg -r "$REPLACES_PKG" >/dev/null 2>&1 || true
        fi
    fi
fi

if [ -d "$PLUGIN_PATH" ]; then
    find "$PLUGIN_PATH" -name "*.pyo" -exec rm -f {} \; >/dev/null 2>&1 || true
    find "$PLUGIN_PATH" -name "*.pyc" -exec rm -f {} \; >/dev/null 2>&1 || true
    find "$PLUGIN_PATH" -name "__pycache__" -type d -exec rm -rf {} \; >/dev/null 2>&1 || true
fi

sync >/dev/null 2>&1 || true

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
PLUGIN_PATH="/usr/lib/enigma2/python/Plugins/Extensions/OAWeatheriet5"

if [ -d "$PLUGIN_PATH" ]; then
  echo "Plugin path found: $PLUGIN_PATH"
else
  echo
fi

find "$PLUGIN_PATH" -name "*.pyo" -exec rm -f {} \; >/dev/null 2>&1 || true
find "$PLUGIN_PATH" -name "*.pyc" -exec rm -f {} \; >/dev/null 2>&1 || true
find "$PLUGIN_PATH" -name "__pycache__" -type d -exec rm -rf {} \; >/dev/null 2>&1 || true

find "$PLUGIN_PATH" -type d -exec chmod 755 {} \; >/dev/null 2>&1 || true
find "$PLUGIN_PATH" -type f -exec chmod 644 {} \; >/dev/null 2>&1 || true
find "$PLUGIN_PATH" -name "*.sh" -exec chmod 755 {} \; >/dev/null 2>&1 || true
find "$PLUGIN_PATH" -name "*.py" -exec chmod 644 {} \; >/dev/null 2>&1 || true

sync >/dev/null 2>&1 || true
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
