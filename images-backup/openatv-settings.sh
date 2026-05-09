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
config.ArabicSavior.fonts=/usr/lib/enigma2/python/Plugins/Extensions/ArabicSavior//fonts/Khalid-Art-bold.ttf
config.autolanguage.audio_autoselect1=orj dos ory org esl qaa qaf und mis mul ORY ORJ Audio_ORJ oth
config.autolanguage.audio_autoselect2=eng Englisch
config.autolanguage.audio_epglanguage_alternative=eng Englisch
config.av.edid_override=True
config.av.policy_169=bestfit
config.av.policy_43=bestfit
config.av.videomode.HDMI=1080p
config.crash.lastfulljobtrashtime=1778063247
config.lcd.bright=8
config.lcd.dimbright=4
config.misc.ButtonSetup.back=Plugins/Extensions/HistoryZapSelector/1
config.misc.ButtonSetup.cross_down=Infobar/zapUp
config.misc.ButtonSetup.cross_left=Infobar/volumeDown
config.misc.ButtonSetup.cross_right=Infobar/volumeUp
config.misc.ButtonSetup.cross_up=Infobar/zapDown
config.misc.ButtonSetup.info=Infobar/openBouquets
config.misc.ButtonSetup.info_long=Infobar/openSatellites
config.misc.ButtonSetup.list=Infobar/toggleShow
config.misc.ButtonSetup.next=Plugins/Extensions/AJPan/10
config.misc.ButtonSetup.previous=Plugins/Extensions/AJPan/2
config.misc.ButtonSetup.red=Plugins/Extensions/IPTVPlayer/1
config.misc.country=US
config.misc.epgcachepath=/media/hdd/
config.misc.firstrun=False
config.misc.initialchannelselection=False
config.misc.language=en
config.misc.lastrotorposition=3300
config.misc.locale=en_US
config.misc.migrationVersion=3
config.misc.nextWakeup=1778082694,-1,-1,0,0,-1,0
config.misc.SettingsVersion=1.1
config.misc.softcams=OSCam_11.725-r798
config.misc.startCounter=15
config.misc.use_ci_assignment=False
config.misc.videowizardenabled=False
config.misc.wizardLanguageEnabled=False
config.misc.zapmode=mutetilllock
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
config.OpenWebif.allow_upload_ipk=True
config.osd.dst_height=550
config.osd.dst_left=14
config.osd.dst_top=14
config.osd.dst_width=692
config.pep.brightness=133
config.plisettings.InfoBarEpg_mode=1
config.plugins.AJPanel.backupPath=/media/hdd/ajpanel_backup/
config.plugins.AJPanel.customMenuPath=/media/hdd/ajpanel_backup/
config.plugins.AJPanel.FileManagerExit=e
config.plugins.AJPanel.hideIptvServerAdultWords=True
config.plugins.AJPanel.hideIptvServerChannPrefix=True
config.plugins.AJPanel.lastCopyMoveDir=/etc/tuxbox/
config.plugins.AJPanel.showInMainMenu=True
config.plugins.autoresolution.delay_switch_mode=0
config.plugins.autoresolution.enable=True
config.plugins.autoresolution.showinfo=False
config.plugins.autotimer.show_help=False
config.plugins.bitrate.force_restart=False
config.plugins.bitrate.show_in_menu=infobar
config.plugins.bitrate.style_skin=compact
config.plugins.bitrate.x=1570
config.plugins.bitrate.y=220
config.plugins.CacheFlush.enable=True
config.plugins.CacheFlush.free_default=8192
config.plugins.CacheFlush.scrinfo=False
config.plugins.chocholousekpicons.1.allowed=True
config.plugins.chocholousekpicons.1.background=transparent
config.plugins.chocholousekpicons.1.picon_folder=/media/hdd/picon
config.plugins.epgsearch.numorbpos=0
config.plugins.imdb.showinplugins=True
config.plugins.IPToSAT.enable=True
config.plugins.IPToSAT.player=exteplayer3
config.plugins.KeyAdder.Autodownload_enabled=True
config.plugins.KeyAdder.Autodownload_sitelink=MOHAMED_OS
config.plugins.KeyAdder.wakeup=20:0
config.plugins.MetrixWeather.animationspeed=80
config.plugins.MetrixWeather.currentWeatherCode=34
config.plugins.MetrixWeather.currentWeatherDataValid=3
config.plugins.MetrixWeather.currentWeatherdate=2022-07-10
config.plugins.MetrixWeather.currentWeatherday=Sunday
config.plugins.MetrixWeather.currentWeatherfeelslike=32
config.plugins.MetrixWeather.currentWeatherhumidity=66
config.plugins.MetrixWeather.currentWeatherobservationtime=16:00:00
config.plugins.MetrixWeather.currentWeathershortday=Sun
config.plugins.MetrixWeather.currentWeatherTemp=29
config.plugins.MetrixWeather.currentWeatherText=Mostly Sunny
config.plugins.MetrixWeather.currentWeatherwinddisplay=18 km/h Southwest
config.plugins.MetrixWeather.currentWeatherwindspeed=18 km/h
config.plugins.MetrixWeather.detail=True
config.plugins.MetrixWeather.forecast=5
config.plugins.MetrixWeather.forecastTodayCode=32
config.plugins.MetrixWeather.forecastTodayTempMax=35
config.plugins.MetrixWeather.forecastTodayTempMin=28
config.plugins.MetrixWeather.forecastTodayText=Sunny
config.plugins.MetrixWeather.forecastTomorrowCode=32
config.plugins.MetrixWeather.forecastTomorrowCode2=32
config.plugins.MetrixWeather.forecastTomorrowCode3=32
config.plugins.MetrixWeather.forecastTomorrowdate=2022-07-11
config.plugins.MetrixWeather.forecastTomorrowdate2=2022-07-12
config.plugins.MetrixWeather.forecastTomorrowdate3=2022-07-13
config.plugins.MetrixWeather.forecastTomorrowday=Monday
config.plugins.MetrixWeather.forecastTomorrowday2=Tuesday
config.plugins.MetrixWeather.forecastTomorrowday3=Wednesday
config.plugins.MetrixWeather.forecastTomorrowshortday=Mon
config.plugins.MetrixWeather.forecastTomorrowshortday2=Tue
config.plugins.MetrixWeather.forecastTomorrowshortday3=Wed
config.plugins.MetrixWeather.forecastTomorrowTempMax=35
config.plugins.MetrixWeather.forecastTomorrowTempMax2=35
config.plugins.MetrixWeather.forecastTomorrowTempMax3=35
config.plugins.MetrixWeather.forecastTomorrowTempMin=27
config.plugins.MetrixWeather.forecastTomorrowTempMin2=28
config.plugins.MetrixWeather.forecastTomorrowTempMin3=28
config.plugins.MetrixWeather.forecastTomorrowText=Sunny
config.plugins.MetrixWeather.forecastTomorrowText2=Sunny
config.plugins.MetrixWeather.forecastTomorrowText3=Sunny
config.plugins.MetrixWeather.icontype=1
config.plugins.MetrixWeather.owm_geocode=35.62,33.95667
config.plugins.MetrixWeather.weathercity=Zouk Mosbeh
config.plugins.MetrixWeather.weatherservice=OpenMeteo
config.plugins.MetrixWeather.weekday=true
config.plugins.MetrixWeather.woeid=2911298
config.plugins.MyMetrixLiteColors.channelselectionprogress=F0A30A
config.plugins.MyMetrixLiteColors.channelselectionprogressborder=FFFFFF
config.plugins.MyMetrixLiteColors.channelselectionservicedescription=BF9217
config.plugins.MyMetrixLiteColors.epgbackground=000000
config.plugins.MyMetrixLiteColors.epgbackgroundtransparency=00
config.plugins.MyMetrixLiteColors.epgborderlines=FFFFFF
config.plugins.MyMetrixLiteColors.epgeventbackground=000000
config.plugins.MyMetrixLiteColors.epgeventbackgroundtransparency=00
config.plugins.MyMetrixLiteColors.epgeventdescriptionbackground=000000
config.plugins.MyMetrixLiteColors.epgeventdescriptionbackgroundtransparency=00
config.plugins.MyMetrixLiteColors.epgeventselectedbackground=000000
config.plugins.MyMetrixLiteColors.epgeventselectedbackgroundtransparency=00
config.plugins.MyMetrixLiteColors.epgservicebackground=000000
config.plugins.MyMetrixLiteColors.epgservicebackgroundtransparency=00
config.plugins.MyMetrixLiteColors.infobaraccent1=FFFFFF
config.plugins.MyMetrixLiteColors.infobaraccent2=FFFFFF
config.plugins.MyMetrixLiteColors.infobarbackground=000000
config.plugins.MyMetrixLiteColors.infobarbackgroundtransparency=00
config.plugins.MyMetrixLiteColors.infobarfont2=FFFFFF
config.plugins.MyMetrixLiteColors.infobarprogress=F0A30A
config.plugins.MyMetrixLiteColors.infobarprogresstransparency=00
config.plugins.MyMetrixLiteColors.layeraaccent1=FFFFFF
config.plugins.MyMetrixLiteColors.layeraaccent2=FFFFFF
config.plugins.MyMetrixLiteColors.layerabackground=000000
config.plugins.MyMetrixLiteColors.layerabackgroundtransparency=00
config.plugins.MyMetrixLiteColors.layeraextendedinfo1=FFFFFF
config.plugins.MyMetrixLiteColors.layeraextendedinfo2=FFFFFF
config.plugins.MyMetrixLiteColors.layeraprogress=F0A30A
config.plugins.MyMetrixLiteColors.layeraprogresstransparency=00
config.plugins.MyMetrixLiteColors.layeraselectionbackground=000000
config.plugins.MyMetrixLiteColors.layeraselectionbackgroundtransparency=00
config.plugins.MyMetrixLiteColors.layeraunderline=FFFFFF
config.plugins.MyMetrixLiteColors.layerbaccent1=FFFFFF
config.plugins.MyMetrixLiteColors.layerbaccent2=FFFFFF
config.plugins.MyMetrixLiteColors.layerbbackground=000000
config.plugins.MyMetrixLiteColors.layerbbackgroundtransparency=00
config.plugins.MyMetrixLiteColors.layerbprogress=F0A30A
config.plugins.MyMetrixLiteColors.layerbprogresstransparency=00
config.plugins.MyMetrixLiteColors.layerbselectionbackground=000000
config.plugins.MyMetrixLiteColors.layerbselectionbackgroundtransparency=00
config.plugins.MyMetrixLiteColors.listboxborder_bottomwidth=2px
config.plugins.MyMetrixLiteColors.listboxborder_left=A4C400
config.plugins.MyMetrixLiteColors.listboxborder_right=A4C400
config.plugins.MyMetrixLiteColors.listboxborder_topwidth=2px
config.plugins.MyMetrixLiteColors.menubackground=000000
config.plugins.MyMetrixLiteColors.menubackgroundtransparency=00
config.plugins.MyMetrixLiteColors.menusymbolbackground=000000
config.plugins.MyMetrixLiteColors.menusymbolbackgroundtransparency=00
config.plugins.MyMetrixLiteColors.optionallayerhorizontalbackground=2E2E2E
config.plugins.MyMetrixLiteColors.optionallayerhorizontaltransparency=34
config.plugins.MyMetrixLiteColors.windowborder_bottom=FFFFFF
config.plugins.MyMetrixLiteColors.windowborder_left=FFFFFF
config.plugins.MyMetrixLiteColors.windowborder_right=FFFFFF
config.plugins.MyMetrixLiteColors.windowborder_top=FFFFFF
config.plugins.MyMetrixLiteColors.windowtitletextback=000000
config.plugins.MyMetrixLiteFonts.epgevent_scale=100
config.plugins.MyMetrixLiteFonts.epginfo_scale=100
config.plugins.MyMetrixLiteFonts.epgtext_scale=100
config.plugins.MyMetrixLiteFonts.globalbutton_scale=105
config.plugins.MyMetrixLiteFonts.globalclock_scale=105
config.plugins.MyMetrixLiteFonts.globallarge_scale=105
config.plugins.MyMetrixLiteFonts.globalmenu_scale=105
config.plugins.MyMetrixLiteFonts.globalsmall_scale=105
config.plugins.MyMetrixLiteFonts.globaltitle_scale=105
config.plugins.MyMetrixLiteFonts.globalweatherweek_scale=105
config.plugins.MyMetrixLiteFonts.infobarevent_scale=105
config.plugins.MyMetrixLiteFonts.infobartext_scale=100
config.plugins.MyMetrixLiteFonts.Meteo_scale=105
config.plugins.MyMetrixLiteFonts.Regular_scale=100
config.plugins.MyMetrixLiteFonts.RegularLight_scale=100
config.plugins.MyMetrixLiteFonts.screeninfo_scale=105
config.plugins.MyMetrixLiteFonts.screenlabel_scale=100
config.plugins.MyMetrixLiteFonts.screentext_scale=100
config.plugins.MyMetrixLiteFonts.SetrixHD_scale=105
config.plugins.MyMetrixLiteFonts.SkinFontExamples=preset_1
config.plugins.MyMetrixLiteOther.channelSelectionStyle=CHANNELSELECTION-4
config.plugins.MyMetrixLiteOther.EHDenabled=1
config.plugins.MyMetrixLiteOther.EHDoldlinechanger=true
config.plugins.MyMetrixLiteOther.EHDrounddown=True
config.plugins.MyMetrixLiteOther.movielistStyle=right
config.plugins.MyMetrixLiteOther.piconresize_experimental=True
config.plugins.MyMetrixLiteOther.piconsharpness_experimental=5.00
config.plugins.MyMetrixLiteOther.runningTextSpeed=60
config.plugins.MyMetrixLiteOther.runningTextStartdelay=1200
config.plugins.MyMetrixLiteOther.setTunerManual=1
config.plugins.MyMetrixLiteOther.showChannelName=False
config.plugins.MyMetrixLiteOther.showChannelNumber=False
config.plugins.MyMetrixLiteOther.showExtended_caid=False
config.plugins.MyMetrixLiteOther.showExtendedinfo=True
config.plugins.MyMetrixLiteOther.showInfoBarResolutionExtended=True
config.plugins.MyMetrixLiteOther.showMovieListScrollbar=True
config.plugins.MyMetrixLiteOther.showRAMfree=True
config.plugins.MyMetrixLiteOther.showSTBinfo=True
config.plugins.MyMetrixLiteOther.SkinDesignButtons=True
config.plugins.MyMetrixLiteOther.SkinDesignButtonsBackColor=000000
config.plugins.MyMetrixLiteOther.SkinDesignButtonsTextColor=FFFFFF
config.plugins.MyMetrixLiteOther.SkinDesignButtonsTextFont=/usr/share/fonts/ae_AlMateen.ttf
config.plugins.MyMetrixLiteOther.SkinDesignInfobarZZZPiconPosX=0
config.plugins.MyMetrixLiteOther.SkinDesignInfobarZZZPiconPosY=0
config.plugins.MyMetrixLiteOther.SkinDesignInfobarZZZPiconSize=0
config.plugins.MyMetrixLiteOther.SkinDesignLLCheight=720
config.plugins.MyMetrixLiteOther.SkinDesignLLCposz=1
config.plugins.MyMetrixLiteOther.SkinDesignLLCwidth=795
config.plugins.MyMetrixLiteOther.SkinDesignLUCheight=41
config.plugins.MyMetrixLiteOther.SkinDesignLUCposz=1
config.plugins.MyMetrixLiteOther.SkinDesignLUCwidth=200
config.plugins.MyMetrixLiteOther.SkinDesignOLH=screens
config.plugins.MyMetrixLiteOther.SkinDesignOLHheight=670
config.plugins.MyMetrixLiteOther.SkinDesignOLHposx=30
config.plugins.MyMetrixLiteOther.SkinDesignOLHposy=15
config.plugins.MyMetrixLiteOther.SkinDesignOLHposz=1
config.plugins.MyMetrixLiteOther.SkinDesignOLHwidth=1220
config.plugins.MyMetrixLiteOther.SkinDesignOLVheight=3
config.plugins.MyMetrixLiteOther.SkinDesignOLVposx=0
config.plugins.MyMetrixLiteOther.SkinDesignOLVposy=696
config.plugins.MyMetrixLiteOther.SkinDesignOLVposz=1
config.plugins.MyMetrixLiteOther.SkinDesignOLVwidth=1280
config.plugins.MyMetrixLiteOther.SkinDesignRLCheight=101
config.plugins.MyMetrixLiteOther.SkinDesignRLCwidth=1280
config.plugins.MyMetrixLiteOther.SkinDesignRUCheight=720
config.plugins.MyMetrixLiteOther.SkinDesignRUCposz=1
config.plugins.MyMetrixLiteOther.SkinDesignRUCwidth=1280
config.plugins.PermanentClock.enabled=True
config.plugins.PermanentClock.position_x=217
config.plugins.PermanentClock.position_y=0
config.plugins.serviceapp.servicemp3.player=exteplayer3
config.plugins.serviceapp.servicemp3.replace=True
config.plugins.setpicon.sorting=1
config.plugins.setpicon.target=/media/hdd/picon/
config.plugins.setpicon.type=1
config.skin.primary_skin=MetrixHD/skin.MySkin.xml
config.subtitles.ai_subtitle_colors=2
config.subtitles.ai_translate_to=ar_sy
config.timeshift.allowedPaths=['/media/hdd/timeshift/', '/hdd/timeshift/']
config.timeshift.skipReturnToLive=True
config.tv.lastroot=1:7:1:0:0:0:0:0:0:0:FROM BOUQUET "bouquets.tv" ORDER BY bouquet;1:7:0:0:0:0:CE40000:0:0:0:(satellitePosition == 3300) && (type == 1) || (type == 17) || (type == 22) || (type == 25) || (type == 31) || (type == 32) || (type == 134) || (type == 195)ORDER BY name:30.0W Hispasat 30W-5/30W-6 - Services;
config.tv.lastservice=-1:0:0:0:0:0:0:0:0:0:
config.usage.boolean_graphic=True
config.usage.crypto_icon_mode=1
config.usage.date.compact=%-d %b 
config.usage.date.compressed=%-d%b 
config.usage.date.displayday=%a %-d %b
config.usage.dns=google
config.usage.informationExtraSpacing=True
config.usage.informationShowAllMenuScreens=True
config.usage.menu_sort_weight={'mainmenu': {'submenu': {'information': {'sort': 40}, 'timermenu': {'sort': 50}, 'plugin_selection': {'sort': 60}, 'setup': {'sort': 70}, 'shutdown': {'sort': 140}, 'BouquetMakerXtream': {'sort': 90, 'hidden': True}, 'egami_boot': {'sort': 30}, 'EStalker': {'sort': 100, 'hidden': True}, 'eliesat_panel_grid': {'sort': 20}, 'servicescanupdates_mainmenu': {'sort': 110, 'hidden': True}, 'simply_sports': {'sort': 80, 'hidden': True}, 'XStreamity': {'sort': 120, 'hidden': True}, 'movie_selection': {'sort': 130}, 'AJPanel': {'sort': 10, 'hidden': True}}}}
config.usage.menuEntryStyle=both
config.usage.movieSelectionInMenu=True
config.usage.numberZapDisplay=both
config.usage.numzappicon=True
config.usage.okbutton_mode=1
config.usage.panicbutton=True
config.usage.progressinfo_fontsize=-2
config.usage.screenSaverStartTimer=60
config.usage.second_infobar_timeout=10
config.usage.service_icon_enable=True
config.usage.serviceinfo_fontsize=-2
config.usage.servicelist_picon_downsize=0
config.usage.servicelistpreview_mode=True
config.usage.servicename_fontsize=2
config.usage.servicenum_fontsize=2
config.usage.show_event_progress_in_servicelist=barleft
config.usage.show_infobar_channel_number=True
config.usage.show_second_infobar=2
config.usage.showScreenPath=small
config.usage.shutdownOK=False
config.usage.swap_snr_on_osd=True
config.usage.updownbutton_mode=0
config.volumeControl.longStep=10
config.volumeControl.pressStep=2
config.volumeControl.volume=24
EOF
#device
device=$(head -n 1 /etc/hostname)
echo "config.plugins.MyMetrixLiteOther.EHDtested="$device"_|_01" >> /tmp/file.txt

sync

mv /tmp/file.txt /etc/enigma2/settings

sync

sleep 5

#!/bin/sh

PACKAGE_URL="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/images-backup/openatv-settings-8.0.tar.gz"
PACKAGE_FILE="/tmp/openatv-settings-8.0.tar.gz"

# Remove old file if exists
rm -f "$PACKAGE_FILE"

wget -O "$PACKAGE_FILE" "$PACKAGE_URL"

if [ $? -ne 0 ]; then
    echo "Download failed!"
    exit 1
fi

tar -xzf "$PACKAGE_FILE" -C /

if [ $? -ne 0 ]; then
    echo "Extraction failed!"
    rm -f "$PACKAGE_FILE"
    exit 1
fi

rm -f "$PACKAGE_FILE"


