#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/skins/fury/fury.sh

# Configuration
#########################################
plugin="fury-fhd"
rm="Fury-FHD"
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
rm -rf /usr/lib/enigma2/python/Plugins/Extensions/Fury  > /dev/null 2>&1
rm -rf /usr/share/enigma2/Fury-FHD  > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/fury* > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/Converter/fury* > /dev/null 2>&1
rm -r /usr/lib/enigma2/python/Components/Renderer/fury* > /dev/null 2>&1

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

SKINDIR='/usr/share/enigma2/Fury-FHD'
TMPDIR='/tmp'

RAW_DEVICE_INFO=""
for DEVICE_FILE in /proc/stb/info/boxtype /proc/stb/info/machinebuild /proc/stb/info/model /proc/stb/info/vumodel /proc/stb/info/oem /etc/hostname; do
    if [ -f "$DEVICE_FILE" ]; then
        RAW_DEVICE_INFO="$RAW_DEVICE_INFO $(cat "$DEVICE_FILE" 2>/dev/null)"
    fi
done
RAW_DEVICE_INFO="$RAW_DEVICE_INFO $(hostname 2>/dev/null)"
NORMALIZED_DEVICE_INFO=$(echo "$RAW_DEVICE_INFO" | tr '[:upper:]' '[:lower:]')

case "$NORMALIZED_DEVICE_INFO" in
    *sf8008mini*)
        FILE_MODEL="sf8008mini"
        ;;
    *sf8008m*)
        FILE_MODEL="sf8008m"
        ;;
    *sf8008*)
        FILE_MODEL="sf8008"
        ;;
    *)
        if [ -f /etc/hostname ]; then
            FILE_MODEL=$(cat /etc/hostname 2>/dev/null)
        elif [ -f /proc/stb/info/boxtype ]; then
            FILE_MODEL=$(cat /proc/stb/info/boxtype 2>/dev/null)
        else
            FILE_MODEL="unknown"
        fi
        ;;
esac

if command -v python3 >/dev/null 2>&1; then
    PYVER=$(python3 -c 'import sys; print("{}.{}".format(sys.version_info.major, sys.version_info.minor))' 2>/dev/null)
elif command -v python >/dev/null 2>&1; then
    PYVER=$(python -c 'import sys; print(str(sys.version_info[0]) + "." + str(sys.version_info[1]))' 2>/dev/null)
else
    PYVER=""
fi

LOGO_FOLDER="main"
if grep -qs -i "openATV" /etc/image-version; then
    LOGO_FOLDER="openatv"
elif grep -qs -i "egami" /etc/image-version; then
    LOGO_FOLDER="egami"
elif grep -qs -i "PURE2" /etc/image-version; then
    LOGO_FOLDER="pure2"
elif grep -qs -i "OpenSPA" /etc/image-version; then
    LOGO_FOLDER="openspa"
elif grep -qs -i "openBH" /etc/image-version; then
    LOGO_FOLDER="openbh"
elif grep -qs -i "openViX" /etc/image-version; then
    LOGO_FOLDER="openvix"
elif grep -qs -i "openDroid" /etc/image-version; then
    LOGO_FOLDER="opendroid"
elif grep -qs -i "openpli" /etc/issue; then
    if grep -qs -i "GCC-15.1" /etc/issue; then
        LOGO_FOLDER="foxbob"
    else
        LOGO_FOLDER="openpli"
    fi
elif grep -qs -i "foxbob" /etc/issue; then
    LOGO_FOLDER="openplifoxbob"
elif grep -qs -i "Corvoboys" /etc/issue; then
    LOGO_FOLDER="corvoboys"
elif grep -qs -i "TNAP" /etc/issue; then
    LOGO_FOLDER="tnap"
elif grep -qs -i "teamblue" /etc/issue; then
    LOGO_FOLDER="teamblue"
elif grep -qs -i "openhdf" /etc/issue; then
    LOGO_FOLDER="openhdf"
fi

if [ -d "$SKINDIR/image_logo/$LOGO_FOLDER" ]; then
    mv -f "$SKINDIR/image_logo/$LOGO_FOLDER/imagelogo.png" "$SKINDIR/" 2>/dev/null
    mv -f "$SKINDIR/image_logo/$LOGO_FOLDER/top_logo.png" "$SKINDIR/" 2>/dev/null
else
    cp -f "$SKINDIR/main/top_logo.png" "$SKINDIR/top_logo.png" 2>/dev/null
fi

BOX_IMAGE_FOUND=false
for IMG_PATH in \
    "/usr/share/enigma2/${FILE_MODEL}.png" \
    "/usr/share/enigma2/hardware/${FILE_MODEL}_front.png" \
    "/usr/share/enigma2/hardware/${FILE_MODEL}.png" \
    "/usr/share/enigma2/skin_default/icons/stb/${FILE_MODEL}.png" \
    "/usr/share/enigma2/skin_default/stb/${FILE_MODEL}.png" \
    "/usr/share/enigma2/stb_icons/${FILE_MODEL}.png" \
    "/usr/share/enigma2/skin_default/stb_icons/${FILE_MODEL}.png" ; do
    
    if [ -f "$IMG_PATH" ]; then
        cp -f "$IMG_PATH" "$SKINDIR/boximage.png" 2>/dev/null
        BOX_IMAGE_FOUND=true
        break 
    fi
done

if [ "$BOX_IMAGE_FOUND" = false ]; then
    cp -f "$SKINDIR/main/boximage.png" "$SKINDIR/boximage.png" 2>/dev/null
fi

if [ ! -f /usr/bin/bitrate ] && [ ! -d /usr/lib/enigma2/python/Plugins/Extensions/Bitrate ] && [ ! -d /usr/lib/enigma2/python/Plugins/Extensions/BitrateViewer ]; then
    cat << 'EOF' > /tmp/install_bitrate.sh
#!/bin/sh
sleep 8
opkg update >/dev/null 2>&1
opkg install bitrate >/dev/null 2>&1
if [ ! -d /usr/lib/enigma2/python/Plugins/Extensions/Bitrate ] && [ ! -f /usr/bin/bitrate ]; then
    opkg install enigma2-plugin-extensions-bitrate >/dev/null 2>&1
fi
if [ ! -d /usr/lib/enigma2/python/Plugins/Extensions/Bitrate ] && [ ! -f /usr/bin/bitrate ]; then
    opkg install enigma2-plugin-extensions-bitrateviewer >/dev/null 2>&1
fi
rm -f /tmp/install_bitrate.sh
EOF
    chmod 755 /tmp/install_bitrate.sh
    /tmp/install_bitrate.sh &
fi

SYS_ARCH=$(uname -m)
if [ "$SYS_ARCH" = "aarch64" ]; then
    BASE_ARCH="aarch64"
elif echo "$SYS_ARCH" | grep -q "mips"; then
    BASE_ARCH="mipsel"
else
    BASE_ARCH="arm"
fi

cat << EOF > /tmp/install_aifury.sh
#!/bin/sh
sleep 10
curl -s -k -L "https://raw.githubusercontent.com/islam-2412/IPKS/main/fury/AIFury/aifury_py${PYVER}_${BASE_ARCH}.ipk" -o /tmp/aifury.ipk
if [ -f /tmp/aifury.ipk ] && [ \$(wc -c < /tmp/aifury.ipk) -gt 1000 ]; then
    if ! grep -q 'Not Found' /tmp/aifury.ipk; then
        opkg install --force-reinstall --force-overwrite /tmp/aifury.ipk >/dev/null 2>&1
    fi
fi
rm -f /tmp/aifury.ipk
rm -f /tmp/install_aifury.sh
EOF

chmod 755 /tmp/install_aifury.sh
/tmp/install_aifury.sh &

rm -rf "$SKINDIR/image_logo" > /dev/null 2>&1
rm -rf /control > /dev/null 2>&1

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
