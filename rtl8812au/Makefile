DEB_VER=
DEBIAN_CODENAME=

.PHONY: deb
deb:
	./build_deb.sh --pkg-version $(DEB_VER) --debian-codename $(DEBIAN_CODENAME)

.PHONY: clean
clean:
	sudo rm -rf rtl8812au-dkms_*.deb
	sudo rm -rf rtl8812au_*.buildinfo
	sudo rm -rf rtl8812au_*.changes
	sudo rm -rf rtl8812au_*.dsc
	sudo rm -rf rtl8812au_*.debian.tar.xz
	sudo rm -rf rtl8812au_*.orig.tar.xz
	sudo rm -rf rtl8812au_*/
