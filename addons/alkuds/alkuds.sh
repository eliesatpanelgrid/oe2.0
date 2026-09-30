#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/alkuds/alkuds.sh

# Configuration
#########################################
plugin="alkuds"
rm="Alkuds"
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

OLD_PACKAGE="enigma2-plugin-extensions-xklass"
OLD_PLUGIN="/usr/lib/enigma2/python/Plugins/Extensions/XKlass"
OLD_DATA="/etc/enigma2/xklass"
NEW_DATA="/etc/enigma2/alkuds"

# Preserve the user's playlists and cached account data under the new name.
if [ -d "$OLD_DATA" ] && [ ! -d "$NEW_DATA" ]; then
    mv "$OLD_DATA" "$NEW_DATA" 2>/dev/null || true
fi

# Preserve Enigma2 settings while changing the plugin configuration namespace.
if [ -f /etc/enigma2/settings ]; then
    sed -i 's/^config\.plugins\.XKlass\./config.plugins.Alkuds./' /etc/enigma2/settings 2>/dev/null || true
fi

# Remove the legacy XClass/XKlass package before installing Alkuds.
if command -v opkg >/dev/null 2>&1 && opkg status "$OLD_PACKAGE" 2>/dev/null | grep -q '^Status:.* installed'; then
    opkg remove --force-depends "$OLD_PACKAGE" >/tmp/alkuds-remove-xklass.log 2>&1 || true
elif command -v dpkg >/dev/null 2>&1 && dpkg -s "$OLD_PACKAGE" >/dev/null 2>&1; then
    dpkg --remove "$OLD_PACKAGE" >/tmp/alkuds-remove-xklass.log 2>&1 || true
fi

# Clean up legacy files even when the old package database entry is absent.
rm -rf "$OLD_PLUGIN"
rm -f /usr/lib/enigma2/python/Components/Converter/XKlassServiceInfo.py \
      /usr/lib/enigma2/python/Components/Converter/XKlassServiceInfo.pyc \
      /usr/lib/enigma2/python/Components/Converter/XKlassServicePosition.py \
      /usr/lib/enigma2/python/Components/Converter/XKlassServicePosition.pyc \
      /usr/lib/enigma2/python/Components/Renderer/XKlassRunningText.py \
      /usr/lib/enigma2/python/Components/Renderer/XKlassRunningText.pyc 2>/dev/null || true

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
    2.*|3.*) ;;
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
  print_message "> $plugin-$version package installed successfully"

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
[ -f /etc/enigma2/alkuds_audio_sources.json ] && chmod 600 /etc/enigma2/alkuds_audio_sources.json 2>/dev/null || true
[ -f /media/hdd/alkuds_audio_sources.json ] && chmod 600 /media/hdd/alkuds_audio_sources.json 2>/dev/null || true

rm -f /tmp/alkuds-native-audio.log /tmp/alkuds-backgroundaudio.log /tmp/alkuds-audio-relay.log /tmp/alkuds-timeshift.log /tmp/alkuds-timeshift-recorder.log /tmp/alkuds-timeshift-video.log /tmp/alkuds-timeshift-ffmpeg.log /tmp/alkuds-remux.log /tmp/alkuds-remux-ffmpeg.log 2>/dev/null || true
rm -f /media/hdd/timeshift/.ipaudio-alquds-sat-timeshift-*.ts 2>/dev/null || true
rm -f /media/hdd/.ipaudio-alquds-sat-timeshift-*.ts 2>/dev/null || true

PLUG=/usr/lib/enigma2/python/Plugins/Extensions/Alkuds
# R72: clear Reezn VOD resolver bytecode and diagnostics on upgrade.
rm -f /tmp/alkuds_reezn_vod.log 2>/dev/null || true
rm -f "$PLUG"/reeznvod.pyc "$PLUG"/reeznvod.pyo "$PLUG"/__pycache__/reeznvod.*.pyc 2>/dev/null || true
# R70: discard stale bytecode for the updated Reezn playback path.
rm -f "$PLUG"/streamproxy.pyc "$PLUG"/streamproxy.pyo \
      "$PLUG"/__pycache__/streamproxy.*.pyc \
      "$PLUG"/__pycache__/freeproviders.*.pyc \
      "$PLUG"/__pycache__/freechannels.*.pyc 2>/dev/null || true
rm -f "$PLUG"/receivercompat.pyc "$PLUG"/receivercompat.pyo \
      "$PLUG"/backgroundaudio.pyc "$PLUG"/backgroundaudio.pyo \
      "$PLUG"/remux.pyc "$PLUG"/remux.pyo \
      "$PLUG"/remuxreturn.pyc "$PLUG"/remuxreturn.pyo \
      "$PLUG"/stalker.pyc "$PLUG"/stalker.pyo \
      "$PLUG"/xtreamlite.pyc "$PLUG"/xtreamlite.pyo \
      "$PLUG"/startmenu.pyc "$PLUG"/startmenu.pyo \
      "$PLUG"/audioquickreturn.pyc "$PLUG"/audioquickreturn.pyo \
      "$PLUG"/ipaudioexport.pyc "$PLUG"/ipaudioexport.pyo \
      "$PLUG"/streammonitor.pyc "$PLUG"/streammonitor.pyo \
      "$PLUG"/streammetrics.pyc "$PLUG"/streammetrics.pyo \
      "$PLUG"/audiofeeds.pyc "$PLUG"/audiofeeds.pyo \
      "$PLUG"/freechannels.pyc "$PLUG"/freechannels.pyo \
      "$PLUG"/freeproviders.pyc "$PLUG"/freeproviders.pyo \
      "$PLUG"/uihelpers.pyc "$PLUG"/uihelpers.pyo \
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

# The package manager is normally locked while postinst runs. Finish removing
# the legacy package after that lock is released, then remove its old folder.
LEGACY_CLEANUP='if command -v opkg >/dev/null 2>&1; then opkg remove --force-depends enigma2-plugin-extensions-xklass >/tmp/alkuds-remove-xklass.log 2>&1 || true; elif command -v dpkg >/dev/null 2>&1; then dpkg --remove enigma2-plugin-extensions-xklass >/tmp/alkuds-remove-xklass.log 2>&1 || true; fi; rm -rf /usr/lib/enigma2/python/Plugins/Extensions/XKlass'
if command -v nohup >/dev/null 2>&1; then
    nohup sh -c "sleep 10; $LEGACY_CLEANUP" >/dev/null 2>&1 &
else
    sh -c "sleep 10; $LEGACY_CLEANUP" >/dev/null 2>&1 &
fi
# Discard old bytecode for the custom account/OSD/menu changes.
for module in akwam akwamui radiobackground freechannels fajershow fajershowui freeplayer series xtreamlite accountinfo remote_backup streammetrics vod audiofeeds stalker liveplayer settings trafficwidget freeproviders streammonitor catchupplayer vodplayer plugin channelmenu; do
    rm -f "$PLUG/$module.pyc" "$PLUG/$module.pyo" "$PLUG"/__pycache__/"$module".*.pyc 2>/dev/null || true
done

# R80: local, bounded JSON import; no account requests are made here.
# Respect offline image/rootfs installation.
if [ -z "$IPKG_INSTROOT" ] && [ -z "$OPKG_INSTROOT" ]; then
    for py in python3 python; do
        if command -v "$py" >/dev/null 2>&1; then
            "$py" "$PLUG/localimport.py" || true
            break
        fi
    done
fi
for module in localimport processfiles; do
    rm -f "$PLUG/$module.pyc" "$PLUG/$module.pyo" "$PLUG"/__pycache__/"$module".*.pyc 2>/dev/null || true
done

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
