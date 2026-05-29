#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/ciefpyoutube/ciefpyoutube.sh

# Configuration
#########################################
plugin="ciefpyoutube"
rm="CiefpYouTube"
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
echo "Updating package lists..."
TMP_DIR="/tmp"
CONFIG_DIR="/home/root/.config/yt-dlp"
CONFIG_FILE="$CONFIG_DIR/config"

log() {
	echo "$1"
}

#########################################
# Detect OS
#########################################

if command -v apt-get >/dev/null 2>&1; then
	OSTYPE="DreamOS"
	PKG_INSTALL="apt-get install -y"
	PKG_UPDATE="apt-get update"
else
	OSTYPE="OpenEmbedded"
	PKG_INSTALL="opkg install"
	PKG_UPDATE="opkg update"
fi

#########################################
# Install package helper
#########################################

install_pkg() {
	for pkg in "$@"; do
		if ! opkg list-installed 2>/dev/null | grep -q "^$pkg " && \
		   ! dpkg -l 2>/dev/null | grep -q "$pkg"; then
			
			log "Installing $pkg ..."
			$PKG_INSTALL "$pkg" >/dev/null 2>&1
		else
			log "$pkg already installed"
		fi
	done
}

#########################################
# Install FFmpeg
#########################################

install_ffmpeg() {
	log "Checking FFmpeg ..."
	
	if ! command -v ffmpeg >/dev/null 2>&1; then
		$PKG_UPDATE >/dev/null 2>&1
		install_pkg ffmpeg
	else
		log "FFmpeg already installed"
	fi
}

#########################################
# Install yt-dlp
#########################################

install_ytdlp() {
	log "Installing yt-dlp dependencies ..."
	
	$PKG_UPDATE >/dev/null 2>&1
	
	install_pkg python3-requests python3-core python3-codecs python3-json
	
	if ! command -v yt-dlp >/dev/null 2>&1; then
		
		install_pkg python3-yt-dlp
		
		if ! command -v yt-dlp >/dev/null 2>&1; then
			install_pkg python3-pip
			
			if command -v pip3 >/dev/null 2>&1; then
				pip3 install --upgrade yt-dlp
			fi
		fi
	else
		log "yt-dlp already installed"
	fi
}

#########################################
# Install Node.js
#########################################

install_nodejs() {
	log "Checking Node.js ..."
	
	if ! command -v node >/dev/null 2>&1; then
		$PKG_UPDATE >/dev/null 2>&1
		install_pkg nodejs
	fi
	
	if command -v node >/dev/null 2>&1; then
		log "Node.js installed successfully"
	else
		log "Node.js unavailable, fallback to Deno"
		install_deno
	fi
}

#########################################
# Install Deno fallback
#########################################

install_deno() {

	if command -v deno >/dev/null 2>&1; then
		log "Deno already installed"
		return
	fi

	log "Installing Deno ..."

	ARCH=$(uname -m)

	case "$ARCH" in
		aarch64)
			DENO_URL="https://github.com/denoland/deno/releases/download/v1.40.0/deno-aarch64-unknown-linux-gnu.zip"
			;;
		armv7l|armv7*)
			DENO_URL="https://github.com/denoland/deno/releases/download/v1.40.0/deno-armv7-unknown-linux-gnueabihf.zip"
			;;
		x86_64)
			DENO_URL="https://github.com/denoland/deno/releases/download/v1.40.0/deno-x86_64-unknown-linux-gnu.zip"
			;;
		*)
			log "Unsupported architecture: $ARCH"
			return
			;;
	esac

	cd "$TMP_DIR" || return

	wget -q --no-check-certificate "$DENO_URL" -O deno.zip

	if [ ! -f deno.zip ]; then
		log "Deno download failed"
		return
	fi

	unzip -o deno.zip >/dev/null 2>&1

	chmod +x deno
	cp deno /usr/bin/ 2>/dev/null

	rm -f deno deno.zip

	if command -v deno >/dev/null 2>&1; then
		log "Deno installed successfully"
	else
		log "Deno installation failed"
	fi
}

#########################################
# Install yt-dlp-ejs
#########################################

install_ytdlp_ejs() {

	log "Installing yt-dlp-ejs ..."

	if ! command -v pip3 >/dev/null 2>&1; then
		install_pkg python3-pip
	fi

	if command -v pip3 >/dev/null 2>&1; then
		pip3 install --upgrade yt-dlp-ejs >/dev/null 2>&1
	fi

	if pip3 show yt-dlp-ejs >/dev/null 2>&1; then
		log "yt-dlp-ejs installed successfully"
	else
		log "WARNING: yt-dlp-ejs installation failed"
	fi
}

#########################################
# Create yt-dlp config
#########################################

create_ytdlp_config() {

	log "Creating yt-dlp configuration ..."

	mkdir -p "$CONFIG_DIR"

	cat > "$CONFIG_FILE" << 'EOF'
# Best MP4 video/audio up to 1080p
-f bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080][ext=mp4]/best

# Quiet mode
--no-warnings

# Skip invalid formats
--no-check-formats

# Use GitHub EJS components
--remote-components ejs:github

# Merge output streams
--merge-output-format mp4

# Better stream selection
--format-sort res:1080,codec:av1:mp4
EOF

	if command -v node >/dev/null 2>&1; then
		echo "--js-runtimes node" >> "$CONFIG_FILE"
		log "Configured yt-dlp to use Node.js"

	elif command -v deno >/dev/null 2>&1; then
		echo "--js-runtimes deno" >> "$CONFIG_FILE"
		log "Configured yt-dlp to use Deno"
	fi
}

install_ffmpeg
install_ytdlp
install_nodejs
install_ytdlp_ejs
create_ytdlp_config


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
