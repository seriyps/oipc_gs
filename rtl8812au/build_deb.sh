#!/bin/bash

ROOTDIR=$(pwd)
DEBIAN_CODENAME=bookworm
PKG_VERSION=0.0.0
SKIP_SETUP=0
SRC_NAME=rtl8812au
KVER=`ls /lib/modules | tail -n 1`

while [[ $# -gt 0 ]]; do
    case $1 in
        --pkg-version)
            PKG_VERSION=$2
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


if [ $SKIP_SETUP -lt 1 ]; then
    # needed for GPG tools to work
    if [ ! -e /dev/null ]; then
        mknod /dev/null c 1 3
        chmod 666 /dev/null
    fi

    keyring="${ROOTDIR}/keyring.deb"
    version="$(curl -L https://github.com/radxa-pkg/radxa-archive-keyring/releases/latest/download/VERSION)"
    curl -L --output "$keyring" "https://github.com/radxa-pkg/radxa-archive-keyring/releases/download/${version}/radxa-archive-keyring_${version}_all.deb"
    dpkg -i $keyring
    rm $keyring

    case $DEBIAN_CODENAME in
        bookworm)
            tee /etc/apt/sources.list.d/70-radxa.list <<< "deb [signed-by=/usr/share/keyrings/radxa-archive-keyring.gpg] https://radxa-repo.github.io/bookworm/ bookworm main"
            tee /etc/apt/sources.list.d/80-radxa-rk3566.list <<< "deb [signed-by=/usr/share/keyrings/radxa-archive-keyring.gpg] https://radxa-repo.github.io/rk3566-bookworm rk3566-bookworm main"
            ;;
        bullseye)
            tee /etc/apt/sources.list.d/70-radxa.list <<< "deb [signed-by=/usr/share/keyrings/radxa-archive-keyring.gpg] https://radxa-repo.github.io/bullseye/ bullseye main"
            tee /etc/apt/sources.list.d/80-rockchip.list <<< "deb [signed-by=/usr/share/keyrings/radxa-archive-keyring.gpg] https://radxa-repo.github.io/bullseye rockchip-bullseye main"
            ;;
    esac

    apt-get update
    apt-get install -y cmake build-essential git pkg-config devscripts equivs linux-headers-$KVER dkms
fi

SRCDIR=${SRC_NAME}_${PKG_VERSION}
BUILD_DEPS_FILE=${SRC_NAME}-build-deps_${PKG_VERSION}-1_all.deb

cd $ROOTDIR/$SRCDIR

# Install build dependencies
mk-build-deps
apt-get install -y ./$BUILD_DEPS_FILE
rm ${SRC_NAME}-build-deps*

dpkg-buildpackage -uc -us -b
