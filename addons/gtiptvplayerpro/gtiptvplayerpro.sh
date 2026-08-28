#!/bin/sh
#https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/addons/gtiptvplayerpro/gtiptvplayerpro.sh

# Configuration
#########################################
plugin="gtiptvplayerpro"
rm="GTIPTVPlayerPro"
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

set -eu
PLUGIN_DIR='/usr/lib/enigma2/python/Plugins/Extensions/GTIPTVPlayerPro'
ACTION=${1:-remove}
case "$ACTION" in
  remove|purge)
    if [ -d "$PLUGIN_DIR" ] && [ ! -L "$PLUGIN_DIR" ]; then
      find "$PLUGIN_DIR" -type f \( -name '*.py' -o -name '*.pyc' -o -name '*.pyo' -o -iname '*lab_bridge*' \) -delete
      rm -f "$PLUGIN_DIR/release-manifest.json"
      rm -rf "$PLUGIN_DIR/_gt_variants" "$PLUGIN_DIR/.gt-installing"
      find "$PLUGIN_DIR" -depth -type d -empty -delete
    fi
    ;;
esac

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

set -eu
PYTHON=/usr/bin/python3
if [ ! -x "$PYTHON" ]; then
  exit 1
fi
if ! IDENTITY=$("$PYTHON" -c 'import importlib.util,sys;print("cp{}{}:{}".format(sys.version_info[0],sys.version_info[1],importlib.util.MAGIC_NUMBER.hex()))'); then
  exit 1
fi
case "$IDENTITY" in
  "cp39:610d0d0a") : ;;
  "cp310:6f0d0d0a") : ;;
  "cp311:a70d0d0a") : ;;
  "cp312:cb0d0d0a") : ;;
  "cp313:f30d0d0a") : ;;
  "cp314:2b0e0d0a") : ;;
  *)
    exit 1
    ;;
esac

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
DEPS="enigma2
python3-core"

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

set -eu
PLUGIN_DIR='/usr/lib/enigma2/python/Plugins/Extensions/GTIPTVPlayerPro'
VARIANTS_DIR="$PLUGIN_DIR/_gt_variants"
PYTHON=/usr/bin/python3
VERSION='0.9.64'
if [ ! -d "$PLUGIN_DIR" ] || [ -L "$PLUGIN_DIR" ]; then
  exit 1
fi
if ! IDENTITY=$("$PYTHON" -c 'import importlib.util,sys;print("cp{}{}:{}".format(sys.version_info[0],sys.version_info[1],importlib.util.MAGIC_NUMBER.hex()))'); then
  exit 1
fi
case "$IDENTITY" in
  "cp39:610d0d0a") ABI="${IDENTITY%%:*}"; MAGIC="${IDENTITY#*:}" ;;
  "cp310:6f0d0d0a") ABI="${IDENTITY%%:*}"; MAGIC="${IDENTITY#*:}" ;;
  "cp311:a70d0d0a") ABI="${IDENTITY%%:*}"; MAGIC="${IDENTITY#*:}" ;;
  "cp312:cb0d0d0a") ABI="${IDENTITY%%:*}"; MAGIC="${IDENTITY#*:}" ;;
  "cp313:f30d0d0a") ABI="${IDENTITY%%:*}"; MAGIC="${IDENTITY#*:}" ;;
  "cp314:2b0e0d0a") ABI="${IDENTITY%%:*}"; MAGIC="${IDENTITY#*:}" ;;
  *)
    exit 1
    ;;
esac
SELECTED="$VARIANTS_DIR/$ABI"
"$PYTHON" - "$PLUGIN_DIR" "$SELECTED" "$ABI" "$MAGIC" "$VERSION" <<'PY'
import hashlib
import json
import os
import shutil
import sys
from pathlib import Path, PurePosixPath


def unique_object(pairs):
    value = {}
    for key, item in pairs:
        if key in value:
            raise RuntimeError("duplicate manifest field")
        value[key] = item
    return value


def digest(path):
    value = hashlib.sha256()
    size = 0
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            size += len(chunk)
            value.update(chunk)
    return size, value.hexdigest()


root = Path(sys.argv[1])
selected = Path(sys.argv[2])
abi = sys.argv[3]
magic = sys.argv[4]
version = sys.argv[5]
variants = root / "_gt_variants"
stage = root / ".gt-installing"
if root.is_symlink() or not root.is_dir():
    raise RuntimeError("unsafe plugin root")
if variants.is_symlink() or selected.is_symlink() or not selected.is_dir():
    raise RuntimeError("unsafe bytecode variant")
for path in variants.rglob("*"):
    if path.is_symlink():
        raise RuntimeError("variant contains symlink")
manifest_path = selected / "release-manifest.json"
manifest_payload = manifest_path.read_bytes()
manifest = json.loads(
    manifest_payload.decode("utf-8"), object_pairs_hook=unique_object
)
python_info = manifest.get("python") or {}
if (
    manifest.get("plugin") != "GTIPTVPlayerPro"
    or manifest.get("version") != version
    or manifest.get("protected") is not True
    or manifest.get("source_included") is not False
    or manifest.get("device_lab_bridge_included") is not False
    or python_info.get("abi") != abi
    or python_info.get("magic_hex") != magic
    or python_info.get("optimization") != 2
):
    raise RuntimeError("selected manifest identity does not match")
entries = manifest.get("files")
if not isinstance(entries, list) or not entries:
    raise RuntimeError("selected manifest file list is missing")
expected = {}
for entry in entries:
    if not isinstance(entry, dict) or set(entry) != {"path", "sha256", "size"}:
        raise RuntimeError("selected manifest entry is invalid")
    name = entry.get("path")
    relative = PurePosixPath(name) if isinstance(name, str) else PurePosixPath("/")
    if (
        not name
        or relative.is_absolute()
        or relative.as_posix() != name
        or any(part in ("", ".", "..") for part in relative.parts)
        or name in expected
        or name == "release-manifest.json"
        or name.lower().endswith((".py", ".pyo"))
        or "lab_bridge" in name.lower()
    ):
        raise RuntimeError("selected manifest path is unsafe")
    expected[name] = entry
variant_names = {
    path.relative_to(selected).as_posix()
    for path in selected.rglob("*")
    if path.is_file()
}
expected_bytecode = {name for name in expected if name.lower().endswith(".pyc")}
if variant_names != expected_bytecode | {"release-manifest.json"}:
    raise RuntimeError("selected bytecode file list does not match")
for name, entry in expected.items():
    path = selected / name if name in expected_bytecode else root / name
    if path.is_symlink() or not path.is_file():
        raise RuntimeError("protected payload is missing: " + name)
    size, sha256 = digest(path)
    if size != entry.get("size") or sha256 != entry.get("sha256"):
        raise RuntimeError("protected payload hash does not match: " + name)
    if name in expected_bytecode and path.read_bytes()[:4].hex() != magic:
        raise RuntimeError("protected bytecode magic does not match: " + name)
if stage.exists():
    if stage.is_symlink() or not stage.is_dir():
        raise RuntimeError("unsafe temporary install path")
    shutil.rmtree(str(stage))
stage.mkdir(mode=0o700)
try:
    for name in sorted(expected_bytecode):
        source = selected / name
        target = stage / name
        target.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        shutil.copyfile(str(source), str(target))
    for current, directories, files in os.walk(str(root), topdown=True):
        current_path = Path(current)
        kept = []
        for directory in directories:
            child = current_path / directory
            if child in (variants, stage):
                continue
            if child.is_symlink():
                raise RuntimeError("installed plugin contains symlink")
            kept.append(directory)
        directories[:] = kept
        for filename in files:
            path = current_path / filename
            relative = path.relative_to(root).as_posix()
            lowered = relative.lower()
            if path.is_symlink():
                raise RuntimeError("installed plugin contains symlink")
            if (
                lowered.endswith((".py", ".pyo", ".pyc"))
                or "lab_bridge" in lowered
                or relative == "release-manifest.json"
            ):
                path.unlink()
    for name in sorted(expected_bytecode):
        source = stage / name
        target = root / name
        target.parent.mkdir(mode=0o755, parents=True, exist_ok=True)
        os.replace(str(source), str(target))
    manifest_temporary = stage / "release-manifest.json"
    manifest_temporary.write_bytes(manifest_payload)
    os.replace(str(manifest_temporary), str(root / "release-manifest.json"))
    allowed = set(expected) | {"release-manifest.json"}
    for current, directories, files in os.walk(str(root), topdown=True):
        current_path = Path(current)
        directories[:] = [
            item
            for item in directories
            if current_path / item not in (variants, stage)
        ]
        for filename in files:
            path = current_path / filename
            relative = path.relative_to(root).as_posix()
            if relative not in allowed:
                path.unlink()
    for name, entry in expected.items():
        path = root / name
        size, sha256 = digest(path)
        if size != entry.get("size") or sha256 != entry.get("sha256"):
            raise RuntimeError("installed payload verification failed: " + name)
finally:
    if stage.exists() and not stage.is_symlink():
        shutil.rmtree(str(stage))
if variants.exists():
    shutil.rmtree(str(variants))
PY
sync

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
