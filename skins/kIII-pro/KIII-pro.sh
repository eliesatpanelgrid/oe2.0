#!/bin/sh

# Configuration
#########################################
plugin="kIII-pro"
rm="KIII-pro"
section="skins"

# Fixed path formatting (Ensure exact case match on GitHub)
git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"
version=$(wget $git_url/version -qO- | awk 'NR==1')

# Fallback version if version file is missing on server
if [ -z "$version" ]; then
    version="1.0"
fi

plugin_path="/usr/share/enigma2/$rm"
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

# Check and remove old version
#########################################
check_and_remove_package() {
    if [ -d "$plugin_path" ]; then
        echo "> Removing old version, please wait..."
        sleep 2
        rm -rf "$plugin_path" > /dev/null 2>&1

        if grep -q "$package" "$status_file"; then
            echo "> Removing existing $package package, please wait..."
            $uninstall_command $package > /dev/null 2>&1
        fi
        echo "*******************************************"
        echo "*       Old Version Removed Successfully   *"
        echo "*            Maintained by Eliesat         *"
        echo "*******************************************"
        sleep 2
        echo
        exit 1
    else
        echo "> No previous installation found. Proceeding..."
    fi
}
check_and_remove_package

# Download & install dependencies
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

# Download & install package
#########################################
print_message() {
    echo "> [$(date +'%Y-%m-%d')] $1"
}

download_and_install_package() {
    print_message "Downloading $plugin-$version package, please wait..."
    sleep 2
    wget --show-progress -qO "$temp_dir/$targz_file" --no-check-certificate "$url"
    
    if [ ! -s "$temp_dir/$targz_file" ]; then
        print_message "Error: Downloaded file is empty or missing at $url"
        exit 1
    fi

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
        print_message "Maintained By ElieSatpanelgrid team"
        echo
        sleep 2
    else
        print_message "$plugin-$version package extraction failed"
        sleep 2
    fi
}

download_and_install_package
