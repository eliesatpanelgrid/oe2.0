#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/skins/premium-fhd/premium-fhd-black.sh

# Configuration
#########################################
plugin="premium-fhd-black"
rm="Premium-FHD-Black"
section="skins/premium-fhd"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section"
version=$(wget $git_url/version -qO- | awk 'NR==1')
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

#check and_remove package old version
#########################################
check_and_remove_package() {
    if [ -d "$plugin_path" ]; then
        echo "> removing package old version please wait..."
        sleep 3 
        rm -rf "$plugin_path" > /dev/null 2>&1

        if grep -q "$package" "$status_file"; then
            echo "> Removing existing $package package, please wait..."
            $uninstall_command "$package" > /dev/null 2>&1
        fi
        echo "*******************************************"
        echo "*       Removal Completed Successfully   *"
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

# Required packages
DEPS="enigma2-plugin-extensions-bitrate
enigma2-plugin-extensions-oaweather 
enigma2-plugin-extensions-atilehd"

# Check if installed
is_installed() {
    if [ "$OS" = "DreamOS" ]; then
        dpkg -s "$1" >/dev/null 2>&1
    else
        opkg list-installed | grep -wq "$1"
    fi
}

# Install deps
if [ -n "$DEPS" ]; then
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

#download & install package
#########################################
print_message() {
    echo "> [$(date +'%Y-%m-%d')] $1"
}

download_and_install_package() {
    print_message "> Downloading $plugin-$version package  please wait ..."
    sleep 3
    wget --show-progress -qO "$temp_dir/$targz_file" --no-check-certificate "$url"
    tar -xzf "$temp_dir/$targz_file" -C / > /dev/null 2>&1
    extract=$?
    rm -rf "$temp_dir/$targz_file" >/dev/null 2>&1

    if [ $extract -eq 0 ]; then
        # Post-extraction image adjustments
        SKINDIR='/usr/share/enigma2/Premium-FHD-Black'
        TMPDIR='/tmp'

        if [ -d "$SKINDIR" ]; then
            if grep -qs -i "openATV" /etc/image-version; then
                [ -f "$SKINDIR/image_logo/openatv/imagelogo.png" ] && mv "$SKINDIR/image_logo/openatv/imagelogo.png" "$SKINDIR"
            elif grep -qs -i "egami" /etc/image-version; then
                [ -f "$SKINDIR/image_logo/egami/imagelogo.png" ] && mv "$SKINDIR/image_logo/egami/imagelogo.png" "$SKINDIR"
            elif grep -qs -i "PURE2" /etc/image-version; then
                [ -f "$SKINDIR/image_logo/pure2/imagelogo.png" ] && mv "$SKINDIR/image_logo/pure2/imagelogo.png" "$SKINDIR"
            elif grep -qs -i "OpenSPA" /etc/image-version; then
                [ -f "$SKINDIR/image_logo/openspa/imagelogo.png" ] && mv "$SKINDIR/image_logo/openspa/imagelogo.png" "$SKINDIR"
            fi

            if [ -f "$SKINDIR/pfiles/premiumcomponents.tar.gz" ]; then
                mv -f "$SKINDIR/pfiles/premiumcomponents.tar.gz" "$TMPDIR"
                tar -xzf "$TMPDIR/premiumcomponents.tar.gz" -C "$TMPDIR"
                cp -r "$TMPDIR/usr" /
            fi

            rm -rf "$SKINDIR/pfiles" "$SKINDIR/image_logo" /CONTROL "$TMPDIR/premiumcomponents.tar.gz" "$TMPDIR/usr" > /dev/null 2>&1
        fi

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
