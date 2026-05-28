#!/bin/sh
# https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/myhybridiptv/myhybridiptv.sh

#########################################
# Detect Python
#########################################
PY=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null)

case "$PY" in
    3.13|3.14)
        plugin1="myhybridiptv_py$PY"
        ;;
    *)
        echo "> Python $PY is not supported"
        exit 1
        ;;
esac

#########################################
# Configuration
#########################################
plugin="myhybridiptv"
rm="MyHybridIPTV"
section="addons"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"

version=$(wget -qO- "$git_url/version" | awk 'NR==1')

plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"

targz_file="$plugin1.tar.gz"
url="$git_url/$targz_file"

temp_dir="/tmp"

#########################################
# Detect architecture
#########################################
ARCH=$(opkg print-architecture | grep "cortexa15hf-neon-vfpv4")

if [ -z "$ARCH" ]; then
    echo "Your device is not supported."
    exit 1
fi

#########################################
# Determine package manager
#########################################
if command -v dpkg >/dev/null 2>&1; then
    package_manager="apt"
    status_file="/var/lib/dpkg/status"
    uninstall_command="apt-get purge --auto-remove -y"
else
    package_manager="opkg"
    status_file="/var/lib/opkg/status"
    uninstall_command="opkg remove --force-depends"
fi

#########################################
# Check and remove old version
#########################################
check_and_remove_package() {

if [ -d "$plugin_path" ]; then

    echo "> removing package old version please wait..."
    sleep 3

    rm -rf "$plugin_path" >/dev/null 2>&1

    if grep -q "$package" "$status_file"; then
        echo "> Removing existing $package package, please wait..."
        $uninstall_command "$package" >/dev/null 2>&1
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
fi

}

check_and_remove_package
exit 0