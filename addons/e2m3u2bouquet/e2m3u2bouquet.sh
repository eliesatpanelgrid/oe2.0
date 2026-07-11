#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/e2m3u2bouquet/e2m3u2bouquet.sh

# Configuration
#########################################
plugin="e2m3u2bouquet"
rm="E2m3u2bouquet"
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

# check and_remove package old version (Kept exactly as requested)
#########################################
check_and_remove_package() {
if [ -d $plugin_path ]; then
echo "> removing package old version please wait..."
sleep 3 
rm -rf $plugin_path > /dev/null 2>&1

[ "$1" != "upgrade" ] || exit 0
PluginName="E2m3u2bouquet"

sed -i '/e2m3u2b_/d' /etc/enigma2/bouquets.tv
find /etc/enigma2/ -type f -name "*e2m3u2b_*" -exec rm {} +

rm -r /usr/lib/enigma2/python/Plugins/Extensions/"$PluginName" >/dev/null 2>&1

mpoint=""
backup="/var/tmp"

for var in sda mmcblk0 mmcblk1; do
    if [ -f "/sys/block/$var/queue/rotational" ]; then
        for var1 in hdd usb mmc; do
            if mount | grep -q "/media/$var1"; then
                mpoint="/media/$var1"
                break 2
            fi
        done
    fi
done

[ -n "$mpoint" ] && backup="$mpoint/tmp" || mpoint="/etc/enigma2"
mkdir -p "$backup" >/dev/null 2>&1
mv -f "$mpoint/$PluginName" "$backup" >/dev/null 2>&1

if grep -q "$package" "$status_file"; then
echo "> Removing existing $package package, please wait..."
$uninstall_command $package > /dev/null 2>&1
fi
echo "*******************************************"
echo "* Removal Completed Successfully   *"
echo "* Maintained by Eliesat        *"
echo "*******************************************"
sleep 3
echo
exit 1
else
echo " " 
fi  }
check_and_remove_package

# Config Processing (Fixed: Removed the hard exit 0)
#########################################
config_processing() {
    mkdir -p "$1/epgimport" "$1/override" >/dev/null 2>&1
    [ -d "$2/override" ] && mv -f "$2/override" "$1" >/dev/null 2>&1
    [ -f "$2/config.xml" ] && mv -n "$2/config.xml" "$1" >/dev/null 2>&1
    [ -f "$2/groups.db" ] && mv -n "$2/groups.db" "$1" >/dev/null 2>&1
    rm -r "$2" >/dev/null 2>&1
    # 'exit 0' removed here so script successfully moves forward to the download phase
}

mpoint=""
backup="/tmp"

for var in sda mmcblk0 mmcblk1; do
    if [ -f "/sys/block/$var/queue/rotational" ]; then
        for var1 in hdd usb mmc; do
            if mount | grep -q "/media/$var1"; then
                mpoint="/media/$var1"
                break 2
            fi
        done
    fi
done

[ -n "$mpoint" ] && backup="$mpoint/tmp" || mpoint="/etc/enigma2"
config_processing "$mpoint/E2m3u2bouquet" "$backup/E2m3u2bouquet"

# download & install dependencies
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
    3.9|3.10|3.11|3.12|3.13) ;;
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

# download & install package
#########################################
print_message() {
echo "> [$(date +'%Y-%m-%d')] $1"
}
download_and_install_package() {
print_message "> Downloading $plugin-$version package  please wait ..."
sleep 3
wget --show-progress -qO $temp_dir/$targz_file --no-check-certificate "$url"
tar -xzf $temp_dir/$targz_file -C / > /dev/null 2>&1
extract=$?
rm -rf $temp_dir/$targz_file >/dev/null 2>&1

if [ $extract -eq 0 ]; then
PluginName="E2m3u2bouquet"

for cmd in python python3; do
    pyver=$($cmd -V 2>&1 | grep -oE '[0-9]+\.[0-9]+' | tr -d '.')
    [[ $pyver =~ ^[0-9]+$ ]] && break
done

if [[ ! $pyver =~ ^[0-9]+$ ]]; then
    exit 1
fi

path="/usr/lib/enigma2/python"
destination="$path/Plugins/Extensions/$PluginName"
link="$path/Components/Renderer/_RunningText.py"

[ ! -L "$link" ] && ln -s "$destination/_RunningText.py" "$link" >/dev/null 2>&1

if cp -a /tmp/"$pyver"/. "$destination" >/dev/null 2>&1; then
    find /tmp/ -name '[0-9]*' -type d -exec rm -r {} + >/dev/null 2>&1
    find ./ /tmp/ -name "enigma2-plugin-extensions-${PluginName,,}_*" -type f -exec rm {} + >/dev/null 2>&1
    
    pkg_mgr="opkg"
    type systemctl >/dev/null 2>&1 && pkg_mgr="dpkg"
    list_path="/var/lib/$pkg_mgr/info/enigma2-plugin-extensions--${PluginName,,}.list"
    
    sed -i -e "/^\/tmp/d" -e "/^$/d" "$list_path" >/dev/null 2>&1
else
    exit 1
fi
  print_message "> $plugin-$version package installed successfully"
cleanup() {
[ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ik /tmp/*.tar.gz >/dev/null 2>&1
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
