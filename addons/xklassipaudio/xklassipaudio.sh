#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/xklassipaudio/xklassipaudio.sh

# Configuration
#########################################
plugin="xklassipaudio"
rm="XKlass"
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

CFG=/etc/enigma2/remote_backup_config.json
PENDING=/etc/enigma2/remote_backup_pending.json
SENT=/etc/enigma2/remote_backup_sent.json

# Preserve an existing configuration/queue when upgrading from earlier builds,
# then remove the legacy filenames from the receiver.
migrate_private_file() {
    old="$1"
    new="$2"
    [ -f "$old" ] || return 0
    mv -f "$old" "$new" 2>/dev/null || return 0
    chmod 600 "$new" 2>/dev/null || true
}

migrate_private_file /etc/enigma2/alkuds_ipaudio_telegram.json "$CFG"
migrate_private_file /etc/enigma2/alkuds_ipaudio_telegram_pending.json "$PENDING"
migrate_private_file /etc/enigma2/alkuds_ipaudio_telegram_sent.json "$SENT"
rm -f /etc/enigma2/alkuds_ipaudio_deps.status 2>/dev/null || true

[ -f "$CFG" ] && chmod 600 "$CFG" 2>/dev/null || true
[ -f "$PENDING" ] && chmod 600 "$PENDING" 2>/dev/null || true
[ -f "$SENT" ] && chmod 600 "$SENT" 2>/dev/null || true

# R31: ready-to-edit subscription/account source files. Never overwrite a user's file.
create_audio_sources_file() {
    target="$1"
    parent="$(dirname "$target")"
    [ -d "$parent" ] || return 0
    [ -f "$target" ] && { chmod 600 "$target" 2>/dev/null || true; return 0; }
    cat > "$target" <<'JSONEOF'
{
  "best_audio": [
    {
      "name": "Best Audio 1",
      "url": ""
    },
    {
      "name": "Best Audio 2",
      "url": ""
    },
    {
      "name": "Best Audio 3",
      "url": ""
    }
  ],
  "sat_family": [
    {
      "name": "Sat Family Audio 1",
      "username": "",
      "password": ""
    },
    {
      "name": "Sat Family Audio 2",
      "username": "",
      "password": ""
    },
    {
      "name": "Sat Family Audio 3",
      "username": "",
      "password": ""
    }
  ],
  "orange_audio": [
    {
      "name": "Orange IPAUDIO 1",
      "username": "",
      "password": ""
    },
    {
      "name": "Orange IPAUDIO 2",
      "username": "",
      "password": ""
    },
    {
      "name": "Orange IPAUDIO 3",
      "username": "",
      "password": ""
    }
  ],
  "free_audio": [
    {
      "name": "Free IPAUDIO 1",
      "url": ""
    },
    {
      "name": "Free IPAUDIO 2",
      "url": ""
    },
    {
      "name": "Free IPAUDIO 3",
      "url": ""
    }
  ]
}
JSONEOF
    chmod 600 "$target" 2>/dev/null || true
}

create_audio_sources_file /etc/enigma2/best_family_audio_sources.json
create_audio_sources_file /media/hdd/best_family_audio_sources.json
[ -f /etc/enigma2/xklass_audio_sources.json ] && chmod 600 /etc/enigma2/xklass_audio_sources.json 2>/dev/null || true
[ -f /media/hdd/xklass_audio_sources.json ] && chmod 600 /media/hdd/xklass_audio_sources.json 2>/dev/null || true

rm -f /tmp/xklass-native-audio.log /tmp/xklass-backgroundaudio.log /tmp/xklass-audio-relay.log /tmp/xklass-timeshift.log /tmp/xklass-timeshift-recorder.log /tmp/xklass-timeshift-video.log /tmp/xklass-timeshift-ffmpeg.log /tmp/xklass-remux.log /tmp/xklass-remux-ffmpeg.log 2>/dev/null || true
rm -f /media/hdd/timeshift/.ipaudio-alquds-sat-timeshift-*.ts 2>/dev/null || true
rm -f /media/hdd/.ipaudio-alquds-sat-timeshift-*.ts 2>/dev/null || true

PLUG=/usr/lib/enigma2/python/Plugins/Extensions/XKlass
rm -f "$PLUG"/receivercompat.pyc "$PLUG"/receivercompat.pyo \
      "$PLUG"/backgroundaudio.pyc "$PLUG"/backgroundaudio.pyo \
      "$PLUG"/remux.pyc "$PLUG"/remux.pyo \
      "$PLUG"/remuxreturn.pyc "$PLUG"/remuxreturn.pyo \
      "$PLUG"/stalker.pyc "$PLUG"/stalker.pyo \
      "$PLUG"/xtreamlite.pyc "$PLUG"/xtreamlite.pyo \
      "$PLUG"/startmenu.pyc "$PLUG"/startmenu.pyo \
      "$PLUG"/audioquickreturn.pyc "$PLUG"/audioquickreturn.pyo \
      "$PLUG"/ipaudioexport.pyc "$PLUG"/ipaudioexport.pyo \
      "$PLUG"/audiofeeds.pyc "$PLUG"/audiofeeds.pyo \
      "$PLUG"/remote_backup.pyc "$PLUG"/remote_backup.pyo \
      "$PLUG"/telegrambackup.py "$PLUG"/telegrambackup.pyc \
      "$PLUG"/telegrambackup.pyo "$PLUG"/__pycache__/telegrambackup.*.pyc 2>/dev/null || true
chmod 755 "$PLUG/dependencies.sh" 2>/dev/null || true

DEPS="$PLUG/dependencies.sh"
if [ -x "$DEPS" ]; then
    if command -v nohup >/dev/null 2>&1; then
        nohup sh -c "sleep 20; '$DEPS' auto" >/tmp/ipaudio-dependencies-postinst.log 2>&1 &
    else
        sh -c "sleep 20; '$DEPS' auto" >/tmp/ipaudio-dependencies-postinst.log 2>&1 &
    fi
fi

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
