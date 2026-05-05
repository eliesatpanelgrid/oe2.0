#!/bin/bash

# Configuration
pack="enigma2-plugin-softcams-oscam"
version="11.725-emu-r798"
package="$pack"

#determine package manager
if [ "$package_manager" == "apt" ]; then
    ipk="${pack}_${version}.deb"
    install_command="dpkg -i --force-overwrite"
    uninstall_command="apt-get purge --auto-remove -y"
else
    ipk="${pack}_${version}.ipk"
    install_command="opkg install --force-reinstall"
    uninstall_command="opkg remove --force-depends"
fi
url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/softcams/linuxsat25/$ipk"
temp_dir="/tmp"

# Determine package manager
if command -v dpkg &> /dev/null; then
    package_manager="apt"
    status_file="/var/lib/dpkg/status"
else
    package_manager="opkg"
    status_file="/var/lib/opkg/status"
fi

# Functions
print_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

cleanup() {
    [ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
    rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1
}

check_and_install_package() {
    if grep -q "$package" "$status_file"; then
        print_message "Removing existing $package package, please wait..."
        $uninstall_command $package
    fi

    print_message "Downloading $pack-$version, please wait..."
    wget -q --show-progress $url -P "$temp_dir"
    if [ $? -ne 0 ]; then
        print_message "Failed to download $pack-$version from $url"
    trap cleanup EXIT
        exit 1
    fi

    print_message "Installing $pack-$version, please wait..."
    $install_command "$temp_dir/$ipk"
    if [ $? -eq 0 ]; then
        print_message "$pack-$version installed successfully."
    else
        print_message "Installation failed."
        exit 1
    fi
}
# Main
trap cleanup EXIT
check_and_install_package
echo
sleep 3
exit 1

