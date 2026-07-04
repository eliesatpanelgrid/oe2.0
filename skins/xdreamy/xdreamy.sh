#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/skins/xdreamy/xdreamy.sh

# Configuration
#########################################
plugin="xdreamy"
rm="xDreamy"
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

files_to_remove=(
   /usr/share/enigma2/xDreamy/
   /usr/lib/enigma2/python/Plugins/Extensions/xDreamy/
   /usr/lib/enigma2/python/Components/Converter/iAccess.py
   /usr/lib/enigma2/python/Components/Converter/iBase.py
   /usr/lib/enigma2/python/Components/Converter/iBitrate3.py
   /usr/lib/enigma2/python/Components/Converter/iBoxInfo.py
   /usr/lib/enigma2/python/Components/Converter/iCaidInfo2.py
   /usr/lib/enigma2/python/Components/Converter/iCamdRAED.py
   /usr/lib/enigma2/python/Components/Converter/iCpuUsage.py
   /usr/lib/enigma2/python/Components/Converter/iCryptoInfo.py
   /usr/lib/enigma2/python/Components/Converter/iEcmInfo.py
   /usr/lib/enigma2/python/Components/Converter/iEventList.py
   /usr/lib/enigma2/python/Components/Converter/iEventName2.py
   /usr/lib/enigma2/python/Components/Converter/iExtra.py
   /usr/lib/enigma2/python/Components/Converter/iExtraNumText.py
   /usr/lib/enigma2/python/Components/Converter/iFrontendInfo.py
   /usr/lib/enigma2/python/Components/Converter/iMenuDescription.py
   /usr/lib/enigma2/python/Components/Converter/iMenuEntryCompare.py
   /usr/lib/enigma2/python/Components/Converter/iNetSpeedInfo.py
   /usr/lib/enigma2/python/Components/Converter/iNextEvents.py
   /usr/lib/enigma2/python/Components/Converter/iReceiverInfo.py
   /usr/lib/enigma2/python/Components/Converter/iRouteInfo.py
   /usr/lib/enigma2/python/Components/Converter/iServName2.py
   /usr/lib/enigma2/python/Components/Converter/iTemp.py
   /usr/lib/enigma2/python/Components/Converter/iVpn.py
   /usr/lib/enigma2/python/Components/Converter/iServiceInfoEX.py
   /usr/lib/enigma2/python/Components/Converter/iExtraInfo.py
   /usr/lib/enigma2/python/Components/Converter/iServicePosition.py
   /usr/lib/enigma2/python/Components/Renderer/iBackdropX.py
   /usr/lib/enigma2/python/Components/Renderer/iBackdropXDownloadThread.py
   /usr/lib/enigma2/python/Components/Renderer/iChannelNumber.py
   /usr/lib/enigma2/python/Components/Renderer/iEventListDisplay.py
   /usr/lib/enigma2/python/Components/Renderer/iGenre.py
   /usr/lib/enigma2/python/Components/Renderer/iInfoEvents.py
   /usr/lib/enigma2/python/Components/Renderer/iNxtEvnt.py
   /usr/lib/enigma2/python/Components/Renderer/iPosterX.py
   /usr/lib/enigma2/python/Components/Renderer/iPosterXDownloadThread.py
   /usr/lib/enigma2/python/Components/Renderer/iPosterXEMC.py
   /usr/lib/enigma2/python/Components/Renderer/iRunningText.py
   /usr/lib/enigma2/python/Components/Renderer/iStarX.py
   /usr/lib/enigma2/python/Components/Renderer/iVolume2.py
   /usr/lib/enigma2/python/Components/Renderer/iVolumeText.py
   /usr/lib/enigma2/python/Components/Renderer/iVolz.py
   /usr/lib/enigma2/python/Components/Renderer/iParental.py
   /usr/lib/enigma2/python/Components/Renderer/iConverlibr.py
)

# Remove files and directories
for file in "${files_to_remove[@]}"; do
    if [ -e "$file" ]; then
        rm -rf "$file"
    else
        echo "â?Œ File not found: $file"
    fi
done

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
DEPS="python3-requests
python3-pillow
python3-image"

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

SKINDIR='/usr/share/enigma2/xDreamy'
SETTINGS='/etc/enigma2/settings'
LOGFILE='/tmp/XDREAMY_Installation.log'

# ==================== Logging Functions ====================
echo "" > "$LOGFILE"
log_title() { echo "$(date '+%H:%M:%S') - ==> $1" | tee -a "$LOGFILE"; }
log_step()  { printf "    • %-50s" "$1" | tee -a "$LOGFILE"; }
log_ok()    { echo "[✔]" | tee -a "$LOGFILE"; }
log_skip()  { echo "[skipped]" | tee -a "$LOGFILE"; }
log_fail()  { echo "[✖]" | tee -a "$LOGFILE"; }

# ==================== Title ====================
echo "===========================================================" | tee -a "$LOGFILE"
echo "             ★ XDREAMY Installation Script ★" | tee -a "$LOGFILE"
echo "===========================================================" | tee -a "$LOGFILE"
echo "" | tee -a "$LOGFILE"

# ==================== Image Logo Detection & Python Version ====================
log_title "Detecting Image Type & Python Version"

# Detect Image
IMAGE="unknown"
file_image_version=$(tr '[:upper:]' '[:lower:]' < /etc/image-version 2>/dev/null || true)
file_issue=$(tr '[:upper:]' '[:lower:]' < /etc/issue 2>/dev/null || true)

for key in openatv egami pure2 openspa opendroid openbh openpli openvix openhdf nonsolosat satlodge gcc tnap hyperion teamblue; do
    if echo "$file_image_version$file_issue" | grep -q "$key" 2>/dev/null; then
        IMAGE="$key"
        break
    fi
done
log_step "Detected: $IMAGE"; log_ok

# Detect Python Version
if command -v python3 >/dev/null 2>&1; then
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')" 2>/dev/null || echo "unknown")
    log_step "Python: $PYTHON_VERSION"; log_ok
else
    log_step "Python: not found"; log_fail
fi

# Apply Logo
if [ -f "$SKINDIR/image_logo/$IMAGE/imagelogo.png" ]; then
    cp "$SKINDIR/image_logo/$IMAGE/imagelogo.png" "$SKINDIR/imagelogo.png" 2>/dev/null || true
    log_step "Applied logo for $IMAGE"; log_ok
elif [ -f "/usr/share/enigma2/distro-logo.png" ]; then
    cp "/usr/share/enigma2/distro-logo.png" "$SKINDIR/imagelogo.png" 2>/dev/null || true
    log_step "Applied generic distro logo"; log_ok
else
    cp "$SKINDIR/image_logo/default/imagelogo.png" "$SKINDIR/imagelogo.png" 2>/dev/null || true
    log_step "Applied default logo"; log_ok
fi

# Remove extra files
[ -d "$SKINDIR/image_logo" ] && rm -rf "$SKINDIR/image_logo" 2>/dev/null && { log_step "Removed extra files"; log_ok; } || true
echo "" | tee -a "$LOGFILE"

# ==================== Box Detection ====================
log_title "Detecting Box Model"
BOX_MODEL=$(head -n 1 /etc/hostname 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)
log_step "Box Model: $BOX_MODEL"; log_ok

if [ -f "/usr/share/enigma2/$BOX_MODEL.png" ]; then
    cp "/usr/share/enigma2/$BOX_MODEL.png" "$SKINDIR/boximage.png" 2>/dev/null || true
    log_step "Box Image: Applied Box logo"; log_ok
else
    log_step "Box Image: No logo found"; log_skip
fi
echo "" | tee -a "$LOGFILE"

# ==================== Apply xDreamy Skin ====================
log_title "Applying XDREAMY Skin"
if grep -q "^config.skin.primary_skin=" "$SETTINGS" 2>/dev/null; then
    sed -i "s|^config.skin.primary_skin=.*|config.skin.primary_skin=xDreamy/skin.xml|" "$SETTINGS" 2>/dev/null || true
    log_step "Updated config.skin.primary_skin=xDreamy/skin.xml"; log_ok
else
    echo "config.skin.primary_skin=xDreamy/skin.xml" >> "$SETTINGS" 2>/dev/null || true
    log_step "Appended skin setting for xDreamy"; log_ok
fi

if grep -q "^config.misc.initialchannelselection=True" "$SETTINGS" 2>/dev/null; then
    sed -i "s|^config.misc.initialchannelselection=True|config.misc.initialchannelselection=False|" "$SETTINGS" 2>/dev/null || true
    log_step "Forced OpenSPA channel selection → False"; log_ok
else
    log_step "OpenSPA channel selection unchanged"; log_skip
fi
echo "" | tee -a "$LOGFILE"

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
