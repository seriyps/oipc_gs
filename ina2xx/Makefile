DEB_VER=
DEBIAN_CODENAME=
KERNEL_RELEASE=

.PHONY: deb
deb:
	./build_deb.sh --pkg-version $(DEB_VER) --kernel-release $(KERNEL_RELEASE) --debian-codename $(DEBIAN_CODENAME)

.PHONY: clean
clean:
	sudo rm -f linux-ina2xx-module_*.deb
	sudo rm -f radxa-zero3-ina2xx-overlay_*.deb
	sudo rm -f ina2xx_*.buildinfo
	sudo rm -f ina2xx_*.changes
	sudo rm -rf ina2xx_*/
