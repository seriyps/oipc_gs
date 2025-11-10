DEB_VER=
DEBIAN_CODENAME=

.PHONY: deb
deb:
	./build_deb.sh --pkg-version $(DEB_VER) --debian-codename $(DEBIAN_CODENAME)

.PHONY: clean
clean:
	rm -f python3-adaptive-link-gs_*_all.deb
	rm -f adaptive-link_*.buildinfo
	rm -f adaptive-link_*.changes
	rm -f adaptive-link_*.dsc
	rm -f adaptive-link_*.debian.tar.xz
	rm -f adaptive-link_*.orig.tar.xz
	sudo rm -rf adaptive-link_*/

