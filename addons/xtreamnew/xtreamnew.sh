#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/xtreamnew/xtreamnew.sh

# Configuration
#########################################
plugin="xtreamnew"
rm="XtreamNew"
section="addons"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"

version=$(wget $git_url/version -qO- | awk 'NR==1')
plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"

temp_dir="/tmp"

# Dynamic System Detection (Python Version & Architecture)
#########################################
# 1. Detect Python Version (3.13 or 3.14)
PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null)

case "$PY_VER" in
    3.13) PY_TAG="py3.13" ;;
    3.14) PY_TAG="py3.14" ;;
    *) 
        echo "> Error: Unsupported Python version ($PY_VER). Requires Python 3.13 or 3.14."
        exit 1
        ;;
esac

# 2. Detect Architecture (arm64 or armv7)
SYS_ARCH=$(uname -m)

case "$SYS_ARCH" in
    aarch64|arm64) ARCH_TAG="arm64" ;;
    armv7l|armhf|armv7) ARCH_TAG="armv7" ;;
    *) 
        echo "> Error: Unsupported architecture ($SYS_ARCH). Requires arm64 or armv7."
        exit 1
        ;;
esac

# Construct tar.gz filename and URL dynamically
targz_file="${plugin}_${PY_TAG}_${ARCH_TAG}.tar.gz"
url="$git_url/$targz_file"

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

# Check and remove old version
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
    exit 1     # Early exit preserved
else
    echo " " 
fi
}
check_and_remove_package

# Download & Install Dependencies
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

DEPS=""

# Check if installed
is_installed() {
    if [ "$OS" = "DreamOS" ]; then
        dpkg -s "$1" >/dev/null 2>&1
    else
        opkg list-installed | grep -wq "$1"
    fi
}

# Install deps if specified
if [ -n "$DEPS" ]; then
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

# Download & Install Package
#########################################
print_message() {
    echo "> [$(date +'%Y-%m-%d')] $1"
}

download_and_install_package() {
    print_message "> Detected environment: Python $PY_VER on $ARCH_TAG"
    print_message "> Downloading $targz_file, please wait ..."
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
    fi
}

download_and_install_package
