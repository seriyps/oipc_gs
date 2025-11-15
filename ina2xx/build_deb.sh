#!/bin/bash

ROOTDIR=$(pwd)
DEBIAN_CODENAME=bookworm
PKG_VERSION=0.0.0
KERNEL_RELEASE=$PKG_VERSION
SKIP_SETUP=0
SRC_NAME=ina2xx

while [[ $# -gt 0 ]]; do
    case $1 in
        --pkg-version)
            PKG_VERSION=$2
            shift 2
            ;;
        --kernel-release)
            KERNEL_RELEASE=$2
            shift 2
            ;;
        --debian-codename)
            DEBIAN_CODENAME=$2
            shift 2
            ;;
        --skip-setup)
            SKIP_SETUP=1
            shift
            ;;
        -*)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done
set -x

if [ $SKIP_SETUP -lt 1 ]; then
    apt-get install -y build-essential pkg-config devscripts equivs linux-image-radxa-zero3 libssl-dev
fi

SRCDIR=${SRC_NAME}_${PKG_VERSION}

cd $ROOTDIR/$SRCDIR

if [ ! -f linux-source-$PKG_VERSION/.config ]; then
    cp /boot/config-$PKG_VERSION* linux-source-$PKG_VERSION/.config;
    echo "CONFIG_SENSORS_INA2XX=m" >> linux-source-$PKG_VERSION/.config
fi
echo "$KERNEL_RELEASE" > debian/kver

# Install build dependencies
mk-build-deps debian/control
apt-get install -y ./${SRC_NAME}-build-deps_${PKG_VERSION}*.deb
rm ${SRC_NAME}-build-deps*

dpkg-buildpackage -uc -us -b
