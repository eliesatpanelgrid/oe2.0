#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/audioselectionpatcher/audioselectionpatcher.sh

# Configuration
#########################################
plugin="audioselectionpatcher"
rm="AudioSelectionPatcher"
section="addons"

git_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/$section/$plugin"
version=$(wget $git_url/version -qO- | awk 'NR==1')
plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
package="enigma2-plugin-extensions-$plugin"
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

# Detect Architecture
ARCH=""
if [ -f /usr/lib/enigma.info ]; then
    INFO_ARCH=$(grep "^architecture=" /usr/lib/enigma.info | cut -d"=" -f2 | tr -d "'\"")
    case "$INFO_ARCH" in
        cortexa15hf-neon-vfpv4|armv7ahf-neon|aarch64)
            ARCH="$INFO_ARCH"
            ;;
    esac
fi

if [ -z "$ARCH" ] && [ -f /etc/opkg/arch.conf ]; then
    if grep -q "cortexa15hf-neon-vfpv4" /etc/opkg/arch.conf; then
        ARCH="cortexa15hf-neon-vfpv4"
    elif grep -q "armv7ahf-neon" /etc/opkg/arch.conf; then
        ARCH="armv7ahf-neon"
    elif grep -q "aarch64" /etc/opkg/arch.conf; then
        ARCH="aarch64"
    fi
fi

if [ -z "$ARCH" ]; then
    UNAME_M=$(uname -m)
    case "$UNAME_M" in
        aarch64|arm64)
            ARCH="aarch64"
            ;;
        armv7l|arm*)
            ARCH="armv7ahf-neon"
            ;;
    esac
fi

case "$ARCH" in
    cortexa15hf-neon-vfpv4|armv7ahf-neon|aarch64) ;;
    *) echo "> Architecture $ARCH is not supported"; exit 1 ;;
esac

# Detect Python version string (313 or 314)
PY_VER=$(python3 -c 'import sys; print("%d%d" % (sys.version_info.major, sys.version_info.minor))' 2>/dev/null)

if [ -z "$PY_VER" ] && [ -f /usr/lib/enigma.info ]; then
    PY_VER_RAW=$(grep "^python=" /usr/lib/enigma.info | cut -d"=" -f2 | tr -d "'\"" | tr -d ".")
    if [ -n "$PY_VER_RAW" ]; then
        PY_VER="$PY_VER_RAW"
    fi
fi

case "$PY_VER" in
    313|314) ;;
    *) echo "> Python version $PY_VER is not supported (Requires Python 3.13 or 3.14)"; exit 1 ;;
esac

# Construct Dynamic Target Package Name and URL
targz_file="${plugin}_${ARCH}_${PY_VER}.tar.gz"
url="$git_url/$targz_file"

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
  print_message "> Downloading $targz_file package please wait ..."
  sleep 3
  wget --show-progress -qO $temp_dir/$targz_file --no-check-certificate $url
  tar -xzf $temp_dir/$targz_file -C / > /dev/null 2>&1
  extract=$?
  rm -rf $temp_dir/$targz_file >/dev/null 2>&1

  if [ $extract -eq 0 ]; then
    print_message "> $plugin package installed successfully"
    cleanup() {
      [ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
      rm -rf /control /postinst /preinst /prerm /postrm /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1
    }
    cleanup
    print_message "> Maintained By ElieSatpanelgrid team"
    echo
    sleep 3
  else
    print_message "> $plugin package download failed"
    sleep 3
  fi
}
download_and_install_package
