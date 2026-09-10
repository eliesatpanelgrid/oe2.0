#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/xportal/xportal.sh

#########################################
# Detect Python
#########################################
if command -v python3 >/dev/null 2>&1; then
    PY=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null)
elif command -v python >/dev/null 2>&1; then
    PY=$(python -c 'import sys; print("%s.%s" % (sys.version_info[0], sys.version_info[1]))' 2>/dev/null)
else
    PY=""
fi

case "$PY" in
    2.7)
        PY_TAG="py2_7"
        ;;
    3.9)
        PY_TAG="py3_9"
        ;;
    3.12)
        PY_TAG="py3_12"
        ;;
    3.13)
        PY_TAG="py3_13"
        ;;
    3.14)
        PY_TAG="py3_14"
        ;;
    *)
        echo "> Python $PY is not supported"
        exit 1
        ;;
esac

#########################################
# Detect Architecture
#########################################
ARCH=""

if command -v opkg >/dev/null 2>&1; then
    ARCH_INFO=$(opkg print-architecture)
elif command -v dpkg >/dev/null 2>&1; then
    ARCH_INFO=$(dpkg --print-architecture)
else
    ARCH_INFO=""
fi

SYS_ARCH=$(uname -m)

if echo "$SYS_ARCH" | grep -qi "aarch64" || echo "$ARCH_INFO" | grep -qi "aarch64"; then
    ARCH="aarch64"
elif echo "$SYS_ARCH" | grep -qi "arm" || echo "$ARCH_INFO" | grep -qi "arm"; then
    ARCH="arm"
elif echo "$SYS_ARCH" | grep -qi "mips" || echo "$ARCH_INFO" | grep -qi "mips"; then
    ARCH="mips"
else
    echo "> Your device architecture is not supported."
    exit 1
fi

# Check compatibility for AArch64 (only Python 3.14 exists in the repository list)
if [ "$ARCH" = "aarch64" ] && [ "$PY_TAG" != "py3_14" ]; then
    echo "> Python $PY on $ARCH is not supported"
    exit 1
fi

#########################################
# Configuration
#########################################
plugin="xportal"
rm="XPortal"
section="addons"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"

version=$(wget -qO- "$git_url/version" | awk 'NR==1')

plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"

targz_file="XPortal-${ARCH}-${PY_TAG}.tar.gz"
url="https://github.com/eliesatpanelgrid/oe2.0/releases/download/4.x/$targz_file"

temp_dir="/tmp"

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
DEPS="wget 
python3-requests 
python3-twisted
python-requests 
python-twisted enigma2-plugin-systemplugins-serviceapp
exteplayer3"

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

    tar -xzf "$temp_dir/$targz_file" -C "$temp_dir" >/dev/null 2>&1
    extract=$?
    
    rm -rf "$temp_dir/$targz_file" >/dev/null 2>&1

    if [ $extract -eq 0 ]; then
        mv "$temp_dir/$rm" /usr/lib/enigma2/python/Plugins/Extensions/
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

