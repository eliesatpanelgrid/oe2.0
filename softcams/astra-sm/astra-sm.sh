#!/bin/sh

ipk_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/softcams/astra-sm/astra-sm.ipk"

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    PM_UPDATE="apt-get update"
    PM_INSTALL="apt-get install -y"
    CHECK_CMD="apt-cache show astra-sm"
else
    PM_UPDATE="opkg update"
    PM_INSTALL="opkg install"
    CHECK_CMD="opkg list | grep -w astra-sm"
fi

$PM_UPDATE >/dev/null 2>&1

if sh -c "$CHECK_CMD" >/dev/null 2>&1; then
    echo "astra-sm found in feed. Installing..."
    $PM_INSTALL astra-sm >/dev/null 2>&1
else
    echo "astra-sm not found in feed. Installing from IPK..."

    TMP_IPK="/tmp/astra-sm.ipk"
    wget -q --no-check-certificate "$ipk_url" -O "$TMP_IPK"

    if [ -f "$TMP_IPK" ]; then
        if command -v apt-get >/dev/null 2>&1; then
            dpkg -i "$TMP_IPK"
            apt-get -f install -y
        else
            opkg install "$TMP_IPK"
        fi
        rm -f "$TMP_IPK"
    else
        echo "Download failed!"
        exit 1
    fi
fi


arch=$(uname -m)

case "$arch" in
    aarch64)
        targz_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/softcams/astra-sm/astra-sm-aarch.tar.gz"
        ;;
    arm*)
        targz_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/softcams/astra-sm/astra-sm-arm.tar.gz"
        ;;
    mips*)
        targz_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/softcams/astra-sm/astra-sm-mips.tar.gz"
        ;;
    sh4)
        targz_url="https://raw.githubusercontent.com/eliesatpanelgrid/oe2.0/main/softcams/astra-sm/astra-sm-sh4.tar.gz"
        ;;
    *)
        echo "Device not supported: $arch"
        exit 1
        ;;
esac

TMP_TAR="/tmp/astra-sm.tar.gz"
TMP_DIR="/tmp/astra-sm"

wget -q --no-check-certificate "$targz_url" -O "$TMP_TAR"

if [ ! -f "$TMP_TAR" ]; then
    echo "Download failed!"
    exit 1
fi

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

tar -xzf "$TMP_TAR" -C "$TMP_DIR"

if [ $? -ne 0 ]; then
    echo "Extraction failed!"
    rm -f "$TMP_TAR"
    exit 1
fi
cp -r "$TMP_DIR"/* / 2>/dev/null

# Optional: ensure binaries are executable
find "$TMP_DIR" -type f -exec chmod 755 {} \; 2>/dev/null

rm -rf "$TMP_TAR" "$TMP_DIR"

echo "astra-sm installed successfully"
