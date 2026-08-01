#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/ci-plus-helper/ci-plus-helper.sh

# Configuration
#########################################
plugin="ci-plus-helper"
rm="Ciplushelper"
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

# Check and remove package old version
#########################################
check_and_remove_package() {
    if [ -d $plugin_path ]; then
        echo "> removing package old version please wait..."
        sleep 3 
        rm -rf $plugin_path > /dev/null 2>&1
        if [ -f /etc/init.d/ciplushelper ]; then
            /etc/init.d/ciplushelper stop 2>/dev/null
        fi
        update-rc.d -f ciplushelper remove 2>/dev/null
        killall ciplushelper 2>/dev/null
        rm -f /etc/init.d/ciplushelper 2>/dev/null
        update-rc.d -f ciplushelper remove 2>/dev/null
        rm -f /usr/bin/ciplushelper 2>/dev/null
        rm -rf /etc/ciplus 2>/dev/null
        rm -f /etc/cicert.bin 2>/dev/null

        # Remove plugin directory
        PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/Ciplushelper"
        if [ -d "$PLUGIN_DIR" ]; then
            rm -rf "$PLUGIN_DIR" 2>/dev/null
        fi

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
    fi
}
check_and_remove_package

# Download & Install package payload
#########################################
print_message() {
    echo "> [$(date +'%Y-%m-%d')] $1"
}

download_and_install_package() {
    print_message "> Downloading $plugin-$version package please wait ..."
    sleep 3
    wget --progress=bar:force -qO "$temp_dir/$targz_file" --no-check-certificate "$url" 2>&1
    
    if [ -f "$temp_dir/$targz_file" ]; then
        tar -xzf "$temp_dir/$targz_file" -C / > /dev/null 2>&1
        extract=$?
        rm -rf "$temp_dir/$targz_file" >/dev/null 2>&1

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
            print_message "> $plugin-$version package extraction failed"
            exit 1
        fi
    else
        print_message "> $plugin-$version package download failed"
        exit 1
    fi
}
download_and_install_package

# Detect OS & Dependencies
#######################################
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

# Required packages
DEPS=""

is_installed() {
    if [ "$OS" = "DreamOS" ]; then
        dpkg -s "$1" >/dev/null 2>&1
    else
        opkg list-installed | grep -wq "$1"
    fi
}

if [ -n "$DEPS" ]; then
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

write_info() {
    echo "$1" > /usr/lib/enigma2/python/Plugins/Extensions/Ciplushelper/info.txt
}

cleanup_old() {
    killall ciplushelper 2>/dev/null
    sleep 2
    rm -f /usr/bin/ciplushelper
}

install_ciplushelper() {
    local src_bin="$1"
    local src_init="$2"

    cp "$src_bin" /usr/bin/ciplushelper
    chmod 755 /usr/bin/ciplushelper

    cp "$src_init" /etc/init.d/ciplushelper
    chmod 755 /etc/init.d/ciplushelper

    if type update-rc.d >/dev/null 2>&1; then
        update-rc.d ciplushelper defaults 50
    fi
}

detect_arch_from_opkg() {
    if ! command -v opkg >/dev/null 2>&1; then
        return 1
    fi

    local archs=$(opkg print-architecture 2>/dev/null | grep -i "arch" | awk '{print $2}')

    if echo "$archs" | grep -qiE "arm|cortex|aarch64|armv7|armv8"; then
        echo "arm"
        return 0
    fi

    if echo "$archs" | grep -qiE "mips|mipsel"; then
        echo "mipsel32"
        return 0
    fi

    return 1
}

detect_arch_from_uname() {
    case $(uname -m) in
        armv7l|armv7|armv6l|armv5l|arm|aarch64|armv8)
            echo "arm"
            ;;
        mips|mipsel|mips64|mips64el)
            echo "mipsel32"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

MODEL=""
ZMODEL="no"

if [ -f /proc/stb/info/boxtype ]; then
    MODEL=$(cat /proc/stb/info/boxtype | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

if [ -z "$MODEL" ] && [ -f /proc/stb/info/model ]; then
    MODEL=$(cat /proc/stb/info/model | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

if [ -z "$MODEL" ] && [ -f /tmp/boxbranding.cfg ]; then
    MODEL=$(grep -i 'getMachineBuild=' /tmp/boxbranding.cfg | cut -d'=' -f2 | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

if [ -z "$MODEL" ] && [ -f /proc/stb/info/version ]; then
    MODEL=$(cat /proc/stb/info/version | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | cut -d'-' -f1)
fi

case "$MODEL" in
    h7|h10|h9combo|h9twin|h9combose|h9twinse)
        ZMODEL="zgemma-arm"
        ;;
esac

KERNEL=$(uname -r)
KERNEL_MAJOR=$(echo "$KERNEL" | cut -d. -f1-2)

IMAGE_VERSION=""
if [ -f /tmp/boxbranding.cfg ]; then
    IMAGE_VERSION=$(grep -i 'getImageVersion=' /tmp/boxbranding.cfg | cut -d'=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi
if [ -z "$IMAGE_VERSION" ] && [ -f /etc/image-version ]; then
    IMAGE_VERSION=$(grep -i 'version=' /etc/image-version | cut -d'=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

ARM_MODELS="h7 h10 h9combo h9twin h9combose h9twinse hd51 vs1500 pulse4k pulse4kmini h17 8100s hd61 ustym4kpro ustym4k dm8000 uclan"
MIPSEL_MODELS="h6 hd2400 hd1500 et8000 et10000 formuler1 formuler3 formuler4 triplex cube formuler4turbo formuler1tc formuler3ip formuler4ip"

ARCH=""

if echo "$ARM_MODELS" | grep -qw "$MODEL"; then
    ARCH="arm"
elif echo "$MIPSEL_MODELS" | grep -qw "$MODEL"; then
    ARCH="mipsel32"
elif [ "$ZMODEL" = "zgemma-arm" ]; then
    ARCH="arm"
else
    ARCH=$(detect_arch_from_opkg)
fi

if [ -z "$ARCH" ]; then
    ARCH=$(detect_arch_from_uname)
fi

if [ -z "$ARCH" ] || [ "$ARCH" = "unknown" ]; then
    exit 1
fi

PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/Ciplushelper"
BIN_DIR="$PLUGIN_DIR/ciplushelper_bin"
INIT_SCRIPT="$PLUGIN_DIR/ciplushelper.sh"

cleanup_old

case "$ARCH" in
    arm)
        ZGEMMA_MODELS="h7 h10 h9combo h9twin h9combose h9twinse"
        if echo "$ZGEMMA_MODELS" | grep -qw "$MODEL"; then
            BIN_SUBDIR="zgemma-arm"
        else
            BIN_SUBDIR="arm"
        fi
        ;;
    mipsel32)
        BIN_SUBDIR="mipsel32"
        ;;
    *)
        exit 1
        ;;
esac

BIN_FILE="$BIN_DIR/$BIN_SUBDIR/ciplushelper"
if [ ! -f "$BIN_FILE" ]; then
    ls -la "$BIN_DIR" 2>/dev/null
    exit 1
fi

install_ciplushelper "$BIN_FILE" "$INIT_SCRIPT"

if [ -d "$PLUGIN_DIR/ciplus" ]; then
    mkdir -p /etc/ciplus
    cp -f "$PLUGIN_DIR/ciplus/"* /etc/ciplus/ 2>/dev/null
    chmod 644 /etc/ciplus/* 2>/dev/null
fi

if [ -f "$PLUGIN_DIR/cicert.bin" ] && [ ! -f "/etc/cicert.bin" ]; then
    if [ "$BIN_SUBDIR" = "zgemma-arm" ]; then
        cp "$PLUGIN_DIR/cicert.bin" /etc/cicert.bin
        chmod 644 /etc/cicert.bin
    fi
fi

write_info "ciplushelper-$BIN_SUBDIR"

if [ ! -f /usr/lib/enigma2/python/Plugins/Extensions/Ciplushelper/info.txt ] || [ -z "$(cat /usr/lib/enigma2/python/Plugins/Extensions/Ciplushelper/info.txt 2>/dev/null)" ]; then
    rm -rf "$BIN_DIR" 2>/dev/null
    rm -f /usr/bin/ciplushelper
    exit 1
fi
