#!/bin/sh

# Configuration
#########################################
plugin="skinparts-mnasr-7.4.4-r2"
# Raw URL pointing directly to your GitHub tar.gz file
url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/skins/skinparts/skinparts-mnasr-7.4.4-r2.tar.gz"
package="enigma2-plugin-skins-$plugin"
targz_file="$plugin.tar.gz"
temp_dir="/tmp"

# MetrixHD target path (Specific skinpart directory, NEVER the root MetrixHD folder)
plugin_path="/usr/share/enigma2/MetrixHD/skinparts/mnasr"

# Determine package manager
#########################################
if command -v dpkg > /dev/null 2>&1; then
    package_manager="apt"
    status_file="/var/lib/dpkg/status"
    uninstall_command="apt-get purge --auto-remove -y"
else
    package_manager="opkg"
    status_file="/var/lib/opkg/status"
    uninstall_command="opkg remove --force-depends"
fi

# Clean previous skinpart files safely
#########################################
cleanup_old_version() {
    if [ -d "$plugin_path" ]; then
        echo "> Removing old skinpart version..."
        rm -rf "$plugin_path" > /dev/null 2>&1
    fi

    if grep -q "$package" "$status_file"; then
        echo "> Removing existing $package package..."
        $uninstall_command "$package" > /dev/null 2>&1
    fi
}
cleanup_old_version

# Install required skin dependencies safely
#########################################
install_dependencies() {
    if command -v dpkg > /dev/null 2>&1; then
        apt-get update > /dev/null 2>&1
        apt-get install -y enigma2-plugin-skins-metrix-atv-fhd-icons enigma2-plugin-skins-metrix-atv-weather-icons > /dev/null 2>&1
    else
        opkg update > /dev/null 2>&1
        opkg install enigma2-plugin-skins-metrix-atv-fhd-icons enigma2-plugin-skins-metrix-atv-weather-icons > /dev/null 2>&1
    fi
}
install_dependencies

# Download and extract archive
#########################################
echo "> Downloading $plugin-$version package  please wait ..."

download_and_extract() {
    wget --show-progress -qO "$temp_dir/$targz_file" --no-check-certificate "$url"

    if [ -s "$temp_dir/$targz_file" ]; then
        tar -xzf "$temp_dir/$targz_file" -C / > /dev/null 2>&1
        extract_status=$?
        rm -f "$temp_dir/$targz_file" > /dev/null 2>&1

        if [ $extract_status -eq 0 ]; then
            echo "> metrix skin parts  installed successfully"
            echo "> Maintained By ElieSatpanelgrid team"
        fi
    else
        rm -f "$temp_dir/$targz_file" > /dev/null 2>&1
    fi
}
download_and_extract

# Remove residual installation scripts
#########################################
cleanup_installer() {
    [ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
    rm -f /control /postinst /preinst /prerm /postrm /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1
}
cleanup_installer
