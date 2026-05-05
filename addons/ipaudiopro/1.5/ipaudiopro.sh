#!/bin/bash

#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/ipaudiopro/1.5/ipaudiopro.sh
#configuration
###########################################

package="enigma2-plugin-extensions-ipaudiopro"
version="1.5"
PY_BIN="python"
[[ -e /usr/bin/python3 ]] && PY_BIN="python3"

# ---------------------------
# Detect Python version
# ---------------------------
detect_python() {
    PY_VER=$($PY_BIN -c "import platform; print(platform.python_version())" 2>/dev/null | cut -d'.' -f1-2)

    if [ -z "$PY_VER" ]; then
        echo "Python not detected"
        exit 1
    fi

    pp="py${PY_VER}"
}

# ---------------------------
# Detect FFmpeg version
# ---------------------------
detect_ffmpeg() {
    if ! opkg status ffmpeg >/dev/null 2>&1; then
        echo "FFmpeg not installed"
        exit 1
    fi

    RAW_VERSION=$(opkg status ffmpeg | awk '/Version:/ {print $2}' | cut -d'-' -f1)
    MAJOR=$(echo "$RAW_VERSION" | cut -d'.' -f1)

    case "$MAJOR" in
        4) ff="ff4.0" ;;
        6) ff="ff6.0" ;;
        7) ff="ff7.1" ;;
        8) ff="ff8.0" ;;
        *)
            echo "Unsupported FFmpeg version: $MAJOR"
            exit 1
            ;;
    esac
}

# ---------------------------
# OE + ARCH DETECTION (UNCHANGED)
# ---------------------------
get_oever() {
	OEVER=$($PY_BIN - <<END
import sys
sys.path.append('/usr/lib/enigma2/python')
try:
	from boxbranding import getOEVersion
	print(getOEVersion())
except:
	print("unknown")
END
	)
	OEVER=$(echo $OEVER | sed "s/OE-Alliance //")
}

get_arch() {
	ARCH=$($PY_BIN - <<END
import sys
sys.path.append('/usr/lib/enigma2/python')
try:
	from boxbranding import getImageArch
	print(getImageArch())
except:
	print("unknown")
END
	)

	if [ "x$ARCH" = "xunknown" ]; then
		echo $(uname -m) | grep -q "aarch64" && ARCH="aarch64"
		echo $(uname -m) | grep -q "mips" && ARCH="mips32el"

		if echo $(uname -m) | grep -q "armv7l"; then
			echo $(cat /proc/cpuinfo | grep "CPU part" | uniq) | grep -q "0xc09" && ARCH="cortexa9hf-neon"
			echo $(cat /proc/cpuinfo | grep "CPU part" | uniq) | grep -q "0x00f" && ARCH="cortexa15hf-neon-vfpv4"
		fi
	fi
}

check_compat() {
	if [ "x$ARCH" = "xunknown" ]; then
		echo "Unsupported architecture"
		exit 1
	fi
}

# ---------------------------
# RUN DETECTION
# ---------------------------
get_oever
get_arch
check_compat
detect_python
detect_ffmpeg

plugin="${package}_${version}_${ARCH}_${pp}_${ff}"


site="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/ipaudiopro/1.5"
temp_dir="/tmp"


print_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Determine package manager and plugin extension
###########################################
if command -v dpkg &> /dev/null; then
    package_manager="apt"
    install_command="dpkg -i --force-overwrite"
    uninstall_command="apt-get purge --auto-remove -y"
    status_file="/var/lib/dpkg/status"
    plugin_extension="deb"
else
    package_manager="opkg"
    install_command="opkg install --force-reinstall"
    uninstall_command="opkg remove --force-depends"
    status_file="/var/lib/opkg/status"
    plugin_extension="ipk"
fi

#determine and check url
###########################################
url="$site/$plugin.$plugin_extension"
if wget -q --method=HEAD $url; then
  pluginextension=found
else
  print_message "> $plugin.$plugin_extension not found"
  print_message "> your device is not supported"
exit 1
fi

# Functions
###########################################
cleanup() {
    print_message "> Performing cleanup..."
    [ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
    rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1
    print_message "> Cleanup completed."
}

#check andd install or remove package
###########################################
check_and_install_package() {

plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/IPaudioPro"
if [ -d $plugin_path ]; then
    print_message "> removing package old version please wait..."
    sleep 3 
    rm -rf $plugin_path > /dev/null 2>&1

    if grep -q "$plugin.$plugin_extension" "$status_file"; then
        $uninstall_command $plugin.$plugin_extension > /dev/null 2>&1
    fi
echo "*******************************************"
echo "*             Removed Finished            *"
echo "*            Uploaded By Eliesat          *"
echo "*******************************************"
sleep 3
exit 1
fi

# --- START MESSAGE ---
printf "Starting dependency check and installation...\n"

# ---------------------------------------------------------
# Detect package manager
# ---------------------------------------------------------
if [ -f /etc/opkg/opkg.conf ]; then
    INSTALL="opkg install"
    UPDATE="opkg update"
    LIST_INSTALLED="opkg list-installed"
    LIST_AVAILABLE="opkg list"
elif [ -f /etc/apt/apt.conf ]; then
    INSTALL="apt-get install -y"
    UPDATE="apt-get update"
    LIST_INSTALLED="dpkg -l"
    LIST_AVAILABLE="apt-cache pkgnames"
else
    exit 1
fi

# ---------------------------------------------------------
# Update feeds
# ---------------------------------------------------------
$UPDATE > /dev/null 2>&1

# ---------------------------------------------------------
# ALL possible dependencies
# ---------------------------------------------------------
DEPS="
gstreamer1.0-plugins-good gstreamer1.0-plugins-base
gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
alsa-conf alsa-plugins alsa-state enigma2
libasound2 libc6 libgcc1 libstdc++6
ffmpeg libav
libavcodec58 libavcodec60 libavcodec61 libavcodec62 libavcodec63
libavformat58 libavformat60 libavformat61 libavformat62 libavformat63
python libs
libpython2.7-1.0
libpython3.9-1.0
libpython3.10-1.0
libpython3.11-1.0
libpython3.12-1.0
libpython3.13-1.0
libpython3.14-1.0
"

# ---------------------------------------------------------
# Cache lists
# ---------------------------------------------------------
INSTALLED_LIST="$($LIST_INSTALLED)"
AVAILABLE_LIST="$($LIST_AVAILABLE)"

INSTALL_LIST=""

# ---------------------------------------------------------
# Check loop (NO pipes)
# ---------------------------------------------------------
for pkg in $DEPS; do
    case "$INSTALLED_LIST" in
        *"$pkg"*)
            ;;
        *)
            case "$AVAILABLE_LIST" in
                *"$pkg"*)
                    INSTALL_LIST="$INSTALL_LIST $pkg"
                ;;
                *)
                    ;;
            esac
        ;;
    esac
done

# ---------------------------------------------------------
# Install only valid packages
# ---------------------------------------------------------
if [ -n "$INSTALL_LIST" ]; then
    $INSTALL $INSTALL_LIST > /dev/null 2>&1
fi

# --- END MESSAGE ---
printf "Dependency check and installation completed.\n"


    print_message "> Downloading $plugin.$plugin_extension, please wait..."
    wget -q --show-progress $url -P "$temp_dir"
    if [ $? -ne 0 ]; then
        print_message "> Failed to download $plugin.$plugin_extension from $url"
        exit 1
    fi
sleep 3
    print_message "> Installing $plugin.$plugin_extension, please wait..."
    $install_command "$temp_dir/$plugin.$plugin_extension"
    if [ $? -eq 0 ]; then
    wget -qO $plugin_path/logo.png $site/logo.png
        print_message "> $plugin.$plugin_extension installed successfully."
    else
        print_message "> Installation failed."
        exit 1
    fi
}

# Main
trap cleanup EXIT
check_and_install_package
