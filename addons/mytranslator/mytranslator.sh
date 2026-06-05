#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/mytranslator/mytranslator.sh

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
plugin="mytranslator"
rm="MyTranslator"
section="addons"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"

version=$(wget -qO- "$git_url/version" | awk 'NR==1')

plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"

targz_file="$plugin1.tar.gz"
url="$git_url/$targz_file"

temp_dir="/tmp"

#########################################
# Detect ARM architecture
#########################################
if ! opkg print-architecture | grep -qi "arm"; then
    echo "> Your device is not ARM and is not supported."
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

#########################################
# Detect OS
#########################################
if command -v apt-get >/dev/null 2>&1; then
    OS="DreamOS"
    PM_UPDATE="apt-get update"
    PM_INSTALL="apt-get install -y"
else
    OS="Opensource"
    PM_UPDATE="opkg update"
    PM_INSTALL="opkg install"
fi

#########################################
# Required packages
#########################################
DEPS=""

#########################################
# Check installed package
#########################################
is_installed() {

    if [ "$OS" = "DreamOS" ]; then
        dpkg -s "$1" >/dev/null 2>&1
    else
        opkg list-installed | grep -wq "$1"
    fi

}

#########################################
# Install dependencies
#########################################
# Required packages
DEPS="python3-core"

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


#########################################
# Print messages
#########################################
print_message() {
    echo "> [$(date +'%Y-%m-%d')] $1"
}

#########################################
# Download and install package
#########################################
download_and_install_package() {

    print_message "Downloading $plugin-$version package please wait ..."
    sleep 3

    wget --show-progress -qO $temp_dir/$targz_file --no-check-certificate $url

    if [ $? -ne 0 ]; then
        print_message "$plugin-$version package download failed"
        sleep 3
        exit 1
    fi

    tar -xzf "$temp_dir/$targz_file" -C / >/dev/null 2>&1
    extract=$?

    rm -rf "$temp_dir/$targz_file" >/dev/null 2>&1

    if [ $extract -eq 0 ]; then

        print_message "$plugin-$version package installed successfully"

        cleanup() {
            [ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
            rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1
        }

        cleanup

        print_message "Maintained By ElieSatpanelgrid team"
        echo

        sleep 3

    else

        print_message "$plugin-$version package download failed"
        sleep 3

    fi

}

download_and_install_package
