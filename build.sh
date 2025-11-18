#!/bin/bash

PIXELPILOT_GIT_VER="406a5b5f13dd2baa710d6ec8bf011f0cbe236932"
PIXELPILOT_DEB_VER="1.3.0"

RTL8812AU_GIT_VER="7bccd51541dd505270d322a7da3b9feccc910393"
RTL8812AU_DEB_VER="5.2.20"

RTL8812EU_GIT_VER="eeeb886319c0284d70074b9c779868b49bda7b35"
RTL8812EU_DEB_VER="5.15.0"

RTL8733BU_GIT_VER="2ec19e154cffbc2abd98d43d59278dffa6e50d49"
RTL8733BU_DEB_VER="5.15.12"

ALINK_GIT_VER="3a831a75cb25df403374fa5104ea494c140695da"
ALINK_DEB_VER="0.63.0"

MSPOSD_GIT_VER="694221a59e4b17fd4324d24337a7bf3293127dcf"
MSPOSD_DEB_VER="1.0.0"

PWM_FAN_DEB_VER="0.0.1"

DEBIAN_CODENAME=bookworm
DEBIAN_RELEASE=latest

# From https://github.com/radxa-build/radxa-zero3/releases/download/rsdk-b1/radxa-zero3_bookworm_kde_b1.output_512.img.xz
BOOKWORM_KERNEL="6.1.84-12"
BOOKWORM_KERNEL_MOD="rk2410-nocsf"
# From https://github.com/radxa-build/radxa-zero3/releases/download/b6/radxa-zero3_debian_bullseye_xfce_b6.img.xz
BULLSEYE_KERNEL="5.10.160-39"
BULLSEYE_KERNEL_MOD="rk356x"
KERNEL_VERSION=

# Private key is stored in GitHub Secrets and imported in CI workflow
# Public key is ./public.gpg
GPG_KEY_ID="7E2CA22D6D61824C"

APPS=("pixelpilot" "rtl8812au" "rtl8812eu" "rtl8733bu" "adaptive_link" "msposd" "ina2xx" "pwm_fan")

############################
# Script logic starts here #
############################

POS_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --debian-codename)
            DEBIAN_CODENAME=$2
            shift 2
            ;;
        --*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            POS_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ "$DEBIAN_CODENAME" == "bookworm" ]; then
    DEBIAN_SYSTEM="debian-12-generic-arm64.tar"
    KERNEL_VERSION=$BOOKWORM_KERNEL
    KERNEL_MOD=$BOOKWORM_KERNEL_MOD
elif [ "$DEBIAN_CODENAME" == "bullseye" ]; then
    DEBIAN_SYSTEM="debian-11-generic-arm64.tar"
    KERNEL_VERSION=$BULLSEYE_KERNEL
    KERNEL_MOD=$BULLSEYE_KERNEL_MOD
fi
DEBIAN_HOST=https://cloud.debian.org/images/cloud/$DEBIAN_CODENAME

ROOT=$(pwd)
MOUNT=$ROOT/mountpoint
APT_CACHE=$ROOT/.${DEBIAN_CODENAME}_apt_cache/

#
# Common
#

APPS_DIRS=()
for app in "${APPS[@]}"; do
    # Replace '_' with '-' and add to the new array
    APPS_DIRS+=("${app//_/-}")
done

mk_git_deb_version() {
    echo `git log --date=format:%Y%m%d --pretty=$1~git%cd.%h | head -n 1`
}

# Ensure required dependencies are installed
do_install_dependencies() {
    sudo apt-get update
    sudo apt-get install -y tar git qemu-user-static gpg aptly
}

get_debian_image() {
    if [ ! -f "${DEBIAN_SYSTEM}.xz" ]; then
        curl -L ${DEBIAN_HOST}/${DEBIAN_RELEASE}/${DEBIAN_SYSTEM}.xz -o $ROOT/$DEBIAN_SYSTEM.xz
    fi
}

get_raw_disk() {
    get_debian_image
    tar -xf $ROOT/${DEBIAN_SYSTEM}.xz
    mv $ROOT/disk.raw $ROOT/$DEBIAN_CODENAME-disk.raw
}

init_raw_disk() {
    mount_raw_disk
    sudo rm $MOUNT/etc/resolv.conf
    echo nameserver 1.1.1.1 | sudo tee -a $MOUNT/etc/resolv.conf
    if [ ! -f $MOUNT/usr/local/bin/init_image.sh ]; then
        sudo cp init_image.sh $MOUNT/usr/local/bin/
        sudo chroot $MOUNT /usr/local/bin/init_image.sh --debian-codename $DEBIAN_CODENAME
    fi
}

mount_raw_disk() {
    if [ ! -f "$DEBIAN_CODENAME-disk.raw" ]; then
        get_raw_disk
    fi
    mkdir $MOUNT || true
    sudo mount `sudo losetup -P --show -f $DEBIAN_CODENAME-disk.raw`p1 $MOUNT
	mkdir $APT_CACHE || true
	sudo mount -o bind $APT_CACHE $MOUNT/var/cache/apt

    sudo mount -t proc /proc $MOUNT/proc
    sudo mount -t sysfs /sys $MOUNT/sys
    sudo mount -o bind /dev $MOUNT/dev
    sudo mount -o bind /run $MOUNT/run
    sudo mount -t devpts devpts $MOUNT/dev/pts
}

umount_raw_disk() {
    sudo umount $MOUNT/var/cache/apt
    sudo umount $MOUNT/dev/pts
    sudo umount $MOUNT/proc
    sudo umount $MOUNT/sys
    sudo umount $MOUNT/dev
    sudo umount $MOUNT/run
    sudo umount $MOUNT
    sudo losetup --detach `losetup | grep $DEBIAN_CODENAME-disk.raw | cut -f 1 -d " "`
}

do_mount() {
    mount_raw_disk
}

do_init_disk() {
    init_raw_disk
}

do_umount() {
    umount_raw_disk
}

do_clean() {
    for app in ${APPS_DIRS[@]}; do
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

    sudo umount $MOUNT/usr/src/pixelpilot
}

# Build PixelPilot package
do_pixelpilot() {
    init_raw_disk
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

    # FIXME: DKMS deb package should not build the module! Only package the source!
    # Should probably patch `debian/rules` to remove the module build step:
    # override_dh_auto_build:
    #     true
    sudo chroot $MOUNT /usr/bin/make -C /usr/src/${NAME} -f /usr/src/${NAME}/Makefile \
         DEB_VER=$DEB_VER DEBIAN_CODENAME=$DEBIAN_CODENAME

    sudo umount $MOUNT/usr/src/${NAME}
}

# Build RTL8812AU package
do_rtl8812au() {
    init_raw_disk
    build_rtl_dkms_deb rtl8812au https://github.com/svpcom/rtl8812au.git \
        $RTL8812AU_GIT_VER $RTL8812AU_DEB_VER
    umount_raw_disk
}

# Build RTL8812EU package
do_rtl8812eu() {
    init_raw_disk
    build_rtl_dkms_deb rtl8812eu https://github.com/svpcom/rtl8812eu.git \
        $RTL8812EU_GIT_VER $RTL8812EU_DEB_VER
    umount_raw_disk
}

# Build RTL8733BU package
do_rtl8733bu() {
    init_raw_disk
    build_rtl_dkms_deb rtl8733bu https://github.com/libc0607/rtl8733bu-20240806.git \
        $RTL8733BU_GIT_VER $RTL8733BU_DEB_VER
    umount_raw_disk
}

#
# Build in-tree kernel modules
#

build_ina2xx_deb() {
    cd ${ROOT}/ina2xx/
    # Unfortunately radxa kernel repos for bookworm and bullseye are structured differently:
    # * bookworm: kernel source is in 'src/' subdirectory as a submodule
    # * bullseye: kernel source is described in https://github.com/radxa-repo/bsp/blob/main/linux/rk356x/fork.conf
    #  and needs to be cloned from https://github.com/radxa/kernel.git from branch linux-5.10-gen-rkr4.1
    # TODO: Maybe this module can be built against mainline kernel?
    if [ ! -d "$ROOT/ina2xx/ina2xx_${KERNEL_VERSION}/linux-source-$KERNEL_VERSION" ]; then
        mkdir -p $ROOT/ina2xx/ina2xx_${KERNEL_VERSION}/linux-source-$KERNEL_VERSION
        if [ "$DEBIAN_CODENAME" == "bookworm" ]; then
            git clone --recurse-submodules --shallow-submodules -b $KERNEL_VERSION https://github.com/radxa-pkg/linux-$KERNEL_MOD.git linux-$DEBIAN_CODENAME
            cd linux-$DEBIAN_CODENAME/src/
        elif [ "$DEBIAN_CODENAME" == "bullseye" ]; then
            git clone --depth 1 -b linux-5.10-gen-rkr4.1 https://github.com/radxa/kernel.git linux-$DEBIAN_CODENAME
            cd linux-$DEBIAN_CODENAME/
        fi
        git archive HEAD | tar -x -C $ROOT/ina2xx/ina2xx_${KERNEL_VERSION}/linux-source-$KERNEL_VERSION
    fi
    cd $ROOT/ina2xx/
    cp -r debian/ ina2xx_${KERNEL_VERSION}/debian
    cp debian.$DEBIAN_CODENAME/* ina2xx_${KERNEL_VERSION}/debian/
    cp radxa-zero-3w-ina226-overlay.dts ina2xx_${KERNEL_VERSION}/
    sudo mkdir -p $MOUNT/usr/src/ina2xx
    sudo mount --bind $(pwd) $MOUNT/usr/src/ina2xx

    sudo chroot $MOUNT /usr/bin/make -C /usr/src/ina2xx -f /usr/src/ina2xx/Makefile \
         DEB_VER=$KERNEL_VERSION KERNEL_RELEASE=$KERNEL_VERSION-$KERNEL_MOD DEBIAN_CODENAME=$DEBIAN_CODENAME

    sudo umount $MOUNT/usr/src/ina2xx
}

do_ina2xx() {
    init_raw_disk
    build_ina2xx_deb
    umount_raw_disk
}

#
# Adaptive Link
#

build_adaptive_link_deb() {
    cd adaptive-link/
    if [ ! -d "adaptive-link" ]; then
        git clone https://github.com/OpenIPC/adaptive-link.git
    fi
    cd adaptive-link/
    git checkout $ALINK_GIT_VER
    DEB_VER=$(mk_git_deb_version $ALINK_DEB_VER)
    git archive $ALINK_GIT_VER | xz > ../adaptive-link_${DEB_VER}.orig.tar.xz
    cd ..
    SRCDIR=adaptive-link_${DEB_VER}
    rm -rf $SRCDIR
    mkdir $SRCDIR
    tar -axf adaptive-link_${DEB_VER}.orig.tar.xz -C $SRCDIR
    cp -r debian/ $SRCDIR/debian
    sudo mkdir -p $MOUNT/usr/src/adaptive-link
    sudo mount --bind $(pwd) $MOUNT/usr/src/adaptive-link

    sudo chroot $MOUNT /usr/bin/make -C /usr/src/adaptive-link -f /usr/src/adaptive-link/Makefile \
         DEB_VER=$DEB_VER DEBIAN_CODENAME=$DEBIAN_CODENAME

    sudo umount $MOUNT/usr/src/adaptive-link
}

# Build Adaptive Link package
do_adaptive_link() {
    init_raw_disk
    build_adaptive_link_deb
    umount_raw_disk
}


#
# MspOsd
#

build_msposd_deb() {
    cd msposd/
    if [ ! -d "msposd" ]; then
        git clone https://github.com/OpenIPC/msposd.git
    fi
    cd msposd/
    git checkout $MSPOSD_GIT_VER
    DEB_VER=$(mk_git_deb_version $MSPOSD_DEB_VER)
    git archive $MSPOSD_GIT_VER | xz > ../msposd_${DEB_VER}.orig.tar.xz
    cd ..
    SRCDIR=msposd_${DEB_VER}
    rm -rf $SRCDIR
    mkdir $SRCDIR
    tar -axf msposd_${DEB_VER}.orig.tar.xz -C $SRCDIR
    cp -r debian/ $SRCDIR/debian
    sudo mkdir -p $MOUNT/usr/src/msposd
    sudo mount --bind $(pwd) $MOUNT/usr/src/msposd
    sudo chroot $MOUNT /usr/bin/make -C /usr/src/msposd -f /usr/src/msposd/Makefile \
         DEB_VER=$DEB_VER DEBIAN_CODENAME=$DEBIAN_CODENAME
    sudo umount $MOUNT/usr/src/msposd
}

# Build MspOsd package
do_msposd() {
    init_raw_disk
    build_msposd_deb
    umount_raw_disk
}

#
# PWM Fan Controller
#

build_pwm_fan_deb() {
    cd pwm-fan/
    ORIG_DIR=pwm-fan-${PWM_FAN_DEB_VER}
    SRCDIR=pwm-fan_${PWM_FAN_DEB_VER}
    tar -caf ${SRCDIR}.orig.tar.xz $ORIG_DIR
    cp -r $ORIG_DIR $SRCDIR
    cp -r debian/ $SRCDIR/debian
    sudo mkdir -p $MOUNT/usr/src/pwm-fan
    sudo mount --bind $(pwd) $MOUNT/usr/src/pwm-fan

    sudo chroot $MOUNT /usr/bin/make -C /usr/src/pwm-fan -f /usr/src/pwm-fan/Makefile \
         DEB_VER=$PWM_FAN_DEB_VER DEBIAN_CODENAME=$DEBIAN_CODENAME

    sudo umount $MOUNT/usr/src/pwm-fan
}

do_pwm_fan() {
    init_raw_disk
    build_pwm_fan_deb
    umount_raw_disk
}

# Build all .deb packages
do_all_deb() {
    for app in ${APPS[@]}; do
        do_$app
        cd $ROOT
    done
}

# Create APT repository with packages, built with commands like 'do_all_deb' or individual package build commands
do_apt_repository() {
    DEB_REPO_ORIGIN="oipc-$DEBIAN_CODENAME"
    aptly publish drop -force-drop "$DEBIAN_CODENAME" "$DEB_REPO_ORIGIN" || true
    aptly repo drop -force "$DEBIAN_CODENAME" || true
    aptly db cleanup

    aptly repo create -distribution="$DEBIAN_CODENAME" -component="main" "$DEBIAN_CODENAME"
    # Add built .deb (binary) and .dsc (source) files to the repository
    for deb in */*.{deb,dsc}; do
        aptly repo add "$DEBIAN_CODENAME" "$deb"
    done
    aptly publish repo -skip-signing -architectures="arm64,all,source" -origin="$DEB_REPO_ORIGIN" -label="$DEB_REPO_ORIGIN" "$DEBIAN_CODENAME" "$DEB_REPO_ORIGIN"
    DISTRO_PATH=~/.aptly/public/$DEB_REPO_ORIGIN/dists/$DEBIAN_CODENAME
    gpg --yes --batch --armor -u $GPG_KEY_ID --clear-sign  -o "$DISTRO_PATH/InRelease"   "$DISTRO_PATH/Release"
    gpg --yes --batch --armor -u $GPG_KEY_ID --detach-sign -o "$DISTRO_PATH/Release.gpg" "$DISTRO_PATH/Release"
}

set -x

for arg in ${POS_ARGS[@]}; do
    do_$arg
    cd $ROOT
done
