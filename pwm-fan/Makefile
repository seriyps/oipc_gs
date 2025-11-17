DEB_VER=
DEBIAN_CODENAME=

.PHONY: deb
deb:
	./build_deb.sh --pkg-version $(DEB_VER) --debian-codename $(DEBIAN_CODENAME)

.PHONY: clean
clean:
	sudo rm -rf radxa-zero3-pwm-fan_*.deb
	sudo rm -rf pwm-fan_*.buildinfo
	sudo rm -rf pwm-fan_*.changes
	sudo rm -rf pwm-fan_*.dsc
	sudo rm -rf pwm-fan_*.debian.tar.xz
	sudo rm -rf pwm-fan_*.orig.tar.xz
	sudo rm -rf pwm-fan_*/
