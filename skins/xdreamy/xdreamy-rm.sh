#!/bin/sh

# Configuration
#########################################
plugin="xdreamy"
rm="xDreamy"

plugin_path="/usr/share/enigma2/$rm"
package="enigma2-plugin-extensions-$plugin"

# Determine package manager
#########################################
if command -v dpkg >/dev/null 2>&1; then
package_manager="apt"
status_file="/var/lib/dpkg/status"
uninstall_command="apt-get purge --auto-remove -y"
else
package_manager="opkg"
status_file="/var/lib/opkg/status"
uninstall_command="opkg remove --force-depends"
fi

# Remove package
#########################################
remove_package() {

if [ -d "$plugin_path" ]; then

echo "> removing package old version please wait..."
sleep 3

rm -rf "$plugin_path" >/dev/null 2>&1

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

if grep -q "$package" "$status_file" 2>/dev/null; then
echo "> Removing existing $package package, please wait..."
$uninstall_command "$package" >/dev/null 2>&1
fi

echo "*******************************************"
echo "*        Removal Completed Successfully   *"
echo "*            Provided by Eliesat          *"
echo "*******************************************"
sleep 3

else

echo "> Plugin not found"
sleep 2

fi

}

remove_package

# Cleanup
#########################################
print_message() {
echo "> [$(date +'%Y-%m-%d')] $1"
}

cleanup() {
[ -d "/CONTROL" ] && rm -rf /CONTROL >/dev/null 2>&1
rm -f /control /postinst /preinst /prerm /postrm 2>/dev/null
rm -f /tmp/*.ipk /tmp/*.tar.gz >/dev/null 2>&1
print_message "> Uploaded By ElieSat"
}

cleanup

exit 0