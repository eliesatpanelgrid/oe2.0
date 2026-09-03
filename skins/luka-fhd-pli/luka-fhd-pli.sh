#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/skins/luka-fhd-pli/luka-fhd-pli.sh

# Configuration
#########################################
plugin="luka-fhd-pli"
rm="Luka-FHD-PLI"
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

SKINDIR='/usr/share/enigma2/Luka-FHD-PLI'
MCDIR='/usr/share/enigma2/Luka-FHD-PLI/main/maincolor'
TMPDIR='/tmp'
BOXMODEL=$(cat /etc/hostname)
set -e
cp $MCDIR/lkimages_crimson_blue/2ndinfobar3.png $SKINDIR/lkimages/2ndinfobar3.png
cp $MCDIR/lkimages_crimson_blue/ch_bg.jpg $SKINDIR/lkimages/ch_bg.jpg
cp $MCDIR/lkimages_crimson_blue/infobar.png $SKINDIR/lkimages/infobar.png
cp $MCDIR/lkimages_crimson_blue/menu_bg.png $SKINDIR/lkimages/menu_bg.png
echo "Identify your image ...."
sleep 2
if grep -qs -i "openbh" /etc/image-version; then
	mv $SKINDIR/image_logo/obh/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/skin_templates.xml $SKINDIR
	
elif grep -qs -i "openvix" /etc/image-version; then
	mv $SKINDIR/image_logo/openvix/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/skin_templates.xml $SKINDIR

elif grep -qs -i "openpli" /etc/issue; then
    if grep -qs -i "GCC-15" /etc/issue; then
        mv $SKINDIR/image_logo/openplifoxbob/imagelogo.png $SKINDIR
        mv $SKINDIR/image_logo/skin_templates.xml $SKINDIR
    else
        mv $SKINDIR/image_logo/openpli/imagelogo.png $SKINDIR
    fi

elif grep -qs -i "foxbob" /etc/issue; then
	mv $SKINDIR/image_logo/openplifoxbob/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/skin_templates.xml $SKINDIR
	
elif grep -qs -i "corvoboys" /etc/image-version; then
	mv $SKINDIR/image_logo/corvoboys/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/corvoboys/picon_default.png $SKINDIR
	rm -rf $SKINDIR/spinner > /dev/null 2>&1
	rm -rf $SKINDIR/picon_default.png  > /dev/null 2>&1
	cp $SKINDIR/sf/little_logo.png $SKINDIR/picon_default.png
	
elif grep -qs -i "TNAP" /etc/issue; then
	mv $SKINDIR/image_logo/tnap/imagelogo.png $SKINDIR

elif grep -qs -i "opentr" /etc/issue; then
	mv $SKINDIR/image_logo/opentr/imagelogo.png $SKINDIR

elif grep -qs -i "areadeltasat" /etc/issue; then
	mv $SKINDIR/image_logo/openpli/imagelogo.png $SKINDIR

elif grep -qs -i "teamblue" /etc/issue; then
	mv $SKINDIR/image_logo/teamblue/imagelogo.png $SKINDIR

elif grep -qs -i "nonsolosat" /etc/issue; then
	mv $SKINDIR/image_logo/nss/imagelogo.png $SKINDIR
	
elif grep -qs -i "cobraliberosat" /etc/issue; then		
	mv $SKINDIR/image_logo/cobra/imagelogo.png $SKINDIR
	
elif grep -qs -i "satlodge" /etc/issue; then
	mv $SKINDIR/image_logo/satlodge/imagelogo.png $SKINDIR
	
else	
    echo "even you do not have supported image , you can try Luka-FHD-PLI"
fi
sleep 2
rm -rf $SKINDIR/image_logo  > /dev/null 2>&1
rm -rf /control  > /dev/null 2>&1

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
