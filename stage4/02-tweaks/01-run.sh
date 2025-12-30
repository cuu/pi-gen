#!/bin/sh -e

	echo -n "Copying Files: "
		cp -r files/usr/* "${ROOTFS_DIR}/usr/"
		cp -r files/etc/* "${ROOTFS_DIR}/etc/"
		echo "Done"


	echo -n "Configuring LightDM Screen Rotation: "
		sed -i '/^#greeter-setup-script=/c\greeter-setup-script=/etc/lightdm/setup.sh' "${ROOTFS_DIR}/etc/lightdm/lightdm.conf"
		echo '#!/bin/sh' >"${ROOTFS_DIR}/etc/lightdm/setup.sh"
		echo 'wlr-randr --output DSI-1 --transform 270' >>"${ROOTFS_DIR}/etc/lightdm/setup.sh"
		echo 'exit 0' >>"${ROOTFS_DIR}/etc/lightdm/setup.sh"
		chmod +x "${ROOTFS_DIR}/etc/lightdm/setup.sh"
		echo "Done"

	echo -n "Setting up LightDM: "
		echo '[greeter]' > "${ROOTFS_DIR}/etc/lightdm/pi-greeter.conf"
		echo 'default-user-image=/usr/share/raspberrypi-artwork/clockworkpi.png' >> "${ROOTFS_DIR}/etc/lightdm/pi-greeter.conf"
		echo 'desktop_bg=#000000' >> "${ROOTFS_DIR}/etc/lightdm/pi-greeter.conf"
		echo 'wallpaper=/usr/share/rpd-wallpaper/RPiSystemBlack.png' >> "${ROOTFS_DIR}/etc/lightdm/pi-greeter.conf"
		echo 'wallpaper_mode=center' >> "${ROOTFS_DIR}/etc/lightdm/pi-greeter.conf"
		echo 'gtk-icon-theme-name=PiXflat' >> "${ROOTFS_DIR}/etc/lightdm/pi-greeter.conf"
		echo 'gtk-font-name=PibotoLt 12' >> "${ROOTFS_DIR}/etc/lightdm/pi-greeter.conf"
		echo "Done"

	
	echo -n "Setting rc.local"
		cp -rf files/rc.local "${ROOTFS_DIR}/etc/rc.local"
