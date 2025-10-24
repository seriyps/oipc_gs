
install:
	install -m644 fan-manager /etc/default/fan-manager
	install -m755 fan-manager.sh /usr/local/bin/fan-manager.sh
	install -m644 fan-manager.service /etc/systemd/system/fan-manager.service
	sudo systemctl daemon-reload
	sudo systemctl enable fan-manager
	sudo systemctl start fan-manager
