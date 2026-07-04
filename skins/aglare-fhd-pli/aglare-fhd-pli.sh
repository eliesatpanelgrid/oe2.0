#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/skins/aglare-fhd-pli/aglare-fhd-pli.sh

# Configuration
#########################################
plugin="aglare-fhd-pli"
rm="Aglare-FHD-PLI"
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
rm -rf /usr/share/enigma2/Aglare-FHD-PLI  > /dev/null 2>&1
rm -rf /usr/lib/enigma2/python/Plugins/Extensions/Aglare  > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/Aglare* > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/Converter/Aglare* > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/Renderer/Aglare* > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/Renderer/Agp* > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/Renderer/Agb* > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/Renderer/Agban* > /dev/null 2>&1

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
DEPS="enigma2-plugin-extensions-bitrate python3-pillow"

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
set -e  # Exit on first error
SKINDIR='/usr/share/enigma2/Aglare-FHD-PLI'
WCDIR='/usr/share/enigma2/Aglare-FHD-PLI/main/windowcolor'
TMPDIR='/tmp'

echo "Supported Images are : "
echo "1- OpenPLI develop , OpenPLI 9 , OpenPLI 10 , OpenPLI 10.1 , OpenPLI 11.0"
echo "2- OBH 5.3 , 5.4 , 5.4.1 , 5.5.x , 5.6"
echo "3- OpenVIX 6.4 , 6.5 , 6.6 , 6,7 , 6.8 , 6.9"
echo "4- NonSoloSat"
echo "5- OpenTR"
echo "6- SatLodge"
echo "7- CobraliberoSat"
echo "8- TeamBlue 7.3 , 7.4 , 7.5"
echo "9- OpenPLI foxbob python 3.13"
echo "10- Corvoboys"
echo "11- TNAP"
sleep 2

# Copy Default window color
echo "Copying Default window color..."
cp "$WCDIR/w_Default/"* "$SKINDIR/window/"

echo "Identify your image ...."
sleep 2
if grep -qs -i "openbh" /etc/image-version; then
    echo "You have Openbh image"
	echo "Adjusting some files according to your image..."
	mv $SKINDIR/image_logo/obh/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/obh/top_logo.png $SKINDIR
	mv $SKINDIR/image_logo/skin_templates.xml $SKINDIR
	
elif grep -qs -i "openvix" /etc/image-version; then
    echo "You have OpenVix image"
	echo "Adjusting some files according to your image..."
	mv $SKINDIR/image_logo/openvix/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/openvix/top_logo.png $SKINDIR
	mv $SKINDIR/image_logo/skin_templates.xml $SKINDIR

elif grep -qs -i "openpli" /etc/issue; then
    if grep -qs -i "GCC-15" /etc/issue; then
        echo "You have OpenPli GCC-15.1 image"
        echo "Adjusting some files according to your image..."		
        mv $SKINDIR/image_logo/openplifoxbob/imagelogo.png $SKINDIR
        mv $SKINDIR/image_logo/openplifoxbob/top_logo.png $SKINDIR
        mv $SKINDIR/image_logo/skin_templates.xml $SKINDIR
    else
        echo "You have OpenPli image"
        echo "Adjusting some files according to your image..."		
        mv $SKINDIR/image_logo/openpli/imagelogo.png $SKINDIR
        mv $SKINDIR/image_logo/openpli/top_logo.png $SKINDIR
    fi

elif grep -qs -i "foxbob" /etc/issue; then
    echo "You have OpenPli foxbob image"
	echo "Adjusting some files according to your image..."		
	mv $SKINDIR/image_logo/openplifoxbob/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/openplifoxbob/top_logo.png $SKINDIR
	mv $SKINDIR/image_logo/skin_templates.xml $SKINDIR
	
elif grep -qs -i "corvoboys" /etc/image-version; then
    echo "You have CorvoBoys image"
	echo "Adjusting some files according to your image..."
	mv $SKINDIR/image_logo/corvoboys/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/corvoboys/top_logo.png $SKINDIR
	mv $SKINDIR/image_logo/corvoboys/picon_default.png $SKINDIR
	rm -rf $SKINDIR/spinner > /dev/null 2>&1
	rm -rf $SKINDIR/picon_default.png  > /dev/null 2>&1
	cp $SKINDIR/sf/little_logo.png $SKINDIR/picon_default.png
	
elif grep -qs -i "TNAP" /etc/issue; then
    echo "You have TNAP image"
	echo "Adjusting some files according to your image..."		
	mv $SKINDIR/image_logo/tnap/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/tnap/top_logo.png $SKINDIR

elif grep -qs -i "opentr" /etc/issue; then
    echo "You have OpenTR image"
	echo "Adjusting some files according to your image..."		
	mv $SKINDIR/image_logo/opentr/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/opentr/top_logo.png $SKINDIR

elif grep -qs -i "areadeltasat" /etc/issue; then
    echo "You have areadeltasat image"
	echo "Adjusting some files according to your image..."		
	mv $SKINDIR/image_logo/openpli/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/openpli/top_logo.png $SKINDIR

elif grep -qs -i "teamblue" /etc/issue; then
    echo "You have TeamBlue image"
	echo "Adjusting some files according to your image..."		
	mv $SKINDIR/image_logo/teamblue/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/teamblue/top_logo.png $SKINDIR

elif grep -qs -i "nonsolosat" /etc/issue; then
    echo "You have NonSoloSat image"
	echo "Adjusting some files according to your image..."		
	mv $SKINDIR/image_logo/nss/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/nss/top_logo.png $SKINDIR
	
elif grep -qs -i "cobraliberosat" /etc/issue; then
    echo "You have CobraliberoSat image"
	echo "Adjusting some files according to your image..."		
	mv $SKINDIR/image_logo/cobra/imagelogo.png $SKINDIR
	cp /usr/share/enigma2/Aglare-FHD-PLI/main/top_logo.png $SKINDIR/top_logo.png
	
elif grep -qs -i "satlodge" /etc/issue; then
    echo "You have SatLodge image"
	echo "Adjusting some files according to your image..."		
	mv $SKINDIR/image_logo/satlodge/imagelogo.png $SKINDIR
	mv $SKINDIR/image_logo/satlodge/top_logo.png $SKINDIR
	
else	
    echo "even you do not have supported image , you can try Aglare-FHD-PLI"
fi
echo "removing some files.... "
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
