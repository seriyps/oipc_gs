OpenIPC Radxa ground station image
==================================

OpenIPC ground station for Rockchip devices (Radxa Zero 3w, Runcam, Emax).

Some principles:
----------------

* Main focus is for non-power end-users, so: - ease of use and setup; quick-start (ideally:
  flash - plug - play)
* The reference board is Radxa Zero 3w with RTL USB WiFi card(s), maybe buttons/5-pos joystick
* OS is Debian (bullseye | bookworm)
* There could be various vendors of the hardware:
  (a) bare Radxa with attached WiFi adapters and buttons
  (b) heavily customized Radxa with extra sensors / clocks / PWM fan etc
  (c) commercial solutions which are also rather heavily customized (would like to see commercial
  solutions with voltage sensors, RTC clocks, PWM fan preinstalled)
* for the (non-power) end-user it's better not to give too much opportunities to tweak the image
  system files: just provide them with one FAT partition on the SD card that will be storing very
  basic optional config file and DVR (DCIM);
    * no SSH should be strictly required
    * There should be easy way to set-up a WiFi (still user would need to figure out the IP that
      router assigned to Radxa though - show it in gsmenu?)
    * OR better: USB tethering (radxa looks like USB network card)
    * OR being able to mount `/config` partition via MTP from USB
* power-users should be able to do some tweaks as well by SSH to the radxa or mouting the EXT4
  rootfs of SD card on Linux
* gsmenu is the main UI, but some WEB interface or openipc configurator are also ok; but
  kilometer-long text config files are not so user-friendly for non-power users

Given that, how this should be achieved:

* since we are using Debian, the official way of distributing the software on Debian is .deb
  packages, ideally coming from DEB repos; so we'd need to package all the software:
  * ✅ pixelpilot
  * ✅ wfb-ng
  * ✅ wifi-drivers (DKMS)
  * ✅ msposd
  * ✅ adaptive-link
  * ❌ extras - like PWM fan, INA226, RTC, wifi-card autodetect, .dts/.dtbo files etc
* create an umbrella-packages like `openipc-gs-base` / `openipc-gs-runcam` / `openipc-gs-full` etc
  which would mainly declare correct dependencies and tweak some of the configs
* publish all those packages as a DEB repository (still not sure if we need 2 debian versions or
  bookworm is enough; having two means our code knows how to handle multiple versions and is
  prepared when new Debian version comes out)
* let vendors propose meta-packages for their hardware (so any vendor can propose and maintain
  their own version of `openipc-gs-runcam` / `openipc-gs-emax` etc).
* those deb packages can be used to build the OS disk images, however the building of the image should
  ideally just end-up in adding our DEB repos and then
  `sudo apt install openipc-gs-<runcam|base|full|emacs>; sudo apt clean` inside official
  Radxa Debian image. Software upgrades can be also performed by `sudo apt upgrade`.
* build and publish multiple OS images for different hardware
* we may consider building our own Debian image from scratch instead of it being based on Radxa image
  and also to try to strip as much of unused software as possible to reduce the size and start-up time
  but this is not the highest priority

Are we there yet?
-----------------

* [x] wfb-ng deb package
* [x] pixelpilot deb package
* [x] wifi-drivers deb package
  * [x] RTL8812AU
  * [x] RTL8812EU
  * [x] RTL8733BU
* [x] msposd deb package
* [x] adaptive-link deb package
* [ ] extras
  * [ ] PWM-fan (either daemon or kernel thermal zones / hwmon)
  * [ ] voltage/current/power sensor INA226
  * [ ] RTC (autonomous clocks)
  * [ ] WiFi card autodetect
  * [ ] Various .dts / .dtbo files (would probably vary depending on the hardware)
* [ ] Debian repository (IN PROGRESS)
* [ ] misc software (WiFi access point; SAMBA; USB MTP; USB Ethernet card)
* [ ] OS image building
* [ ] custom base Debian image (stripped for smaller size and start-up time)

Installed software
------------------

### wfb-ng

Installed from APT repository https://apt.wfb-ng.org/

Deb package: `wfb-ng`.

### Pixelpilot-rk

https://github.com/OpenIPC/PixelPilot_rk/

Deb package: `pixelpilot-rk`

### WiFi drivers

via DKMS

* RTL8812au https://github.com/svpcom/rtl8812au
* RTL8812eu https://github.com/svpcom/rtl8812eu
* RTL8733bu https://github.com/libc0607/rtl8733bu-20240806

Deb packages: `rtl8812au-dkms`, `rtl-8812eu-dkms`, `rtl8733bu-dkms`.

### msposd

https://github.com/OpenIPC/msposd

Deb package: `msposd`

### Adaptive link

https://github.com/OpenIPC/adaptive-link

Deb package: `alink_gs`.

### INA226 overlay

See `ina2xx/`

#### Kernel module build

```
sudo apt install linux-source-5.10 libssl-dev
sudo su
cd /usr/src
tar -xaf linux-source-5.10.tar.xz
cd linux-source-5.10
make oldconfig  OR cp /boot/config-$(uname -r) .config
echo "CONFIG_SENSORS_INA2XX=m" >> .config
make prepare
make modules_prepare
make -j3 M=drivers/hwmon
cp drivers/hwmon/ina2xx.ko /lib/modules/$(uname -r)/kernel/drivers/hwmon/
sudo depmod -a
```

### PWM fan controller script

See `pwm_fan/`

TODO: use hwmon's `pwm-fan` kernel module and thermal zones?
https://emlogic.no/2024/09/step-by-step-thermal-management/

Or use [thermald](https://github.com/intel/thermal_daemon)

Periphery devices
-----------------

It supports several additional periphery devices.

### INA226 battery current and voltage sensor

![ina226](pics/ina226.avif)

https://www.aliexpress.com/item/1005006572888455.html

So one can be sure to not run out of battery for their VRX.

Shunt of 0.1 Ohm (R100) is assumed.

It should be connected to I2C pins 3 (SDA) and 5 (SCL). It uses ina2xx kernel driver.

### PWM-controlled fan

![PWM fan](pics/pwm-fan.avif)

https://www.aliexpress.com/item/1005007513931872.html

Automatically regulates the speed of the fan depending on the CPU temperature.

The PWM wire should be connected to pin 7 PWM14_M0. It relies on Radxa's PWM overlay.

### 5-position joystick (left / right / up / down / push)

![Joystick front](pics/joystick-front.avif)
![Joystick back](pics/joystick-back.avif)

https://www.aliexpress.com/item/1005006140659397.html

Or can be de-soldered from, eg, Caddx analog cameras joystick.

Connected between 3.3v (pin 1) and GPIO pins 11 13 16 18 32.

### DS3231 RTC (autonomous clocks)

https://www.aliexpress.com/item/1005009372357241.html

Connected to the same I2C pins as INA226 sensor: 3 (SDA) and 5 (SCL). Uses kernel driver
[rtc-ds1307](https://github.com/torvalds/linux/blob/master/drivers/rtc/rtc-ds1307.c).


How to add new package
----------------------

Let's say we want to add new software package for `my-app` which is hosted
at `https://github.com/my-user/my-app`.

1. Create a new directory `my-app`.
2. Clone the app repo to `my-app/my-app`
3. Generate the source archive `cd my-app/my-app; git archive v1.2.3 | xz >../my-app_1.2.3.orig.tar.xz`
   It can be created by `dh_make --createorig`, but then the .orig would include `.git` directory,
   so we use `git archive` instead.
3. Initialize the `debian/` folder `cd my-app/; dh_make --packagename my-app_1.2.3 --single -f my-app_1.2.3.orig.tar.xz`
4. Edit the contents of this `debian/` folder; (!!) make sure changelog contains the right version, eg
   `git log --date=format:%Y%m%d --pretty=${MY_APP_DEB_VSN}~git%cd.%h | head -n 1`.
   Use `dch -v $VSN` if needed.
5. Create the `my-app/Makefile` - makefile that should have `deb` and `clean` targets. `deb` will
   be executed from within the Makefile's directory inside a container and should actually build
   the DEB package.
5. Add `do_my-app` function to `build.sh` that will clone the code, copy the `debian` dir into it
   and call `make deb` from inside the container. Add `MY_APP_GIT_VSN` and `MY_APP_DEB_VSN` variables.

How to upgrade package
----------------------

1. Edit the `build.sh` and update `MY_APP_GIT_VSN` and, if necessary, `MY_APP_DEB_VSN`.
2. Checkout this GIT version (tag/branch/commit) and run
   `git log --date=format:%Y%m%d --pretty=${MY_APP_DEB_VSN}~git%cd.%h | head -n 1`
3. In the `my-app/` directory run `dch -v <version>` to add new version to `my-app/debian/changelog`
   and edit the changelog release notes.
