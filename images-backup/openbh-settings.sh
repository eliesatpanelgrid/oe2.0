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

AREA=$(echo "$TZ" | cut -d'/' -f1)
VAL=$(echo "$TZ" | cut -d'/' -f2)

log ""

sleep 3
rm -rf /tmp/file.txt
touch /tmp/file.txt
SETTINGS="/tmp/file.txt"
FAV="/etc/enigma2/oaweather_fav.dat"

    # Auto detect location
    API_URL="http://ip-api.com/json"

    DATA=$(wget -qO- "$API_URL")

    CITY=$(echo "$DATA" | sed -n 's/.*"city":"\([^"]*\)".*/\1/p')
    REGION=$(echo "$DATA" | sed -n 's/.*"regionName":"\([^"]*\)".*/\1/p')
    COUNTRY=$(echo "$DATA" | sed -n 's/.*"country":"\([^"]*\)".*/\1/p')
    LAT=$(echo "$DATA" | sed -n 's/.*"lat":\([^,]*\).*/\1/p')
    LON=$(echo "$DATA" | sed -n 's/.*"lon":\([^,}]*\).*/\1/p')

    LOCATION="${CITY}, ${REGION}, ${COUNTRY}"

sed -i '/^config\.plugins\.OAWeather\.weatherlocation=/d' "$SETTINGS"

cat <<EOF >> /tmp/file.txt
config.ArabicSavior.fonts=/usr/lib/enigma2/python/Plugins/Extensions/ArabicSavior//fonts/SaberArnane-Subtitle.ttf
config.audio.volume=50
config.autolanguage.audio_autoselect1=eng Englisch
config.autolanguage.audio_autoselect2=orj dos ory org esl qaa qaf und mis mul ORY ORJ Audio_ORJ oth
config.autolanguage.audio_epglanguage=eng Englisch
config.autolanguage.audio_epglanguage_alternative=orj dos ory org esl qaa qaf und mis mul ORY ORJ Audio_ORJ oth
config.av.edid_override=True
config.av.generalAC3delay=0
config.av.generalPCMdelay=0
config.av.policy_169=auto
config.av.policy_43=auto
config.av.videomode.HDMI=1080p
config.av.volume_stepsize=10
config.ci.0.enabled=False
config.crash.debugLevel=4
config.crash.debugTimeFormat=2
config.crash.lastfulljobtrashtime=1782923968
config.lcd.bright=8
config.lcd.dimbright=4
config.misc.ButtonSetup.cross_down=Infobar/zapUp
config.misc.ButtonSetup.cross_up=Infobar/zapDown
config.misc.ButtonSetup.info=Infobar/openFavouritesList
config.misc.ButtonSetup.info_long=Infobar/openServiceList
config.misc.ButtonSetup.list=Module/Screens.ScanSetup/ScanSetup,MenuPlugin/scan/satfinder,MenuPlugin/scan/blindscan
config.misc.ButtonSetup.next=Plugins/Extensions/AJPan/10
config.misc.ButtonSetup.previous=Plugins/Extensions/AJPan/2
config.misc.country=GB
config.misc.epgcachepath=/media/hdd/
config.misc.firstrun=False
config.misc.initialchannelselection=False
config.misc.language=en
config.misc.languageselected=False
config.misc.lastrotorposition=215
config.misc.load_unlinked_userbouquets=1
config.misc.locale=en_GB
config.misc.migrationVersion=3
config.misc.nextWakeup=1782930849,-1,-1,0,0,-1,0
config.misc.SettingsVersion=1.1
config.misc.startCounter=416
config.misc.videowizardenabled=False
config.misc.wizardLanguageEnabled=False
config.misc.zapkey_delay=5
config.movielist.last_videodir=/media/hdd/movie/.Trash/
config.NewVirtualKeyBoard.firsttime=False
config.NewVirtualKeyBoard.lastsearchText=disclosure day
config.NewVirtualKeyBoard.textinput=NewVirtualKeyBoard
config.Nims.0.advanced.lnb.1.diseqcMode=1_2
config.Nims.0.advanced.lnb.1.powerMeasurement=false
config.Nims.0.advanced.sat.19.lnb=1
config.Nims.0.advanced.sat.19.rotorposition=2
config.Nims.0.advanced.sat.19.usals=False
config.Nims.0.advanced.sat.30.lnb=1
config.Nims.0.advanced.sat.30.rotorposition=3
config.Nims.0.advanced.sat.30.usals=False
config.Nims.0.advanced.sat.48.lnb=1
config.Nims.0.advanced.sat.48.rotorposition=5
config.Nims.0.advanced.sat.48.usals=False
config.Nims.0.advanced.sat.70.lnb=1
config.Nims.0.advanced.sat.70.rotorposition=7
config.Nims.0.advanced.sat.70.usals=False
config.Nims.0.advanced.sat.90.lnb=1
config.Nims.0.advanced.sat.90.rotorposition=9
config.Nims.0.advanced.sat.90.usals=False
config.Nims.0.advanced.sat.100.lnb=1
config.Nims.0.advanced.sat.100.rotorposition=10
config.Nims.0.advanced.sat.100.usals=False
config.Nims.0.advanced.sat.130.lnb=1
config.Nims.0.advanced.sat.130.rotorposition=13
config.Nims.0.advanced.sat.130.usals=False
config.Nims.0.advanced.sat.160.lnb=1
config.Nims.0.advanced.sat.160.rotorposition=16
config.Nims.0.advanced.sat.160.usals=False
config.Nims.0.advanced.sat.192.lnb=1
config.Nims.0.advanced.sat.192.rotorposition=19
config.Nims.0.advanced.sat.192.usals=False
config.Nims.0.advanced.sat.215.lnb=1
config.Nims.0.advanced.sat.215.rotorposition=21
config.Nims.0.advanced.sat.215.usals=False
config.Nims.0.advanced.sat.235.lnb=1
config.Nims.0.advanced.sat.235.rotorposition=23
config.Nims.0.advanced.sat.235.usals=False
config.Nims.0.advanced.sat.255.lnb=1
config.Nims.0.advanced.sat.255.rotorposition=26
config.Nims.0.advanced.sat.255.usals=False
config.Nims.0.advanced.sat.260.lnb=1
config.Nims.0.advanced.sat.260.rotorposition=26
config.Nims.0.advanced.sat.260.usals=False
config.Nims.0.advanced.sat.282.lnb=1
config.Nims.0.advanced.sat.282.rotorposition=28
config.Nims.0.advanced.sat.282.usals=False
config.Nims.0.advanced.sat.305.lnb=1
config.Nims.0.advanced.sat.305.rotorposition=31
config.Nims.0.advanced.sat.305.usals=False
config.Nims.0.advanced.sat.310.lnb=1
config.Nims.0.advanced.sat.310.rotorposition=31
config.Nims.0.advanced.sat.310.usals=False
config.Nims.0.advanced.sat.360.lnb=1
config.Nims.0.advanced.sat.360.rotorposition=36
config.Nims.0.advanced.sat.360.usals=False
config.Nims.0.advanced.sat.390.lnb=1
config.Nims.0.advanced.sat.390.rotorposition=39
config.Nims.0.advanced.sat.390.usals=False
config.Nims.0.advanced.sat.400.lnb=1
config.Nims.0.advanced.sat.400.rotorposition=40
config.Nims.0.advanced.sat.400.usals=False
config.Nims.0.advanced.sat.420.lnb=1
config.Nims.0.advanced.sat.420.rotorposition=42
config.Nims.0.advanced.sat.420.usals=False
config.Nims.0.advanced.sat.450.lnb=1
config.Nims.0.advanced.sat.450.rotorposition=45
config.Nims.0.advanced.sat.450.usals=False
config.Nims.0.advanced.sat.460.lnb=1
config.Nims.0.advanced.sat.460.rotorposition=46
config.Nims.0.advanced.sat.460.usals=False
config.Nims.0.advanced.sat.500.lnb=1
config.Nims.0.advanced.sat.500.rotorposition=50
config.Nims.0.advanced.sat.500.usals=False
config.Nims.0.advanced.sat.515.lnb=1
config.Nims.0.advanced.sat.515.rotorposition=51
config.Nims.0.advanced.sat.515.usals=False
config.Nims.0.advanced.sat.520.lnb=1
config.Nims.0.advanced.sat.520.rotorposition=52
config.Nims.0.advanced.sat.520.usals=False
config.Nims.0.advanced.sat.525.lnb=1
config.Nims.0.advanced.sat.525.rotorposition=52
config.Nims.0.advanced.sat.525.usals=False
config.Nims.0.advanced.sat.530.lnb=1
config.Nims.0.advanced.sat.530.rotorposition=53
config.Nims.0.advanced.sat.530.usals=False
config.Nims.0.advanced.sat.549.lnb=1
config.Nims.0.advanced.sat.549.rotorposition=55
config.Nims.0.advanced.sat.549.usals=False
config.Nims.0.advanced.sat.570.lnb=1
config.Nims.0.advanced.sat.570.rotorposition=57
config.Nims.0.advanced.sat.570.usals=False
config.Nims.0.advanced.sat.620.lnb=1
config.Nims.0.advanced.sat.620.rotorposition=62
config.Nims.0.advanced.sat.620.usals=False
config.Nims.0.advanced.sat.660.lnb=1
config.Nims.0.advanced.sat.660.rotorposition=61
config.Nims.0.advanced.sat.660.usals=False
config.Nims.0.advanced.sat.685.lnb=1
config.Nims.0.advanced.sat.685.rotorposition=63
config.Nims.0.advanced.sat.685.usals=False
config.Nims.0.advanced.sat.705.lnb=1
config.Nims.0.advanced.sat.705.rotorposition=64
config.Nims.0.advanced.sat.705.usals=False
config.Nims.0.advanced.sat.800.lnb=1
config.Nims.0.advanced.sat.800.rotorposition=60
config.Nims.0.advanced.sat.800.usals=False
config.Nims.0.advanced.sat.3255.lnb=1
config.Nims.0.advanced.sat.3255.rotorposition=34
config.Nims.0.advanced.sat.3255.usals=False
config.Nims.0.advanced.sat.3300.lnb=1
config.Nims.0.advanced.sat.3300.rotorposition=30
config.Nims.0.advanced.sat.3300.usals=False
config.Nims.0.advanced.sat.3355.lnb=1
config.Nims.0.advanced.sat.3355.rotorposition=24
config.Nims.0.advanced.sat.3355.usals=False
config.Nims.0.advanced.sat.3380.lnb=1
config.Nims.0.advanced.sat.3380.rotorposition=22
config.Nims.0.advanced.sat.3380.usals=False
config.Nims.0.advanced.sat.3450.lnb=1
config.Nims.0.advanced.sat.3450.rotorposition=15
config.Nims.0.advanced.sat.3450.usals=False
config.Nims.0.advanced.sat.3460.lnb=1
config.Nims.0.advanced.sat.3460.rotorposition=14
config.Nims.0.advanced.sat.3460.usals=False
config.Nims.0.advanced.sat.3520.lnb=1
config.Nims.0.advanced.sat.3520.rotorposition=8
config.Nims.0.advanced.sat.3520.usals=False
config.Nims.0.advanced.sat.3530.lnb=1
config.Nims.0.advanced.sat.3530.rotorposition=8
config.Nims.0.advanced.sat.3530.usals=False
config.Nims.0.advanced.sat.3550.lnb=1
config.Nims.0.advanced.sat.3550.rotorposition=4
config.Nims.0.advanced.sat.3550.usals=False
config.Nims.0.advanced.sat.3560.lnb=1
config.Nims.0.advanced.sat.3560.rotorposition=4
config.Nims.0.advanced.sat.3560.usals=False
config.Nims.0.advanced.sat.3592.lnb=1
config.Nims.0.advanced.sat.3592.usals=False
config.Nims.0.advanced.sats=800
config.Nims.0.configMode=advanced
config.Nims.0.dvbs.advanced.lnb.1.diseqcMode=1_2
config.Nims.0.dvbs.advanced.lnb.1.powerMeasurement=false
config.Nims.0.dvbs.advanced.sat.19.lnb=1
config.Nims.0.dvbs.advanced.sat.19.rotorposition=2
config.Nims.0.dvbs.advanced.sat.19.usals=False
config.Nims.0.dvbs.advanced.sat.30.lnb=1
config.Nims.0.dvbs.advanced.sat.30.rotorposition=3
config.Nims.0.dvbs.advanced.sat.30.usals=False
config.Nims.0.dvbs.advanced.sat.48.lnb=1
config.Nims.0.dvbs.advanced.sat.48.rotorposition=5
config.Nims.0.dvbs.advanced.sat.48.usals=False
config.Nims.0.dvbs.advanced.sat.70.lnb=1
config.Nims.0.dvbs.advanced.sat.70.rotorposition=7
config.Nims.0.dvbs.advanced.sat.70.usals=False
config.Nims.0.dvbs.advanced.sat.90.lnb=1
config.Nims.0.dvbs.advanced.sat.90.rotorposition=9
config.Nims.0.dvbs.advanced.sat.90.usals=False
config.Nims.0.dvbs.advanced.sat.100.lnb=1
config.Nims.0.dvbs.advanced.sat.100.rotorposition=10
config.Nims.0.dvbs.advanced.sat.100.usals=False
config.Nims.0.dvbs.advanced.sat.130.lnb=1
config.Nims.0.dvbs.advanced.sat.130.rotorposition=13
config.Nims.0.dvbs.advanced.sat.130.usals=False
config.Nims.0.dvbs.advanced.sat.160.lnb=1
config.Nims.0.dvbs.advanced.sat.160.rotorposition=16
config.Nims.0.dvbs.advanced.sat.160.usals=False
config.Nims.0.dvbs.advanced.sat.192.lnb=1
config.Nims.0.dvbs.advanced.sat.192.rotorposition=19
config.Nims.0.dvbs.advanced.sat.192.usals=False
config.Nims.0.dvbs.advanced.sat.215.lnb=1
config.Nims.0.dvbs.advanced.sat.215.rotorposition=21
config.Nims.0.dvbs.advanced.sat.215.usals=False
config.Nims.0.dvbs.advanced.sat.235.lnb=1
config.Nims.0.dvbs.advanced.sat.235.rotorposition=23
config.Nims.0.dvbs.advanced.sat.235.usals=False
config.Nims.0.dvbs.advanced.sat.255.lnb=1
config.Nims.0.dvbs.advanced.sat.255.rotorposition=26
config.Nims.0.dvbs.advanced.sat.255.usals=False
config.Nims.0.dvbs.advanced.sat.260.lnb=1
config.Nims.0.dvbs.advanced.sat.260.rotorposition=26
config.Nims.0.dvbs.advanced.sat.260.usals=False
config.Nims.0.dvbs.advanced.sat.282.lnb=1
config.Nims.0.dvbs.advanced.sat.282.rotorposition=28
config.Nims.0.dvbs.advanced.sat.282.usals=False
config.Nims.0.dvbs.advanced.sat.305.lnb=1
config.Nims.0.dvbs.advanced.sat.305.rotorposition=31
config.Nims.0.dvbs.advanced.sat.305.usals=False
config.Nims.0.dvbs.advanced.sat.310.lnb=1
config.Nims.0.dvbs.advanced.sat.310.rotorposition=31
config.Nims.0.dvbs.advanced.sat.310.usals=False
config.Nims.0.dvbs.advanced.sat.360.lnb=1
config.Nims.0.dvbs.advanced.sat.360.rotorposition=36
config.Nims.0.dvbs.advanced.sat.360.usals=False
config.Nims.0.dvbs.advanced.sat.390.lnb=1
config.Nims.0.dvbs.advanced.sat.390.rotorposition=39
config.Nims.0.dvbs.advanced.sat.390.usals=False
config.Nims.0.dvbs.advanced.sat.420.lnb=1
config.Nims.0.dvbs.advanced.sat.420.rotorposition=42
config.Nims.0.dvbs.advanced.sat.420.usals=False
config.Nims.0.dvbs.advanced.sat.450.lnb=1
config.Nims.0.dvbs.advanced.sat.450.rotorposition=45
config.Nims.0.dvbs.advanced.sat.450.usals=False
config.Nims.0.dvbs.advanced.sat.460.lnb=1
config.Nims.0.dvbs.advanced.sat.460.rotorposition=46
config.Nims.0.dvbs.advanced.sat.460.usals=False
config.Nims.0.dvbs.advanced.sat.520.lnb=1
config.Nims.0.dvbs.advanced.sat.520.rotorposition=52
config.Nims.0.dvbs.advanced.sat.520.usals=False
config.Nims.0.dvbs.advanced.sat.525.lnb=1
config.Nims.0.dvbs.advanced.sat.525.rotorposition=52
config.Nims.0.dvbs.advanced.sat.525.usals=False
config.Nims.0.dvbs.advanced.sat.530.lnb=1
config.Nims.0.dvbs.advanced.sat.530.rotorposition=53
config.Nims.0.dvbs.advanced.sat.530.usals=False
config.Nims.0.dvbs.advanced.sat.549.lnb=1
config.Nims.0.dvbs.advanced.sat.549.rotorposition=55
config.Nims.0.dvbs.advanced.sat.549.usals=False
config.Nims.0.dvbs.advanced.sat.560.lnb=1
config.Nims.0.dvbs.advanced.sat.560.rotorposition=56
config.Nims.0.dvbs.advanced.sat.560.usals=False
config.Nims.0.dvbs.advanced.sat.570.lnb=1
config.Nims.0.dvbs.advanced.sat.570.rotorposition=57
config.Nims.0.dvbs.advanced.sat.570.usals=False
config.Nims.0.dvbs.advanced.sat.620.lnb=1
config.Nims.0.dvbs.advanced.sat.620.rotorposition=62
config.Nims.0.dvbs.advanced.sat.620.usals=False
config.Nims.0.dvbs.advanced.sat.660.lnb=1
config.Nims.0.dvbs.advanced.sat.660.rotorposition=61
config.Nims.0.dvbs.advanced.sat.660.usals=False
config.Nims.0.dvbs.advanced.sat.685.lnb=1
config.Nims.0.dvbs.advanced.sat.685.rotorposition=63
config.Nims.0.dvbs.advanced.sat.685.usals=False
config.Nims.0.dvbs.advanced.sat.705.lnb=1
config.Nims.0.dvbs.advanced.sat.705.rotorposition=64
config.Nims.0.dvbs.advanced.sat.705.usals=False
config.Nims.0.dvbs.advanced.sat.3255.lnb=1
config.Nims.0.dvbs.advanced.sat.3255.rotorposition=34
config.Nims.0.dvbs.advanced.sat.3255.usals=False
config.Nims.0.dvbs.advanced.sat.3300.lnb=1
config.Nims.0.dvbs.advanced.sat.3300.rotorposition=30
config.Nims.0.dvbs.advanced.sat.3300.usals=False
config.Nims.0.dvbs.advanced.sat.3380.lnb=1
config.Nims.0.dvbs.advanced.sat.3380.rotorposition=22
config.Nims.0.dvbs.advanced.sat.3380.usals=False
config.Nims.0.dvbs.advanced.sat.3450.lnb=1
config.Nims.0.dvbs.advanced.sat.3450.rotorposition=15
config.Nims.0.dvbs.advanced.sat.3450.usals=False
config.Nims.0.dvbs.advanced.sat.3460.lnb=1
config.Nims.0.dvbs.advanced.sat.3460.rotorposition=14
config.Nims.0.dvbs.advanced.sat.3460.usals=False
config.Nims.0.dvbs.advanced.sat.3520.lnb=1
config.Nims.0.dvbs.advanced.sat.3520.rotorposition=8
config.Nims.0.dvbs.advanced.sat.3520.usals=False
config.Nims.0.dvbs.advanced.sat.3530.lnb=1
config.Nims.0.dvbs.advanced.sat.3530.rotorposition=8
config.Nims.0.dvbs.advanced.sat.3530.usals=False
config.Nims.0.dvbs.advanced.sat.3550.lnb=1
config.Nims.0.dvbs.advanced.sat.3550.rotorposition=4
config.Nims.0.dvbs.advanced.sat.3550.usals=False
config.Nims.0.dvbs.advanced.sat.3560.lnb=1
config.Nims.0.dvbs.advanced.sat.3560.rotorposition=4
config.Nims.0.dvbs.advanced.sat.3560.usals=False
config.Nims.0.dvbs.advanced.sat.3592.lnb=1
config.Nims.0.dvbs.advanced.sat.3592.usals=False
config.Nims.0.dvbs.advanced.sats=705
config.Nims.0.dvbs.configMode=advanced
config.Nims.0.lastsatrotorposition=215
config.Nims.1.force_legacy_signal_stats=True
config.Nims.1.multiType=1
config.OpenWebif.webcache.screenshot_refresh_auto=True
config.OpenWebif.webcache.screenshot_refresh_time=3
config.osd.alpha=255
config.osd.dst_height=552
config.osd.dst_left=14
config.osd.dst_top=13
config.osd.dst_width=693
config.osd.language=en_US
config.pep.brightness=133
config.plugins.AJPanel.backupPath=/media/hdd/ajpanel_backup/
config.plugins.AJPanel.customMenuPath=/media/hdd/ajpanel_backup/
config.plugins.AJPanel.FileManagerExit=e
config.plugins.AJPanel.hideIptvServerChannPrefix=True
config.plugins.AJPanel.iptvAddToBouquetRefType=5002
config.plugins.AJPanel.lastCopyMoveDir=/usr/share/enigma2/
config.plugins.autoresolution.delay_switch_mode=0
config.plugins.autoresolution.enable=True
config.plugins.autoresolution.showinfo=False
config.plugins.bitrate.show_in_menu=infobar
config.plugins.bitrate.x=1500
config.plugins.bitrate.y=200
config.plugins.BouquetMakerXtream.catchup_end=0
config.plugins.BouquetMakerXtream.catchup_start=0
config.plugins.BouquetMakerXtream.max_threads=20
config.plugins.CacheFlush.enable=True
config.plugins.CacheFlush.free_default=8192
config.plugins.CacheFlush.scrinfo=False
config.plugins.CacheFlush.sync=True
config.plugins.CacheFlush.timeout=5
config.plugins.chocholousekpicons.0.method=all_inc
config.plugins.chocholousekpicons.1.allowed=True
config.plugins.chocholousekpicons.1.method=all_inc
config.plugins.chocholousekpicons.1.picon_folder=/media/hdd/picon
config.plugins.chocholousekpicons.2.method=all_inc
config.plugins.chocholousekpicons.3.method=all_inc
config.plugins.ciefpimdb.omdb_api_key=1ebd5606
config.plugins.ciefpimdb.tmdb_api_key=3d690564d76609ab396cabdafee16798
config.plugins.CiefpOscamEditor.dvbapi_path=/etc/tuxbox/config/oscam-emu/oscam.dvbapi
config.plugins.ciefptmdb.omdb_api_key=1ebd5606
config.plugins.ciefptmdb.tmdb_api_key=3d690564d76609ab396cabdafee16798
config.plugins.epgimport.wakeup=20:0
config.plugins.epgsearch.numorbpos=0
config.plugins.EStalker.subs=True
config.plugins.EStalker.timeout=20
config.plugins.MetrixWeather.forecast=5
config.plugins.MetrixWeather.icontype=1
config.plugins.MetrixWeather.owm_geocode=19.72975,45.35421
config.plugins.MetrixWeather.weathercity=Kisač
config.plugins.MyMetrixLiteColors.channelselectioncolorServicePseudoRecorded=6A00FF
config.plugins.MyMetrixLiteColors.channelselectionprogress=A4C400
config.plugins.MyMetrixLiteColors.channelselectionprogressborder=008A00
config.plugins.MyMetrixLiteColors.channelselectionservice=D8C100
config.plugins.MyMetrixLiteColors.channelselectionservicedescription=FFFFFF
config.plugins.MyMetrixLiteColors.channelselectionservicedescriptionselected=A4A4A4
config.plugins.MyMetrixLiteColors.epgbackgroundtransparency=0D
config.plugins.MyMetrixLiteColors.epgeventbackgroundtransparency=0D
config.plugins.MyMetrixLiteColors.epgeventdescriptionbackground=000080
config.plugins.MyMetrixLiteColors.epgeventdescriptionbackgroundtransparency=0D
config.plugins.MyMetrixLiteColors.epgeventselectedbackground=000080
config.plugins.MyMetrixLiteColors.epgeventselectedbackgroundtransparency=0D
config.plugins.MyMetrixLiteColors.epgservicebackgroundtransparency=0D
config.plugins.MyMetrixLiteColors.infobaraccent1=70AD11
config.plugins.MyMetrixLiteColors.infobarbackgroundtransparency=0D
config.plugins.MyMetrixLiteColors.infobarfont2=D8C100
config.plugins.MyMetrixLiteColors.infobarprogress=E51400
config.plugins.MyMetrixLiteColors.infobarprogresstransparency=0D
config.plugins.MyMetrixLiteColors.layerabackgroundtransparency=0D
config.plugins.MyMetrixLiteColors.layeraextendedinfo1=A4C400
config.plugins.MyMetrixLiteColors.layeraprogress=000080
config.plugins.MyMetrixLiteColors.layeraprogresstransparency=0D
config.plugins.MyMetrixLiteColors.layeraselectionbackground=000080
config.plugins.MyMetrixLiteColors.layeraselectionbackgroundtransparency=0D
config.plugins.MyMetrixLiteColors.layerbbackground=000080
config.plugins.MyMetrixLiteColors.layerbbackgroundtransparency=0D
config.plugins.MyMetrixLiteColors.layerbprogress=E51400
config.plugins.MyMetrixLiteColors.layerbprogresstransparency=0D
config.plugins.MyMetrixLiteColors.layerbselectionbackgroundtransparency=0D
config.plugins.MyMetrixLiteColors.menubackgroundtransparency=0D
config.plugins.MyMetrixLiteColors.menusymbolbackground=0F0F0F
config.plugins.MyMetrixLiteColors.menusymbolbackgroundtransparency=0D
config.plugins.MyMetrixLiteOther.EHDenabled=1
config.plugins.MyMetrixLiteOther.EHDtested=vuzero4k_|_01
config.plugins.MyMetrixLiteOther.ExtendedinfoStyle=2
config.plugins.MyMetrixLiteOther.showChannelListRunningtext=True
config.plugins.MyMetrixLiteOther.showChannelNumber=False
config.plugins.OAWeather.weatherlocation=('Kisač, Vojvodina, SERBIA', 19.72975, 45.35421)
config.plugins.PermanentClock.enabled=True
config.plugins.PermanentClock.position_x=86
config.plugins.PermanentClock.position_y=4
config.plugins.PermanentClock.show_hide=True
config.plugins.RaedQuickSignal.style=Full5
config.plugins.serviceapp.servicemp3.player=exteplayer3
config.plugins.serviceapp.servicemp3.replace=True
config.plugins.WeatherPlugin.Entry.0.city=Jounieh, Lebanon
config.plugins.WeatherPlugin.Entry.0.weatherlocationcode=wc:LEXX0005
config.plugins.WeatherPlugin.entrycount=1
config.plugins.XKlass.lastplaylist=sa2.560293.xyz
config.plugins.XStreamity.catchupend=0
config.plugins.XStreamity.catchupstart=0
config.plugins.XStreamity.timeout=20
config.plugins.xtraEvent.searchNUMBER=50
config.radio.lastroot=1:7:2:0:0:0:0:0:0:0:FROM BOUQUET "bouquets.radio" ORDER BY bouquet;1:7:0:0:0:0:DDE0000:0:0:0:(satellitePosition == 3550) && (type == 2) || (type == 10)ORDER BY name:(42) 5.0W Eutelsat 5 West B - Services;
config.radio.lastservice=1:0:2:C:3:20FA:DDE0000:0:0:0:
config.softwareupdate.updatelastcheck=1786907746
config.subtitles.pango_subtitle_colors=2
config.subtitles.ttx_subtitle_colors=2
config.timezone.area=Asia
config.timezone.val=Beirut
config.tv.lastroot=1:7:1:0:0:0:0:0:0:0:FROM BOUQUET "bouquets.tv" ORDER BY bouquet;1:7:1:0:0:0:0:0:0:0:FROM BOUQUET "userbouquet.21_5e_eutelsat_21b___services__tv_.tv" ORDER BY bouquet;
config.tv.lastservice=1:0:1:1:1:0:D7AD9E:0:0:0:
config.usage.alternative_number_mode=True
config.usage.boolean_graphic=yes
config.usage.date.compact=%-d %b 
config.usage.date.compressed=%-d%b 
config.usage.date.displayday=%a %-d %b
config.usage.last_movie_played=4097:0:0:0:0:0:0:0:0:0:http%3a//cdn-007.whatsupcams.com/hls/hr_nin.m3u8:Nin plaža pokojnog jajca 70 wx
config.usage.menu_show_numbers=True
config.usage.menu_sort_mode=user
config.usage.menu_sort_weight={'mainmenu': {'submenu': {'setup': {'sort': 10}, 'blackhole_extra': {'sort': 60}, 'plugin_selection': {'sort': 100}, 'timermenu': {'sort': 30}, 'backupscreen': {'sort': 40}, 'information': {'sort': 140}, 'shutdown': {'sort': 150}, 'BouquetMakerXtream': {'sort': 120, 'hidden': 1}, 'egami_boot': {'sort': 20}, 'eliesat_panel_grid': {'sort': 110}, 'XStreamity': {'sort': 130, 'hidden': 1}, 'EStalker': {'sort': 70, 'hidden': 1}, 'multi_quick': {'sort': 90, 'hidden': 1}, 'servicescanupdates_mainmenu': {'sort': 80, 'hidden': 1}, 'simply_sports': {'sort': 50, 'hidden': 1}}}}
config.usage.menuEntryStyle=image
config.usage.plugin_sort_weight={'ciefptmdbsearch v2.4': {'sort': 10}, 'ciefprottentomatoes v1.2': {'sort': 20}, 'ciefpvibes v2.1': {'sort': 30}, 'ciefpvideoplayer v1.4': {'sort': 40}, 'ciefpyoutube v1.4': {'sort': 50}, 'ciefppictureplayer v1.1': {'sort': 60}, 'ciefpsatelliteanalyzer': {'sort': 80}, 'ciefpsatellitesxmleditor v1.2': {'sort': 90}, 'ciefpparabolacz': {'sort': 100}, 'ciefpkingsat': {'sort': 110}, 'ciefpeasysetup v2.1': {'sort': 120}, 'ciefpopendirectories': {'sort': 130}, 'ciefp plugins': {'sort': 140}, 'ciefpsettings panel': {'sort': 150}, 'ciefpiptvbouquets v1.7': {'sort': 160}, 'ciefpe2converter': {'sort': 170}, 'ciefp oscam editor': {'sort': 180}, 'ciefpbouquetupdater v1.4': {'sort': 190}, 'ciefpchannelmanager v1.6': {'sort': 200}, 'ciefpepgshare': {'sort': 210}, 'ciefpmojtvepg': {'sort': 220}, 'ciefpscreengrab': {'sort': 230}, 'ciefpselectsatellite v1.8': {'sort': 240}, 'ciefpsettingsdownloader v1.5': {'sort': 250}, 'ciefpsettingsmotor': {'sort': 260}, 'ciefpsettingsstreamrelay v1.3': {'sort': 270}, 'ciefpsettingst2miabertis': {'sort': 280}, 'ciefpsrtplayer v1.0': {'sort': 290}, 'ciefpsubtitles v1.4': {'sort': 310}, 'ciefptvprogram': {'sort': 320}, 'ciefptvprograma1hr': {'sort': 330}, 'ciefptvprogramsbb': {'sort': 340}, 'ciefptvprogramsk': {'sort': 350}, 'ciefptvtodayde': {'sort': 360}, 'webcame2prenjsf': {'sort': 70}, 'ciefpwhiteliststreamrelay v1.4': {'sort': 370}, 'ajpanel': {'sort': 380}, 'estalker': {'sort': 390}, 'weather plugin': {'sort': 400}, 'astronomy ver. 1.3': {'sort': 410}, 'file commander': {'sort': 420}, 'hdf radio': {'sort': 430}, 'hdf radio player': {'sort': 440}, 'linuxsat panel': {'sort': 450}, 'mymetrixlite': {'sort': 460}, 'openwebif': {'sort': 470}, 'picture player': {'sort': 480}, 'subssupport downloader': {'sort': 490}, 'subssupport dvb player': {'sort': 500}, 'subssupport settings': {'sort': 510}, 'titlovi browser v1.0': {'sort': 300}, 'vavoo': {'sort': 520}, 'virtualkeyboard': {'sort': 520}, 'keyadder': {'sort': 540}, 'xklass': {'sort': 550}, 'xstreamity': {'sort': 560}, 'youtube': {'sort': 570}, 'raedquicksignal setup': {'sort': 580}, 'imdb setup': {'sort': 590}, 'enhanced movie center (setup)': {'sort': 600}, 'media player': {'sort': 610}, 'media scanner': {'sort': 620}, 'programmlisten-updater v1.3': {'sort': 630}, 'youtubetv settings': {'sort': 640}, 'chromiumos': {'sort': 650}, 'ciefpyoutube v1.5': {'sort': 50}, 'ciefpvideoplayer v1.5': {'sort': 50}, 'ciefpyoutube v1.6': {'sort': 50}, 'ciefpyoutube v1.7': {'sort': 50}, 'ciefpyoutube v1.8': {'sort': 50}, 'ciefpvibes v2.2': {'sort': 30}, 'auto dcw key add': {'sort': 530}, 'ciefpyoutube v1.9': {'sort': 40}, 'ciefprottentomatoes v1.3': {'sort': 20}, 'ciefptmdbsearch v2.5': {'sort': 10}}
config.usage.pluginListLayout=0
config.usage.power.was_controlled_shutdown=False
config.usage.serviceinfo_fontsize=0
config.usage.servicelistpreview_mode=True
config.usage.servicename_fontsize=0
config.usage.servicenum_fontsize=0
config.usage.servicetype_icon_mode=0
config.usage.show_genre_info=True
config.usage.show_infobar_dimming_speed=40
config.usage.show_second_infobar=10
config.usage.showdish=off
config.usage.shutdownOK=False
config.usage.swap_snr_on_osd=True
config.usage.timeshift_skipreturntolive=True
config.version=53023
config.volumeControl.volume=26
EOF

sync

# Rebuild oaweather_fav.dat
    python3 - <<EOF
import pickle

data = [(u"${LOCATION}", ${LAT}, ${LON})]

with open("${FAV}", "wb") as f:
    pickle.dump(data, f, protocol=2)
EOF

sync

mv /tmp/file.txt /etc/enigma2/settings

sync

sleep 5

# === Password Setup ===
#######################################
echo -e "root\nroot" | passwd root >/dev/null 2>&1 && log_action "Password set to root" && log_done || log_fail
sleep 3


