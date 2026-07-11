#!/bin/sh
#https://github.com/eliesatpanelgrid/oe2.0/blob/main/addons/multiquickbutton/multiquickbutton-obh.tar.gz

# Configuration
#########################################
plugin="multiquickbutton"
rm="MultiQuickButton"
section="addons"

if [ -f /etc/image-version ]; then
    image=$(cat /etc/image-version | grep -iF "creator" | cut -d"=" -f2 | xargs)
elif [ -f /etc/issue ]; then
    image=$(cat /etc/issue | head -n1 | awk '{print $1;}')
else
    image=''
fi

image_lower=$(echo "$image" | tr '[:upper:]' '[:lower:]')

[[ ! -z "$image" ]] && echo "> Image detected: $image"
sleep 1

if [[ "$image_lower" == *"openbh"* || "$image_lower" == *"openblackhole"* || "$image_lower" == *"obh"* ]]; then
    plugin1="multiquickbutton-obh"

elif [[ "$image_lower" == *"openvix"* || "$image_lower" == *"vix"* ]]; then
    plugin1="multiquickbutton-ovix"

else
    echo "> Your image ($image) is not supported"
    exit 1
fi

# FIXED: URL pointing to the correct repository structure and using ?raw=true for binaries
git_url="https://github.com/eliesatpanelgrid/oe2.0/raw/main/$section/$plugin"
version=$(wget https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin/version -qO- | awk 'NR==1')
plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"

# FIXED: Target file changes dynamically based on image detection
targz_file="$plugin1.tar.gz" 
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

# check and remove package old version
#########################################
check_and_remove_package() {
    if [ -d "$plugin_path" ]; then
        echo "> removing package old version please wait..."
        sleep 3 
        rm -rf "$plugin_path" > /dev/null 2>&1
        rm -rf /etc/MultiQuickButton > /dev/null 2>&1

        if grep -q "$package" "$status_file"; then
            echo "> Removing existing $package package, please wait..."
            $uninstall_command "$package" > /dev/null 2>&1
        fi
        echo "*******************************************"
        echo "* Removal Completed Successfully   *"
        echo "* Maintained by Eliesat        *"
        echo "*******************************************"
        sleep 3
        exit 1
    else
        echo
    fi  
}
check_and_remove_package

# download & install dependencies
#######################################
if command -v apt-get >/dev/null 2>&1; then
    OS="DreamOS"
    PM_UPDATE="apt-get update"
    PM_INSTALL="apt-get install -y"
else
    OS="Opensource"
    PM_UPDATE="opkg update"
    PM_INSTALL="opkg install"
fi

ARCH=$(uname -m)
case "$ARCH" in
    aarch64) DEVICE="arm64" ;;
    armv7l|armhf) DEVICE="arm" ;;
    mips|mipsel) DEVICE="mips" ;;
    sh4) DEVICE="sh4" ;;
    *) DEVICE="unknown" ;;
esac

PY=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null)

case "$PY" in
    3.9|3.10|3.11|3.12|3.13|3.14) ;;
    *) echo "> Python $PY is not supported"; exit 1 ;;
esac

DEPS=""

is_installed() {
    if [ "$OS" = "DreamOS" ]; then
        dpkg -s "$1" >/dev/null 2>&1
    else
        opkg list-installed | grep -wq "$1"
    fi
}

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
            if $PM_INSTALL "$pkg" >/dev/null 2>&1; then
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
    print_message "Downloading $plugin-$version package please wait ..."
    sleep 3
    
    # Download the corrected URL setup
    wget --show-progress -qO "$temp_dir/$targz_file" --no-check-certificate "$url"
    
    tar -xzf "$temp_dir/$targz_file" -C / > /dev/null 2>&1
    extract=$?
    rm -rf "$temp_dir/$targz_file" >/dev/null 2>&1

    if [ $extract -eq 0 ]; then
        print_message "$plugin-$version package installed successfully"
        cleanup() {
            [ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
            rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1
        }
        cleanup
        # FIXED: Merged broken split word line back together
        print_message "Maintained By ElieSatpanelgrid team" 
        echo
        sleep 3
    else
        print_message "$plugin-$version package download failed"
        sleep 3
    fi  
}
download_and_install_package
