#!/bin/bash

PIXELPILOT_GIT_VER="1.3.0"
PIXELPILOT_DEB_VER=$PIXELPILOT_GIT_VER

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

    sudo mkdir -p $MOUNT/usr/src/PixelPilot_rk
    sudo mount --bind $(pwd) $MOUNT/usr/src/PixelPilot_rk

	sudo chroot $MOUNT /usr/src/PixelPilot_rk/tools/container_build.sh \
         --pkg-version $PIXELPILOT_DEB_VER --debian-codename $DEBIAN_CODENAME --build-type deb

    sudo umount $MOUNT/usr/src/PixelPilot_rk
}

# Build PixelPilot package
do_pixelpilot() {
    mount_raw_disk
    build_pixelpilot_deb
    umount_raw_disk
}

#
# RTL8812AU DKMS Driver
#

build_rtl8812au_deb() {
    cd rtl8812au/
    if [ ! -d "rtl8812au" ]; then
        git clone https://github.com/svpcom/rtl8812au.git
    fi
    cd rtl8812au/
    git checkout $RTL8812AU_GIT_VER
    git archive $RTL8812AU_GIT_VER | xz > ../rtl8812au_${RTL8812AU_DEB_VER}.orig.tar.xz
    cd ..
    SRCDIR=rtl8812au_${RTL8812AU_DEB_VER}
    rm -rf $SRCDIR
    mkdir $SRCDIR
    tar -axf rtl8812au_${RTL8812AU_DEB_VER}.orig.tar.xz -C $SRCDIR
    cp -r debian/ $SRCDIR/debian

    sudo mkdir -p $MOUNT/usr/src/rtl8812au
    sudo mount --bind $(pwd) $MOUNT/usr/src/rtl8812au

    sudo chroot $MOUNT /usr/src/rtl8812au/build_deb.sh \
         --pkg-version $RTL8812AU_DEB_VER --debian-codename $DEBIAN_CODENAME

    sudo umount $MOUNT/usr/src/rtl8812au
}

# Build RTL8812AU package
do_rtl8812au() {
    mount_raw_disk
    build_rtl8812au_deb
    umount_raw_disk
}

#
# RTL8812AU DKMS Driver
#

build_rtl8812eu_deb() {
    cd rtl8812eu/
    if [ ! -d "rtl8812eu" ]; then
        git clone https://github.com/svpcom/rtl8812eu.git
    fi
    cd rtl8812eu/
    git checkout $RTL8812EU_GIT_VER
    git archive $RTL8812EU_GIT_VER | xz > ../rtl8812eu_${RTL8812EU_DEB_VER}.orig.tar.xz
    cd ..
    SRCDIR=rtl8812eu_${RTL8812EU_DEB_VER}
    rm -rf $SRCDIR
    mkdir $SRCDIR
    tar -axf rtl8812eu_${RTL8812EU_DEB_VER}.orig.tar.xz -C $SRCDIR
    cp -r debian/ $SRCDIR/debian

    sudo mkdir -p $MOUNT/usr/src/rtl8812eu
    sudo mount --bind $(pwd) $MOUNT/usr/src/rtl8812eu

    sudo chroot $MOUNT /usr/src/rtl8812eu/build_deb.sh \
         --pkg-version $RTL8812EU_DEB_VER --debian-codename $DEBIAN_CODENAME

    sudo umount $MOUNT/usr/src/rtl8812eu
}

# Build RTL8812EU package
do_rtl8812eu() {
    mount_raw_disk
    build_rtl8812eu_deb
    umount_raw_disk
}

#
# RTL8733BU DKMS Driver
#

build_rtl8733bu_deb() {
    cd rtl8733bu/
    if [ ! -d "rtl8733bu-20240806" ]; then
        git clone https://github.com/libc0607/rtl8733bu-20240806.git
    fi
    cd rtl8733bu-20240806/
    git checkout $RTL8733BU_GIT_VER
    git archive $RTL8733BU_GIT_VER | xz > ../rtl8733bu_${RTL8733BU_DEB_VER}.orig.tar.xz
    cd ..
    SRCDIR=rtl8733bu_${RTL8733BU_DEB_VER}
    rm -rf $SRCDIR
    mkdir $SRCDIR
    tar -axf rtl8733bu_${RTL8733BU_DEB_VER}.orig.tar.xz -C $SRCDIR
    cp -r debian/ $SRCDIR/debian

    sudo mkdir -p $MOUNT/usr/src/rtl8733bu
    sudo mount --bind $(pwd) $MOUNT/usr/src/rtl8733bu

    sudo chroot $MOUNT /usr/src/rtl8733bu/build_deb.sh \
         --pkg-version $RTL8733BU_DEB_VER --debian-codename $DEBIAN_CODENAME

    sudo umount $MOUNT/usr/src/rtl8733bu
}

# Build RTL8733BU package
do_rtl8733bu() {
    mount_raw_disk
    build_rtl8733bu_deb
    umount_raw_disk
}

set -x
for arg in "$@"; do
    do_$arg
done
