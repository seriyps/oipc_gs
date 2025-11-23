#!/usr/bin/env bash

rm /etc/resolv.conf
echo nameserver 1.1.1.1 | sudo tee -a /etc/resolv.conf

curl -s https://apt.wfb-ng.org/public.asc | gpg --dearmor --yes -o /usr/share/keyrings/wfb-ng.gpg
echo "deb [signed-by=/usr/share/keyrings/wfb-ng.gpg] https://apt.wfb-ng.org/ $(lsb_release -cs) release-25.01" | tee /etc/apt/sources.list.d/wfb-ng.list


curl -s https://seriyps.github.io/oipc_gs/public.gpg | gpg --dearmor --yes -o /usr/share/keyrings/oipc_gs.gpg
echo "deb [signed-by=/usr/share/keyrings/oipc_gs.gpg] https://seriyps.github.io/oipc_gs/oipc-bookworm bookworm main" | tee /etc/apt/sources.list.d/oipc_gs.list

apt update

apt install -y \
    linux-image-6.1.84-12-rk2410-nocsf \
    linux-headers-6.1.84-12-rk2410-nocsf

# Remove old kernel so we don't have to waste time building dkms for it
apt remove -y --purge \
    linux-image-6.1.84-10-rk2410-nocsf \
    linux-headers-6.1.84-10-rk2410-nocsf

apt install -y \
    python3-adaptive-link-gs \
    msposd \
    pixelpilot-rk \
    rtl8733bu-dkms \
    rtl8812au-dkms \
    rtl8812eu-dkms \
    linux-ina2xx-module \
    radxa-zero3-ina2xx-overlay \
    radxa-zero3-pwm-fan

apt remove -y --purge \
    kde-standard \
    gnome-shell \
    kaddressbook \
    kwin-wayland kwin-wayland \
    plasma-desktop \
    plasma-framework plasma-workspace \
    xserver-xorg \
    xserver-xorg-core \
    chromium-x11 \
    cups \
    cups-common \
    desktop-base \
    firefox-esr \
    'kde-*' \
    kded5 \
    konqueror \
    'kwayland-*' \
    kwin-x11 \
    'libkf5*' \
    'libqt5*' \
    'mysql-*' \
    plasma-workspace \
    plasma-integration \
    breeze \
    'qml-module-*' \
    qtwayland5 \
    xorg-docs-core \
    cloud-utils \
    firmware-amd-graphics \
    gdb-minimal \
    libdjvulibre21 \
    libgphoto2-6 \
    librabbitmq4 \
    wayland-utils \
    vdpau-driver-all \
    x11-utils \
    x11-xserver-utils \
    xauth \
    xdg-desktop-portal
#    hicolor-icon-theme \
#    libopencv-dev \
#    xorg \
#    linux-image-6.1.84-10-rk2410-nocsf  # bookworm only
apt autoremove -y

apt clean
