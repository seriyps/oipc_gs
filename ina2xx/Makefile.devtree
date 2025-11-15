# or "radxa-zero-3w"
OS_TYPE = raspi-zero-2w

DTS := $(wildcard *.dts)
DTBO := $(patsubst %.dts,%.dtbo,$(DTS))

INSTALL_DTBO := $(OS_TYPE)-ina226-overlay.dtbo

$(DTBO): $(DTS)
	dtc -I dts -O dtb -o $@ $^

all: $(DTBO)

install_raspi-zero-2w:
	install -m644 $(INSTALL_DTBO) /boot/firmware/overlays/ina226-overlay.dtbo

	if [ -z `grep "^dtparam=i2c_arm=on" "/boot/firmware/config.txt"` ] ; then \
		echo "Enable i2c in raspi-config!!"; \
		exit 1; \
	fi

	if [ -z `grep "^dtoverlay=ina226-overlay" "/boot/firmware/config.txt"` ] ; then \
		echo "dtoverlay=ina226-overlay" >> /boot/firmware/config.txt; \
	fi

install_radxa-zero-3w:
	install -m644 $(INSTALL_DTBO) /boot/dtbo/ina226-overlay.dtbo
    # Make sure i2c3 and ina226 overlays are enabled
	rsetup enable_overlays ina226-overlay.dtbo rk3568-i2c3-m0.dtbo $(cd /boot/dtbo/ && ls *.dtbo)

install: install_$(OS_TYPE)
