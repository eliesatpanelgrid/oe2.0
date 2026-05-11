#!/bin/sh

# === Functions ===
log() {
  printf "%s\n" "$*"
}

log_action() {
  printf "    • %-55s" "$1"
}

log_done() {
  echo "[ ✔ ]"
}

log_skip() {
  echo "[ skipped ]"
}

log_fail() {
  echo "[ ✖ ]"
}

cleanup() {
    rm -rf /tmp/*.ipk /tmp/*.tar.gz /var/cache/opkg/* /var/lib/opkg/lists/* /run/opkg.lock $i >/dev/null 2>&1
}

# === Determine the package manager and system type ===
###########################################
if command -v dpkg &> /dev/null; then
    package_manager="apt"
    status_file="/var/lib/dpkg/status"
    install_command="dpkg -i --force-overwrite"
    install_command1="dpkg -i --force-depends"
    uninstall_command="apt-get purge --auto-remove -y"
    ostype="Oe 2.5/2.6"
    it=DreamOs
    update="apt update"
    upgrade="apt upgrade"
else
    package_manager="opkg"
    install_command="opkg install"
    install_command1="opkg install --force-depends"
    uninstall_command="opkg remove --force-depends"
    status_file="/var/lib/opkg/status"
    ostype="Oe 2.0"
    it=OpenSource
    update="opkg update"
    upgrade="opkg upgrade"
fi

###########################################
# Web connectivity check (ip-api only)
###########################################
if wget -q --spider http://ip-api.com; then
    WEB_OK=1
else
    WEB_OK=0
fi

###########################################
# Date & Time
###########################################
DATE=$(date +%d-%m-%Y)
TIME=$(date +%H:%M:%S)

###########################################
# Logging
###########################################
log() { printf "%s\n" "$*"; }

###########################################
# Cleanup (safe)
###########################################
cleanup() {
    rm -f /tmp/*.ipk /tmp/*.tar.gz 2>/dev/null
    rm -f /run/opkg.lock 2>/dev/null
}

###########################################
# Detect package manager
###########################################
if command -v apt-get >/dev/null 2>&1; then
    PM="apt"
    INSTALL="apt-get install -y"
    UPDATE="apt update"
    OSTYPE="OE 2.5/2.6 (DreamOS)"
else
    PM="opkg"
    INSTALL="opkg install"
    UPDATE="opkg update"
    OSTYPE="OE 2.0 (OpenSource)"
fi

###########################################
# System info
###########################################
if [ -f /etc/image-version ]; then
    IMAGE_NAME=$(grep -i "^creator=" /etc/image-version | cut -d"=" -f2 | xargs)
    IMAGE_VERSION=$(grep -i "^version=" /etc/image-version | head -n1 | cut -d"=" -f2 | xargs)
elif [ -f /etc/issue ]; then
    IMAGE_NAME=$(head -n1 /etc/issue | awk '{print $1}')
    IMAGE_VERSION=$(head -n1 /etc/issue | awk '{print $2}')
else
    IMAGE_NAME="Unknown"
    IMAGE_VERSION="Unknown"
fi

BOX_MODEL=$(cat /etc/hostname 2>/dev/null)
PYTHON_VERSION=$(python3 --version 2>/dev/null | awk '{print $2}')

NET_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
[ -z "$NET_IFACE" ] && NET_IFACE="unknown"

###########################################
# Update repositories
###########################################
$UPDATE >/dev/null 2>&1

###########################################
# Ensure curl wget exists
###########################################
if ! command -v curl >/dev/null 2>&1; then
    $INSTALL curl >/dev/null 2>&1
fi

if ! command -v wget >/dev/null 2>&1; then
    $INSTALL wget >/dev/null 2>&1
fi

###########################################
# GEOLOCATION (ONLY if WEB OK)
###########################################
if [ "$WEB_OK" -eq 1 ]; then

IP=$(wget -qO- http://ip-api.com/line/?fields=query)

GEO=$(wget -qO- "http://ip-api.com/json/$IP?fields=status,continent,country,regionName,city,timezone,currency")

STATUS=$(echo "$GEO" | grep -o '"status":"[^"]*"' | cut -d':' -f2 | tr -d '"')

if [ "$STATUS" = "success" ]; then
    CONTINENT=$(echo "$GEO" | grep -o '"continent":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    COUNTRY=$(echo "$GEO" | grep -o '"country":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    REGION=$(echo "$GEO" | grep -o '"regionName":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    CITY=$(echo "$GEO" | grep -o '"city":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    TZ=$(echo "$GEO" | grep -o '"timezone":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    CURRENCY=$(echo "$GEO" | grep -o '"currency":"[^"]*"' | cut -d':' -f2 | tr -d '"')
fi

fi

###########################################
# Display info (SYSTEM ONLY)
###########################################
log "✔ Box Model         : $BOX_MODEL"
sleep 1

log "✔ Image             : $IMAGE_NAME"
sleep 1

log "✔ Image Version     : $IMAGE_VERSION"
sleep 1

log "✔ Python            : $PYTHON_VERSION"
sleep 1

log "✔ Network Interface : $NET_IFACE"
sleep 1

LANG=$(grep config.osd.language /etc/enigma2/settings 2>/dev/null | cut -d'=' -f2 | cut -c1-2)
[ -z "$LANG" ] && LANG="en"
log "✔ Local Language    : $LANG"
sleep 1

###########################################
# GEO DISPLAY ONLY IF WEB OK
###########################################
if [ "$WEB_OK" -eq 1 ]; then
    log "✔ Continent         : $CONTINENT"
    sleep 1
    log "✔ Country           : $COUNTRY"
    sleep 1
    log "✔ Region            : $REGION"
    sleep 1
    log "✔ City              : $CITY"
    sleep 1
    log "✔ Timezone          : $TZ"
    sleep 1
    log "✔ Currency          : $CURRENCY"
    sleep 1
fi

log ""

sleep 3
rm -rf /tmp/file.txt
touch /tmp/file.txt

cat <<EOF >> /tmp/file.txt
config.autolanguage.audio_autoselect1=orj dos ory org esl qaa qaf und mis mul ORY ORJ Audio_ORJ oth
config.autolanguage.audio_autoselect2=eng Englisch
config.autolanguage.audio_epglanguage_alternative=eng Englisch
config.av.policy_169=bestfit
config.av.policy_43=bestfit
config.av.videomode.HDMI=1080p
config.av.videorate.1080p=auto
config.crash.lastfulljobtrashtime=1775089800
config.lcd.bright=2
config.lcd.dimbright=2
config.misc.ButtonSetup.back=Infobar/toggleShow
config.misc.ButtonSetup.cross_down=Infobar/zapUp
config.misc.ButtonSetup.cross_up=Infobar/zapDown
config.misc.ButtonSetup.info=Infobar/openBouquets
config.misc.ButtonSetup.info_long=Infobar/openSatellites
config.misc.ButtonSetup.next=Plugins/Extensions/AJPan/9
config.misc.firstrun=False
config.misc.initialchannelselection=False
config.misc.lastrotorposition=260
config.misc.load_unlinked_userbouquets=True
config.misc.networkwizard.hasnetwork=True
config.misc.networkwizardenabled=False
config.misc.nextWakeup=1775063919,-1,-1,0,0,-1,0
config.misc.SettingsVersion=1.1
config.misc.startCounter=8
config.misc.SyncTimeUsing=1
config.misc.videowizardenabled=False
config.misc.wizardLanguageEnabled=False
config.NewVirtualKeyBoard.textinput=NewVirtualKeyBoard
config.Nims.0.advanced.lnb.1.diseqcMode=1_2
config.Nims.0.advanced.lnb.1.powerMeasurement=false
config.Nims.0.advanced.sat.100.lnb=1
config.Nims.0.advanced.sat.100.rotorposition=10
config.Nims.0.advanced.sat.100.usals=false
config.Nims.0.advanced.sat.130.lnb=1
config.Nims.0.advanced.sat.130.rotorposition=13
config.Nims.0.advanced.sat.130.usals=false
config.Nims.0.advanced.sat.160.lnb=1
config.Nims.0.advanced.sat.160.rotorposition=16
config.Nims.0.advanced.sat.160.usals=false
config.Nims.0.advanced.sat.19.lnb=1
config.Nims.0.advanced.sat.19.rotorposition=2
config.Nims.0.advanced.sat.19.usals=false
config.Nims.0.advanced.sat.192.lnb=1
config.Nims.0.advanced.sat.192.rotorposition=19
config.Nims.0.advanced.sat.192.usals=false
config.Nims.0.advanced.sat.216.lnb=1
config.Nims.0.advanced.sat.216.rotorposition=21
config.Nims.0.advanced.sat.216.usals=false
config.Nims.0.advanced.sat.235.lnb=1
config.Nims.0.advanced.sat.235.rotorposition=23
config.Nims.0.advanced.sat.235.usals=false
config.Nims.0.advanced.sat.255.lnb=1
config.Nims.0.advanced.sat.255.rotorposition=26
config.Nims.0.advanced.sat.255.usals=false
config.Nims.0.advanced.sat.260.lnb=1
config.Nims.0.advanced.sat.260.rotorposition=26
config.Nims.0.advanced.sat.260.usals=false
config.Nims.0.advanced.sat.30.lnb=1
config.Nims.0.advanced.sat.30.rotorposition=3
config.Nims.0.advanced.sat.30.usals=false
config.Nims.0.advanced.sat.305.lnb=1
config.Nims.0.advanced.sat.305.rotorposition=31
config.Nims.0.advanced.sat.305.usals=false
config.Nims.0.advanced.sat.310.lnb=1
config.Nims.0.advanced.sat.310.rotorposition=31
config.Nims.0.advanced.sat.310.usals=false
config.Nims.0.advanced.sat.315.lnb=1
config.Nims.0.advanced.sat.315.rotorposition=32
config.Nims.0.advanced.sat.315.usals=false
config.Nims.0.advanced.sat.330.lnb=1
config.Nims.0.advanced.sat.330.rotorposition=33
config.Nims.0.advanced.sat.330.usals=false
config.Nims.0.advanced.sat.3300.lnb=1
config.Nims.0.advanced.sat.3300.rotorposition=30
config.Nims.0.advanced.sat.3300.usals=false
config.Nims.0.advanced.sat.3380.lnb=1
config.Nims.0.advanced.sat.3380.rotorposition=22
config.Nims.0.advanced.sat.3380.usals=false
config.Nims.0.advanced.sat.3450.lnb=1
config.Nims.0.advanced.sat.3450.rotorposition=15
config.Nims.0.advanced.sat.3450.usals=false
config.Nims.0.advanced.sat.3460.lnb=1
config.Nims.0.advanced.sat.3460.rotorposition=14
config.Nims.0.advanced.sat.3460.usals=false
config.Nims.0.advanced.sat.3520.lnb=1
config.Nims.0.advanced.sat.3520.rotorposition=8
config.Nims.0.advanced.sat.3520.usals=false
config.Nims.0.advanced.sat.3530.lnb=1
config.Nims.0.advanced.sat.3530.rotorposition=8
config.Nims.0.advanced.sat.3530.usals=false
config.Nims.0.advanced.sat.3560.lnb=1
config.Nims.0.advanced.sat.3560.rotorposition=4
config.Nims.0.advanced.sat.3560.usals=false
config.Nims.0.advanced.sat.3592.lnb=1
config.Nims.0.advanced.sat.3592.usals=false
config.Nims.0.advanced.sat.360.lnb=1
config.Nims.0.advanced.sat.360.rotorposition=36
config.Nims.0.advanced.sat.360.usals=false
config.Nims.0.advanced.sat.390.lnb=1
config.Nims.0.advanced.sat.390.rotorposition=39
config.Nims.0.advanced.sat.390.usals=false
config.Nims.0.advanced.sat.420.lnb=1
config.Nims.0.advanced.sat.420.rotorposition=42
config.Nims.0.advanced.sat.420.usals=false
config.Nims.0.advanced.sat.450.lnb=1
config.Nims.0.advanced.sat.450.rotorposition=45
config.Nims.0.advanced.sat.450.usals=false
config.Nims.0.advanced.sat.460.lnb=1
config.Nims.0.advanced.sat.460.rotorposition=46
config.Nims.0.advanced.sat.460.usals=false
config.Nims.0.advanced.sat.48.lnb=1
config.Nims.0.advanced.sat.48.rotorposition=5
config.Nims.0.advanced.sat.48.usals=false
config.Nims.0.advanced.sat.520.lnb=1
config.Nims.0.advanced.sat.520.rotorposition=52
config.Nims.0.advanced.sat.520.usals=false
config.Nims.0.advanced.sat.525.lnb=1
config.Nims.0.advanced.sat.525.rotorposition=52
config.Nims.0.advanced.sat.525.usals=false
config.Nims.0.advanced.sat.530.lnb=1
config.Nims.0.advanced.sat.530.rotorposition=53
config.Nims.0.advanced.sat.530.usals=false
config.Nims.0.advanced.sat.549.lnb=1
config.Nims.0.advanced.sat.549.rotorposition=55
config.Nims.0.advanced.sat.549.usals=false
config.Nims.0.advanced.sat.620.lnb=1
config.Nims.0.advanced.sat.620.rotorposition=62
config.Nims.0.advanced.sat.620.usals=false
config.Nims.0.advanced.sat.70.lnb=1
config.Nims.0.advanced.sat.70.rotorposition=7
config.Nims.0.advanced.sat.70.usals=false
config.Nims.0.advanced.sat.90.lnb=1
config.Nims.0.advanced.sat.90.rotorposition=9
config.Nims.0.advanced.sat.90.usals=false
config.Nims.0.advanced.sats=216
config.Nims.0.configMode=advanced
config.Nims.0.dvbs.advanced.lnb.1.diseqcMode=1_2
config.Nims.0.dvbs.advanced.lnb.1.powerMeasurement=false
config.Nims.0.dvbs.advanced.sat.100.lnb=1
config.Nims.0.dvbs.advanced.sat.100.rotorposition=10
config.Nims.0.dvbs.advanced.sat.100.usals=false
config.Nims.0.dvbs.advanced.sat.130.lnb=1
config.Nims.0.dvbs.advanced.sat.130.rotorposition=13
config.Nims.0.dvbs.advanced.sat.130.usals=false
config.Nims.0.dvbs.advanced.sat.160.lnb=1
config.Nims.0.dvbs.advanced.sat.160.rotorposition=16
config.Nims.0.dvbs.advanced.sat.160.usals=false
config.Nims.0.dvbs.advanced.sat.19.lnb=1
config.Nims.0.dvbs.advanced.sat.19.rotorposition=2
config.Nims.0.dvbs.advanced.sat.19.usals=false
config.Nims.0.dvbs.advanced.sat.192.lnb=1
config.Nims.0.dvbs.advanced.sat.192.rotorposition=19
config.Nims.0.dvbs.advanced.sat.192.usals=false
config.Nims.0.dvbs.advanced.sat.235.lnb=1
config.Nims.0.dvbs.advanced.sat.235.rotorposition=23
config.Nims.0.dvbs.advanced.sat.235.usals=false
config.Nims.0.dvbs.advanced.sat.255.lnb=1
config.Nims.0.dvbs.advanced.sat.255.rotorposition=26
config.Nims.0.dvbs.advanced.sat.255.usals=false
config.Nims.0.dvbs.advanced.sat.260.lnb=1
config.Nims.0.dvbs.advanced.sat.260.rotorposition=26
config.Nims.0.dvbs.advanced.sat.260.usals=false
config.Nims.0.dvbs.advanced.sat.30.lnb=1
config.Nims.0.dvbs.advanced.sat.30.rotorposition=3
config.Nims.0.dvbs.advanced.sat.30.usals=false
config.Nims.0.dvbs.advanced.sat.305.lnb=1
config.Nims.0.dvbs.advanced.sat.305.rotorposition=31
config.Nims.0.dvbs.advanced.sat.305.usals=false
config.Nims.0.dvbs.advanced.sat.310.lnb=1
config.Nims.0.dvbs.advanced.sat.310.rotorposition=31
config.Nims.0.dvbs.advanced.sat.310.usals=false
config.Nims.0.dvbs.advanced.sat.3300.lnb=1
config.Nims.0.dvbs.advanced.sat.3300.rotorposition=30
config.Nims.0.dvbs.advanced.sat.3300.usals=false
config.Nims.0.dvbs.advanced.sat.3380.lnb=1
config.Nims.0.dvbs.advanced.sat.3380.rotorposition=22
config.Nims.0.dvbs.advanced.sat.3380.usals=false
config.Nims.0.dvbs.advanced.sat.3450.lnb=1
config.Nims.0.dvbs.advanced.sat.3450.rotorposition=15
config.Nims.0.dvbs.advanced.sat.3450.usals=false
config.Nims.0.dvbs.advanced.sat.3460.lnb=1
config.Nims.0.dvbs.advanced.sat.3460.rotorposition=14
config.Nims.0.dvbs.advanced.sat.3460.usals=false
config.Nims.0.dvbs.advanced.sat.3520.lnb=1
config.Nims.0.dvbs.advanced.sat.3520.rotorposition=8
config.Nims.0.dvbs.advanced.sat.3520.usals=false
config.Nims.0.dvbs.advanced.sat.3530.lnb=1
config.Nims.0.dvbs.advanced.sat.3530.rotorposition=8
config.Nims.0.dvbs.advanced.sat.3530.usals=false
config.Nims.0.dvbs.advanced.sat.3560.lnb=1
config.Nims.0.dvbs.advanced.sat.3560.rotorposition=4
config.Nims.0.dvbs.advanced.sat.3560.usals=false
config.Nims.0.dvbs.advanced.sat.3592.lnb=1
config.Nims.0.dvbs.advanced.sat.3592.usals=false
config.Nims.0.dvbs.advanced.sat.360.lnb=1
config.Nims.0.dvbs.advanced.sat.360.rotorposition=36
config.Nims.0.dvbs.advanced.sat.360.usals=false
config.Nims.0.dvbs.advanced.sat.390.lnb=1
config.Nims.0.dvbs.advanced.sat.390.rotorposition=39
config.Nims.0.dvbs.advanced.sat.390.usals=false
config.Nims.0.dvbs.advanced.sat.420.lnb=1
config.Nims.0.dvbs.advanced.sat.420.rotorposition=42
config.Nims.0.dvbs.advanced.sat.420.usals=false
config.Nims.0.dvbs.advanced.sat.450.lnb=1
config.Nims.0.dvbs.advanced.sat.450.rotorposition=45
config.Nims.0.dvbs.advanced.sat.450.usals=false
config.Nims.0.dvbs.advanced.sat.460.lnb=1
config.Nims.0.dvbs.advanced.sat.460.rotorposition=46
config.Nims.0.dvbs.advanced.sat.460.usals=false
config.Nims.0.dvbs.advanced.sat.48.lnb=1
config.Nims.0.dvbs.advanced.sat.48.rotorposition=5
config.Nims.0.dvbs.advanced.sat.48.usals=false
config.Nims.0.dvbs.advanced.sat.520.lnb=1
config.Nims.0.dvbs.advanced.sat.520.rotorposition=52
config.Nims.0.dvbs.advanced.sat.520.usals=false
config.Nims.0.dvbs.advanced.sat.525.lnb=1
config.Nims.0.dvbs.advanced.sat.525.rotorposition=52
config.Nims.0.dvbs.advanced.sat.525.usals=false
config.Nims.0.dvbs.advanced.sat.530.lnb=1
config.Nims.0.dvbs.advanced.sat.530.rotorposition=53
config.Nims.0.dvbs.advanced.sat.530.usals=false
config.Nims.0.dvbs.advanced.sat.549.lnb=1
config.Nims.0.dvbs.advanced.sat.549.rotorposition=55
config.Nims.0.dvbs.advanced.sat.549.usals=false
config.Nims.0.dvbs.advanced.sat.620.lnb=1
config.Nims.0.dvbs.advanced.sat.620.rotorposition=62
config.Nims.0.dvbs.advanced.sat.620.usals=false
config.Nims.0.dvbs.advanced.sat.70.lnb=1
config.Nims.0.dvbs.advanced.sat.70.rotorposition=7
config.Nims.0.dvbs.advanced.sat.70.usals=false
config.Nims.0.dvbs.advanced.sat.90.lnb=1
config.Nims.0.dvbs.advanced.sat.90.rotorposition=9
config.Nims.0.dvbs.advanced.sat.90.usals=false
config.Nims.0.dvbs.advanced.sats=3300
config.Nims.0.dvbs.configMode=advanced
config.Nims.0.lastsatrotorposition=3560
config.osd.dst_height=523
config.osd.dst_left=39
config.osd.dst_top=26
config.osd.dst_width=643
config.pep.brightness=133
config.plugins.AJPanel.backupPath=/media/hdd/Ajpanel_Eliesatpanel/
config.plugins.AJPanel.browserBookmarks=/usr/lib/enigma2/python/Plugins/Extensions/,/tmp/,/
config.plugins.AJPanel.browserStartPath=/hdd/
config.plugins.AJPanel.checkForUpdateAtStartup=True
config.plugins.AJPanel.customMenuPath=/media/hdd/Ajpanel_Eliesatpanel/
config.plugins.AJPanel.downloadedPackagesPath=/media/hdd/Ajpanel_Eliesatpanel/downloaded-packages/
config.plugins.AJPanel.exportedPIconsPath=/media/hdd/Ajpanel_Eliesatpanel/exported-picons/
config.plugins.AJPanel.exportedTablesPath=/media/hdd/Ajpanel_Eliesatpanel/exported-tables/
config.plugins.AJPanel.FileManagerExit=e
config.plugins.AJPanel.hideIptvServerChannPrefix=True
config.plugins.AJPanel.iptvAddToBouquetRefType=5002
config.plugins.AJPanel.lastCopyMoveDir=/
config.plugins.AJPanel.lastFeedPkgsDir=/hdd/dreamsatpanel/13-sport/
config.plugins.AJPanel.lastFileManFindSrt=/tmp
config.plugins.AJPanel.lastPkgProjDir=/etc/enigma2/MyMetrixLiteBackup.dat
config.plugins.AJPanel.lastTerminalCustCmdLineNum=307
config.plugins.AJPanel.packageOutputPath=/media/hdd/Ajpanel_Eliesatpanel/create-package-files/
config.plugins.AJPanel.PIconsPath=/media/hdd/picon/
config.plugins.AJPanel.screenshotFType=png
config.plugins.AJPanel.subtBGTransp=60
config.plugins.AJPanel.subtDelaySec=-1
config.plugins.AJPanel.subtShadowColor=#FF0000
config.plugins.AJPanel.subtTextFg=#FFFF00
config.plugins.bitrate.show_in_menu=infobar
config.plugins.bitrate.style_skin=compact
config.plugins.CacheFlush.enable=True
config.plugins.CacheFlush.free_default=8192
config.plugins.CacheFlush.scrinfo=False
config.plugins.CacheFlush.timescrinfo=9
config.plugins.chocholousekpicons.1.allowed=True
config.plugins.chocholousekpicons.1.background=transparent
config.plugins.epgimport.enabled=True
config.plugins.epgimport.wakeup=20:0
config.plugins.epgsearch.numorbpos=0
config.plugins.extra_epgimport.last_import=01 Apr 2026 20:14:27, 4207
config.plugins.FileCommander.pathLeft=/usr/share/enigma2/picon
config.plugins.FileCommander.pathRight=/media/hdd/picon
config.plugins.imdb.showinplugins=True
config.plugins.IPAudioPro.default_agent=True
config.plugins.IPAudioPro.epg=True
config.plugins.IPAudioPro.mainmenu=True
config.plugins.IPAudioPro.picons=True
config.plugins.OAWeather.weatherlocation=('Zouk Mosbeh, Mohafazat Mont-Liban, LEBANON', 35.62, 33.95667)
config.plugins.OAWeather.weatherservice=OpenMeteo
config.plugins.serviceapp.servicemp3.player=exteplayer3
config.plugins.serviceapp.servicemp3.replace=True
config.subtitles.dvb_subtitles_color=1
config.subtitles.pango_subtitle_colors=2
config.subtitles.ttx_subtitle_colors=2
config.timeshift.skipReturnToLive=True
config.timezone.area=Asia
config.timezone.val=Beirut
config.tv.lastroot=1:7:1:0:0:0:0:0:0:0:(type == 1) || (type == 17) || (type == 22) || (type == 25) || (type == 31) || (type == 32) || (type == 134) || (type == 195)FROM SATELLITES ORDER BY satellitePosition;1:7:0:0:0:0:1040000:0:0:0:(satellitePosition == 260) && (type == 1) || (type == 17) || (type == 22) || (type == 25) || (type == 31) || (type == 32) || (type == 134) || (type == 195)ORDER BY name:26.0E Ku-band Badr 7/8 & Es'hail 2 - Services;
config.tv.lastservice=1:0:1:5:1BC0:2BE:1040000:0:0:0:
config.usage.crypto_icon_mode=1
config.usage.date.compact=%-d %b 
config.usage.date.compressed=%-d%b 
config.usage.date.displayday=%a %-d %b
config.usage.dns=google
config.usage.enableInfoCover=True
config.usage.frontend_priority=expert_mode
config.usage.infobar_timeout=3
config.usage.informationExtraSpacing=True
config.usage.informationShowAllMenuScreens=True
config.usage.menu_sort_weight={'mainmenu': {'submenu': {'egami_selection': {'sort': 30}, 'plugin_selection': {'sort': 60}, 'timermenu': {'sort': 70}, 'setup': {'sort': 80}, 'information': {'sort': 90}, 'shutdown': {'sort': 120}, 'BouquetMakerXtream': {'sort': 110, 'hidden': True}, 'filecommand': {'sort': 40}, 'EGAMINews': {'sort': 50}, 'EStalker': {'sort': 130, 'hidden': True}, 'eliesat_panel_grid': {'sort': 20}, 'servicescanupdates_mainmenu': {'sort': 140, 'hidden': True}, 'simply_sports': {'sort': 100, 'hidden': True}, 'XStreamity': {'sort': 150, 'hidden': True}, 'Listen to your favorite commentators': {'sort': 10, 'hidden': True}}}}
config.usage.okbutton_mode=1
config.usage.screenSaverStartTimer=60
config.usage.second_infobar_timeout=10
config.usage.servicelist_picon_downsize=0
config.usage.servicelistpreview_mode=True
config.usage.servicename_fontsize=2
config.usage.servicenum_fontsize=2
config.usage.show_event_progress_in_servicelist=barleft
config.usage.show_infobar_channel_number=True
config.usage.show_notification_for_updates=False
config.usage.show_second_infobar=2
config.usage.showScreenPath=small
config.usage.shutdownOK=False
config.usage.swap_snr_on_osd=True
config.usage.use_force_overwrite=False
config.usage.use_package_conffile=False
config.usage.volume_instead_of_channelselection=True
config.volumeControl.longStep=10
config.volumeControl.pressStep=2
config.volumeControl.volume=0
EOF
#device
device=$(head -n 1 /etc/hostname)
echo "config.plugins.MyMetrixLiteOther.EHDtested="$device"_|_01" >> /tmp/file.txt

sync

mv /tmp/file.txt /etc/enigma2/settings

sync

sleep 5

# === Password Setup ===
#######################################
echo -e "root\nroot" | passwd root >/dev/null 2>&1 && log_action "Password set to root" && log_done || log_fail
sleep 3


