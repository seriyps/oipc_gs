#!/bin/bash

PIXELPILOT_GIT_VER="406a5b5f13dd2baa710d6ec8bf011f0cbe236932"
PIXELPILOT_DEB_VER="1.3.0"

RTL8812AU_GIT_VER="7bccd51541dd505270d322a7da3b9feccc910393"
RTL8812AU_DEB_VER="5.2.20"

RTL8812EU_GIT_VER="eeeb886319c0284d70074b9c779868b49bda7b35"
RTL8812EU_DEB_VER="5.15.0"

RTL8733BU_GIT_VER="2ec19e154cffbc2abd98d43d59278dffa6e50d49"
RTL8733BU_DEB_VER="5.15.12"

DEBIAN_CODENAME=bookworm
DEBIAN_RELEASE=latest

if [ "$DEBIAN_CODENAME" == "bookworm" ]; then
    DEBIAN_SYSTEM="debian-12-generic-arm64.tar"
elif [ "$DEBIAN_CODENAME" == "bullseye" ]; then
    DEBIAN_SYSTEM="debian-11-generic-arm64.tar"
fi
DEBIAN_HOST=https://cloud.debian.org/images/cloud/$DEBIAN_CODENAME

ROOT=$(pwd)
MOUNT=$ROOT/mountpoint
APT_CACHE=$ROOT/.${DEBIAN_CODENAME}_apt_cache/

#
# Common
#

mk_git_deb_version() {
    echo `git log --date=format:%Y%m%d --pretty=$1~git%cd.%h | head -n 1`
}

# Ensure required dependencies are installed
do_install_dependencies() {
    sudo apt-get update
    sudo apt-get install -y wget tar git qemu-user-static
}

get_debian_image() {
    if [ ! -f "${DEBIAN_SYSTEM}.xz" ]; then
        curl -L ${DEBIAN_HOST}/${DEBIAN_RELEASE}/${DEBIAN_SYSTEM}.xz -o $ROOT/$DEBIAN_SYSTEM.xz
    fi
}

get_raw_disk() {
    get_debian_image
    tar -xf $ROOT/${DEBIAN_SYSTEM}.xz
}

mount_raw_disk() {
    if [ ! -f "disk.raw" ]; then
        get_raw_disk
    fi
    mkdir $MOUNT || true
    sudo mount `sudo losetup -P --show -f disk.raw`p1 $MOUNT
	mkdir $APT_CACHE || true
	sudo mount -o bind $APT_CACHE $MOUNT/var/cache/apt
    sudo rm $MOUNT/etc/resolv.conf
    echo nameserver 1.1.1.1 | sudo tee -a $MOUNT/etc/resolv.conf
}

umount_raw_disk() {
    sudo umount $MOUNT/var/cache/apt
    sudo umount $MOUNT
    sudo losetup --detach `losetup | grep disk.raw | cut -f 1 -d " "`
}

do_mount() {
    mount_raw_disk
}

do_umount() {
    umount_raw_disk
}

do_clean() {
    for app in pixelpilot rtl8812au rtl8812eu rtl8733bu; do
        cd $app/
        make clean
        cd ..
    done
}

#
# PixelPilot
#

build_pixelpilot_deb() {
    cd pixelpilot/
    if [ ! -d "PixelPilot_rk" ]; then
        git clone https://github.com/OpenIPC/PixelPilot_rk.git
    fi
    cd PixelPilot_rk/
    git checkout $PIXELPILOT_GIT_VER
    git submodule update --init
    cd ..

    sudo mkdir -p $MOUNT/usr/src/pixelpilot
    sudo mount --bind $(pwd) $MOUNT/usr/src/pixelpilot

    sudo chroot $MOUNT /usr/bin/make -C /usr/src/pixelpilot -f /usr/src/pixelpilot/Makefile \
         DEB_VER=$PIXELPILOT_DEB_VER DEBIAN_CODENAME=$DEBIAN_CODENAME

    sudo umount $MOUNT/usr/src/PixelPilot_rk
}

# Build PixelPilot package
do_pixelpilot() {
    mount_raw_disk
    build_pixelpilot_deb
    umount_raw_disk
}

#
# DKMS WiFi Drivers
#

build_rtl_dkms_deb() {
    NAME=$1
    GIT_REPOSITORY=$2
    GIT_VER=$3
    DEB_VER_BASE=$4
    cd $NAME/
    if [ ! -d "$NAME" ]; then
        git clone $GIT_REPOSITORY $NAME
    fi
    cd $NAME/
    git checkout $GIT_VER
    DEB_VER=$(mk_git_deb_version $DEB_VER_BASE)
    git archive $GIT_VER | xz > ../${NAME}_${DEB_VER}.orig.tar.xz
    cd ..
    SRCDIR=${NAME}_${DEB_VER}
    rm -rf $SRCDIR
    mkdir $SRCDIR
    tar -axf ${NAME}_${DEB_VER}.orig.tar.xz -C $SRCDIR
    cp -r debian/ $SRCDIR/debian

    sudo mkdir -p $MOUNT/usr/src/${NAME}
    sudo mount --bind $(pwd) $MOUNT/usr/src/${NAME}

    sudo chroot $MOUNT /usr/bin/make -C /usr/src/${NAME} -f /usr/src/${NAME}/Makefile \
         DEB_VER=$DEB_VER DEBIAN_CODENAME=$DEBIAN_CODENAME

    sudo umount $MOUNT/usr/src/${NAME}
}

# Build RTL8812AU package
do_rtl8812au() {
    mount_raw_disk
    build_rtl_dkms_deb rtl8812au https://github.com/svpcom/rtl8812au.git \
        $RTL8812AU_GIT_VER $RTL8812AU_DEB_VER
    umount_raw_disk
}

# Build RTL8812EU package
do_rtl8812eu() {
    mount_raw_disk
    build_rtl_dkms_deb rtl8812eu https://github.com/svpcom/rtl8812eu.git \
        $RTL8812EU_GIT_VER $RTL8812EU_DEB_VER
    umount_raw_disk
}

# Build RTL8733BU package
do_rtl8733bu() {
    mount_raw_disk
    #build_rtl8733bu_deb
    build_rtl_dkms_deb rtl8733bu https://github.com/libc0607/rtl8733bu-20240806.git \
        $RTL8733BU_GIT_VER $RTL8733BU_DEB_VER
    umount_raw_disk
}

set -x
for arg in "$@"; do
    do_$arg
done
