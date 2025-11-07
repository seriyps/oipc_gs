DEB_VER=
DEBIAN_CODENAME=

.PHONY: deb
deb:
	./build_deb.sh --pkg-version $(DEB_VER) --debian-codename $(DEBIAN_CODENAME)

.PHONY: clean
clean:
	sudo rm -rf rtl8812eu-dkms_*.deb
	sudo rm -rf rtl8812eu_*.buildinfo
	sudo rm -rf rtl8812eu_*.changes
	sudo rm -rf rtl8812eu_*.orig.tar.xz
	sudo rm -rf rtl8812eu_*/
