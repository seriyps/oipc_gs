DEB_VER=
DEBIAN_CODENAME=

.PHONY: deb
deb:
	./PixelPilot_rk/tools/container_build.sh \
         --pkg-version $(DEB_VER) --debian-codename $(DEBIAN_CODENAME) \
		 --build-type deb --root-dir $(shell pwd)/PixelPilot_rk
	cp PixelPilot_rk/pixelpilot-rk-dbgsym_$(DEB_VER)*.deb ./
	cp PixelPilot_rk/pixelpilot-rk_$(DEB_VER)*.deb ./
	cp PixelPilot_rk/pixelpilot-rk_$(DEB_VER)*.buildinfo ./
	cp PixelPilot_rk/pixelpilot-rk_$(DEB_VER)*.changes ./
	cp PixelPilot_rk/pixelpilot-rk_$(DEB_VER).orig.tar.gz ./

.PHONY: clean
clean:
	cd PixelPilot_rk && sudo git clean -fdx && cd ..
	rm -f pixelpilot-rk-dbgsym_*.deb
	rm -f pixelpilot-rk_*.deb
	rm -f pixelpilot-rk_*.buildinfo
	rm -f pixelpilot-rk_*.changes
	rm -f pixelpilot-rk_*.orig.tar.gz

