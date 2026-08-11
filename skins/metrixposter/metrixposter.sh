#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/skins/metrixposter/metrixposter.sh

# Configuration
#########################################
plugin="metrixposter"
rm="metrixposter"
section="skins"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"
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


PY_DEPENDS="requests core json"
SYS_DEPENDS=""

grep -iq "openatv" /etc/issue /etc/image-version /etc/os-release 2>/dev/null && [ -d "/usr/share/enigma2/MetrixHD/" ] || exit 1

command -v opkg >/dev/null 2>&1 && PM="opkg" || PM="apt"
command -v python3 >/dev/null 2>&1 && PFX="python3-" || PFX="python-"

for d in $PY_DEPENDS; do LIST="$LIST ${PFX}$d"; done
LIST="$LIST $SYS_DEPENDS"

is_installed() {
    [ "$PM" = "opkg" ] && { grep -q "^Package: $1$" /var/lib/opkg/status 2>/dev/null || opkg list-installed 2>/dev/null | grep -q "^$1[[:space:]-]"; } && return 0
    [ "$PM" = "apt" ] && dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed" && return 0
    return 1
}

if [ -n "$LIST" ]; then
    [ "$PM" = "opkg" ] && opkg update >/dev/null 2>&1
    [ "$PM" = "apt" ] && apt-get update >/dev/null 2>&1

    for pkg in $LIST; do
        if ! is_installed "$pkg"; then
            [ "$PM" = "opkg" ] && opkg install "$pkg" >/dev/null 2>&1
            [ "$PM" = "apt" ] && DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >/dev/null 2>&1
            is_installed "$pkg" || exit 1
        fi
    done
fi

sync

#download & install package
#########################################
print_message() {
echo "> [$(date +'%Y-%m-%d')] $1"
}
download_and_install_package() {
print_message "> Downloading $plugin-$version package  please wait ..."
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
fi  }
download_and_install_package
