#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/myhits/myhits.sh

# Configuration
#########################################
plugin="myhits"
rm="MyHits"
section="addons"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"
version=$(wget $git_url/version -qO- | awk 'NR==1')

plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"
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

# Check and remove package old version
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

# Detect Architecture and Python
#########################################
ARCH=$(uname -m)
case "$ARCH" in
    aarch64) 
        ARCH_IPK="aarch64" 
        ;;
    armv7l|armhf) 
        if grep -q "Cortex-A15" /proc/cpuinfo 2>/dev/null; then
            ARCH_IPK="cortexa15hf-neon-vfpv4"
        else
            ARCH_IPK="armv7ahf-neon"
        fi
        ;;
    *) 
        ARCH_IPK="armv7ahf-neon" 
        ;;
esac

PY=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null)

case "$PY" in
    3.*) ;;
    *) echo "> Python $PY is not supported"; exit 1 ;;
esac

# Define IPK filename and download URL
ipk_file="${package}_${version}_${ARCH_IPK}_py${PY}.ipk"
url="$git_url/$ipk_file"

# Download & install package
#########################################
print_message() {
echo "> [$(date +'%Y-%m-%d')] $1"
}

download_and_install_package() {
print_message "> Downloading $plugin-$version package  please wait ..."
sleep 3
wget --no-check-certificate "$url" -O "$temp_dir/$ipk_file"

if [ -f "$temp_dir/$ipk_file" ] && [ -s "$temp_dir/$ipk_file" ]; then
    opkg install "$temp_dir/$ipk_file" > /dev/null 2>&1
    install_status=$?
    
    if [ $install_status -eq 0 ]; then
        print_message "> $plugin-$version package installed successfully"
        cleanup() {
            [ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
            rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ipk >/dev/null 2>&1
        }
        cleanup
        print_message "> Maintained By ElieSatpanelgrid team"
        echo
        sleep 3
    else
        print_message "> $plugin-$version package installation failed"
        rm -rf "$temp_dir/$ipk_file" >/dev/null 2>&1
        sleep 3
    fi
else
    print_message "> $plugin-$version package download failed"
    sleep 3
fi
}

download_and_install_package
