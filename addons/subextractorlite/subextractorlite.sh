#!/bin/sh
# https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/subextractorlite/subextractorlite.sh

# Configuration
#########################################
plugin="subextractorlite"
rm="SubExtractorLite" # Adjust folder name if needed
section="addons"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"
version=$(wget $git_url/version -qO- | awk 'NR==1')
plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"
temp_dir="/tmp"

tesseract_file="Tesseract_5.5.3_armv7l.tar.gz"
tesseract_url="$git_url/$tesseract_file"

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
        echo "> Removing old version of $plugin, please wait..."
        sleep 2 
        rm -rf "$plugin_path" > /dev/null 2>&1
        rm -rf /share/tessdata > /dev/null 2>&1

        if grep -q "$package" "$status_file"; then
            echo "> Removing existing $package package, please wait..."
            $uninstall_command $package > /dev/null 2>&1
        fi
        echo "*******************************************"
        echo "*        Removal Completed Successfully   *"
        echo "*            Maintained by Eliesat        *"
        echo "*******************************************"
        sleep 2
        echo
        exit 1
    fi
}
check_and_remove_package

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

# Detect Architecture
#########################################
ARCH=$(uname -m)
case "$ARCH" in
    armv7l|armhf|arm) 
        DEVICE="armv7l" 
        ;;
    *) 
        echo "> ERROR: $plugin is only supported on ARM (armv7l) architectures."
        echo "> Your architecture: $ARCH"
        exit 1 
        ;;
esac

# Detect Python Version
#########################################
PY=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null)

case "$PY" in
    3.12|3.13|3.14) 
        echo "> Python version $PY detected (Compatible)."
        ;;
    *) 
        echo "> ERROR: Python $PY is not supported."
        echo "> This plugin requires Python 3.12, 3.13, or 3.14."
        exit 1 
        ;;
esac

# Formulate specific package filename
#########################################
targz_file="${plugin}_${DEVICE}_py${PY}.tar.gz"
url="$git_url/$targz_file"

print_message() {
    echo "> [$(date +'%Y-%m-%d')] $1"
}

# Download & Install Package + Dependencies
#########################################
download_and_install_package() {
    print_message "Downloading $plugin-$version ($targz_file)..."
    sleep 2
    
    wget --show-progress -qO "$temp_dir/$targz_file" --no-check-certificate "$url"
    
    if [ ! -f "$temp_dir/$targz_file" ]; then
        print_message "Error: Download failed or file not found!"
        exit 1
    fi

    tar -xzf "$temp_dir/$targz_file" -C / > /dev/null 2>&1
    extract=$?
    rm -f "$temp_dir/$targz_file" >/dev/null 2>&1

    if [ $extract -eq 0 ]; then
        print_message "$plugin-$version installed successfully!"
        
        # Download and install Tesseract binary dependency
        print_message "Downloading Tesseract dependency ($tesseract_file)..."
        wget --show-progress -qO "$temp_dir/$tesseract_file" --no-check-certificate "$tesseract_url"
        
        if [ -f "$temp_dir/$tesseract_file" ]; then
            tar -xzf "$temp_dir/$tesseract_file" -C / > /dev/null 2>&1
            tess_extract=$?
            rm -f "$temp_dir/$tesseract_file" >/dev/null 2>&1
            
            if [ $tess_extract -eq 0 ]; then
                print_message "Tesseract 5.5.3 installed successfully!"
            else
                print_message "Failed to extract Tesseract dependency."
            fi
        else
            print_message "Failed to download Tesseract dependency."
        fi

        # Cleanup metadata files
        [ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
        rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1
        
        print_message "Installation Complete - Maintained By ElieSatpanelgrid team"
        echo
        sleep 2
    else
        print_message "$plugin-$version extraction failed!"
        exit 1
    fi
}

download_and_install_package
