#!/bin/sh

# Configuration
#########################################
plugin="vavoo"
rm="vavoo"

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

#check and_remove package old version
#########################################
check_and_remove_package() {
    if [ -d "$plugin_path" ]; then
        echo "> removing package old version please wait..."
        sleep 3

        rm -rf "$plugin_path" > /dev/null 2>&1

        [ -f "/tmp/vavoo.log" ] && rm -f "/tmp/vavoo.log" > /dev/null 2>&1
        [ -f "/tmp/vavookey" ] && rm -f "/tmp/vavookey" > /dev/null 2>&1

        find /tmp -name "*.m3u" -exec rm -f {} \; > /dev/null 2>&1
        find /etc/enigma2 -name "*vavoo*" -exec rm -f {} \; > /dev/null 2>&1
        find /etc/enigma2 -name "*subbouquet.vavoo*" -exec rm -f {} \; > /dev/null 2>&1

        for bouquet_file in /etc/enigma2/bouquets.*; do
            [ -f "$bouquet_file" ] && sed -i '/vavoo/d' "$bouquet_file" > /dev/null 2>&1
        done

        if [ -e "/usr/bin/enigma2" ]; then
            wget -q -O - "http://127.0.0.1/web/servicelistreload?mode=0" > /dev/null 2>&1
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

        exit 1
    fi
}
check_and_remove_package

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