#!/bin/sh

# Configuration
#########################################
plugin="oaweatheriet5"
rm="OAWeatheriet5"

plugin_path="/usr/lib/enigma2/python/Plugins/Extensions/$rm"
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

PLUGIN_PATH="/usr/lib/enigma2/python/Plugins/Extensions/OAWeatheriet5"

if [ -x "/etc/init.d/oaweatheriet5" ]; then
    /etc/init.d/oaweatheriet5 stop >/dev/null 2>&1 || true
fi

if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-units 2>/dev/null | grep -q "oaweatheriet5"; then
        systemctl stop oaweatheriet5 >/dev/null 2>&1 || true
        systemctl disable oaweatheriet5 >/dev/null 2>&1 || true
    fi
fi

if [ -d "$PLUGIN_PATH/logs" ]; then
    rm -f "$PLUGIN_PATH/logs/"* >/dev/null 2>&1 || true
fi
find "$PLUGIN_PATH" -name "*.pyo" -exec rm -f {} \; >/dev/null 2>&1 || true
find "$PLUGIN_PATH" -name "*.pyc" -exec rm -f {} \; >/dev/null 2>&1 || true
find "$PLUGIN_PATH" -name "__pycache__" -type d -exec rm -rf {} \; >/dev/null 2>&1 || true

rm -f /tmp/diskcputemp.log >/dev/null 2>&1 || true
rm -f /tmp/oaweatheriet5* >/dev/null 2>&1 || true

sync >/dev/null 2>&1 || true

rm -rf "$plugin_path" >/dev/null 2>&1

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