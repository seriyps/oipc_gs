DEB_VER=
DEBIAN_CODENAME=

.PHONY: deb
deb:
	./build_deb.sh --pkg-version $(DEB_VER) --debian-codename $(DEBIAN_CODENAME)

.PHONY: clean
clean:
	sudo rm -rf msposd_*.deb
	sudo rm -rf msposd-dbgsym_*.deb
	sudo rm -rf msposd_*.buildinfo
	sudo rm -rf msposd_*.changes
	sudo rm -rf msposd_*.dsc
	sudo rm -rf msposd_*.debian.tar.xz
	sudo rm -rf msposd_*.orig.tar.xz
	sudo rm -rf msposd_*/
