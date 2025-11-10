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
    apt-get install -y build-essential git pkg-config devscripts equivs linux-headers-$KVER dkms
fi

SRCDIR=${SRC_NAME}_${PKG_VERSION}
BUILD_DEPS_FILE=${SRC_NAME}-build-deps_${PKG_VERSION}-1_all.deb

cd $ROOTDIR/$SRCDIR

# Install build dependencies
mk-build-deps
apt-get install -y ./$BUILD_DEPS_FILE
rm ${SRC_NAME}-build-deps*

dpkg-buildpackage -uc -us
