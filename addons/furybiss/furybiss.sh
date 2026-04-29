#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/furybiss/furybiss.sh

# Configuration
#########################################
plugin="furybiss"
rm="FuryBiss"
section="addons"

# Detect python
PY=$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null)

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"
version=$(wget $git_url/version -qO- | awk 'NR==1')
plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"
ipk_file=""$plugin"_"$PY".ipk"
url="$git_url/$ipk_file"
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

# Required packages
DEPS=""

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

print_message() {
    echo "> [$(date +'%Y-%m-%d')] $1"
}

#download & install package
#########################################
download_and_install_package() {
    print_message "> Downloading $plugin-$version package  please wait ..."
    sleep 3

    wget --no-check-certificate --show-progress -qO $temp_dir/$ipk_file $url
    dl_status=$?

    if [ $dl_status -ne 0 ] || [ ! -f "$temp_dir/$ipk_file" ]; then
        print_message "> $plugin-$version package download failed"
        sleep 3
        return 1
    fi

    if command -v opkg >/dev/null 2>&1; then
        opkg update >/dev/null 2>&1
        opkg install --force-reinstall $temp_dir/$ipk_file
        install_status=$?
    elif command -v dpkg >/dev/null 2>&1; then
        dpkg -i $temp_dir/$ipk_file
        install_status=$?
    else
        print_message "> No supported package manager found"
        return 1
    fi

    rm -f $temp_dir/$ipk_file >/dev/null 2>&1

    if [ $install_status -eq 0 ]; then
        echo
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
        print_message "> $plugin-$version installation failed"
        sleep 3
    fi
}
download_and_install_package
