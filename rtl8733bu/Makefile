DEB_VER=
DEBIAN_CODENAME=

.PHONY: deb
deb:
	./build_deb.sh --pkg-version $(DEB_VER) --debian-codename $(DEBIAN_CODENAME)

.PHONY: clean
clean:
	sudo rm -rf rtl8733bu-dkms_*.deb
	sudo rm -rf rtl8733bu_*.buildinfo
	sudo rm -rf rtl8733bu_*.changes
	sudo rm -rf rtl8733bu_*.orig.tar.xz
	sudo rm -rf rtl8733bu_*/
