#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/foreca-one/foreca-one.sh

# Configuration
#########################################
plugin="foreca-one"
rm="Foreca1"
section="addons"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"
version=$(wget $git_url/version -qO- | awk 'NR==1')
plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
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
rm -rf "/usr/lib/enigma2/python/Plugins/Extensions/vavoo"
rm -f "/tmp/vavoo.log" > /dev/null 2>&1
rm -f "/tmp/vavookey" > /dev/null 2>&1
find /tmp -name "*.m3u" -exec rm -f {} \; > /dev/null 2>&1

find /etc/enigma2 -name "*vavoo*" -exec rm -f {} \; > /dev/null 2>&1
find /etc/enigma2 -name "*subbouquet.vavoo*" -exec rm -f {} \; > /dev/null 2>&1

for bouquet_file in /etc/enigma2/bouquets.*; do
sed -i '/vavoo/d' "$bouquet_file" > /dev/null 2>&1
done

wget -q -O - "http://127.0.0.1/web/servicelistreload?mode=0" > /dev/null 2>&1

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
