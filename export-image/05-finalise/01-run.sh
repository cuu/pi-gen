#!/bin/bash -e

IMG_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.img"
INFO_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.info"

on_chroot << EOF
if [ -x /etc/init.d/fake-hwclock ]; then
	/etc/init.d/fake-hwclock stop
fi
if hash hardlink 2>/dev/null; then
	hardlink -t /usr/share/doc
fi

apt remove -y tracker tracker-miner-fs tracker-extract

EOF

cat <<EOF >> "${ROOTFS_DIR}/etc/network/interfaces.d/usb0"
allow-hotplug usb0
iface usb0 inet static
    address 192.168.7.2
    netmask 255.255.255.0
    network 192.168.7.0
    broadcast 192.168.7.255
    gateway 192.168.7.1
EOF

if [ -d "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config" ]; then
	chmod 700 "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config"
fi

rm -f "${ROOTFS_DIR}/usr/bin/qemu-arm-static"

if [ "${USE_QEMU}" != "1" ]; then
	if [ -e "${ROOTFS_DIR}/etc/ld.so.preload.disabled" ]; then
		mv "${ROOTFS_DIR}/etc/ld.so.preload.disabled" "${ROOTFS_DIR}/etc/ld.so.preload"
	fi
fi

rm -f "${ROOTFS_DIR}/etc/network/interfaces.dpkg-old"

rm -f "${ROOTFS_DIR}/etc/apt/sources.list~"
rm -f "${ROOTFS_DIR}/etc/apt/trusted.gpg~"

rm -f "${ROOTFS_DIR}/etc/passwd-"
rm -f "${ROOTFS_DIR}/etc/group-"
rm -f "${ROOTFS_DIR}/etc/shadow-"
rm -f "${ROOTFS_DIR}/etc/gshadow-"
rm -f "${ROOTFS_DIR}/etc/subuid-"
rm -f "${ROOTFS_DIR}/etc/subgid-"

rm -f "${ROOTFS_DIR}"/var/cache/debconf/*-old
rm -f "${ROOTFS_DIR}"/var/lib/dpkg/*-old

rm -f "${ROOTFS_DIR}"/usr/share/icons/*/icon-theme.cache

rm -f "${ROOTFS_DIR}/var/lib/dbus/machine-id"

true > "${ROOTFS_DIR}/etc/machine-id"

ln -nsf /proc/mounts "${ROOTFS_DIR}/etc/mtab"

find "${ROOTFS_DIR}/var/log/" -type f -exec cp /dev/null {} \;

rm -f "${ROOTFS_DIR}/root/.vnc/private.key"
rm -f "${ROOTFS_DIR}/etc/vnc/updateid"


d="${ROOTFS_DIR}/home/cpi"
owner_id=$(stat -c '%u' "$d")
mkdir -p "$d/.config"
cp -rf files/user/.* "$d/" || echo "cp failed"
chown -R $owner_id "$d/.config"
chown -R $owner_id "$d/.lexaloffle"

cp -rf files/dphys-swapfile "${ROOTFS_DIR}/etc/" || echo "cp dphys-swapfile failed"

#rm -rf dphys-swapfile "${ROOTFS_DIR}/home/cpi"

cp -rf files/x.pkla "${ROOTFS_DIR}/etc/polkit-1/localauthority/50-local.d/"

cp -rf files/cursors "${ROOTFS_DIR}/usr/share/icons/PiXflat/"

cp -rf files/chromium-browser.desktop  "${ROOTFS_DIR}/usr/share/applications/"


on_chroot << EOF1

rm /home/cpi/dphys-swapfile
rm /home/cpi/x.pkla
rm -rf /home/cpi/cursors
rm -rf /home/cpi/chromium-browser.desktop

sed -i 's/^#\?HandlePowerKey=.*/HandlePowerKey=ignore/' /etc/systemd/logind.conf

systemctl set-default multi-user.target


tee /etc/systemd/system/save_backlight.service <<'EOF'

[Unit]
Description=Run sync_backlight.sh on shutdown
DefaultDependencies=no
Before=shutdown.target reboot.target halt.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/save_backlight.sh
RemainAfterExit=yes

[Install]
WantedBy=shutdown.target reboot.target halt.target

EOF

systemctl daemon-reload

systemctl enable save_backlight.service

tee /etc/systemd/system/sync_backlight.service <<'EOF'

[Unit]
Description=Sync LCD backlight at boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/sync_backlight.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl enable sync_backlight.service

tee /usr/local/bin/sync_backlight.sh <<'EOF'
#!/bin/sh

SYNC_FILE="/usr/local/etc/sync_backlight"
BRIGHTNESS_PATH="/sys/class/backlight/picocalc_lcd_backlight/brightness"

mkdir -p /usr/local/etc

if [ -f "\$SYNC_FILE" ]; then
    VALUE=\$(cat "\$SYNC_FILE")
    echo "\$VALUE" > "\$BRIGHTNESS_PATH"
else

    echo 30 > "\$BRIGHTNESS_PATH"
    echo 30 > "\$SYNC_FILE"
fi
EOF

chmod +x /usr/local/bin/sync_backlight.sh 

tee /usr/local/bin/save_backlight.sh <<'EOF'
#!/bin/sh

SYNC_FILE="/usr/local/etc/sync_backlight"
BRIGHTNESS_PATH="/sys/class/backlight/picocalc_lcd_backlight/actual_brightness"

VALUE=\$(cat "\$BRIGHTNESS_PATH")

echo "\$VALUE" > "\$SYNC_FILE"
EOF

chmod +x /usr/local/bin/save_backlight.sh

tee /usr/local/bin/toggle_dpms.sh <<'EOF'
#!/bin/bash

status=\$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor)

if [ "\$status" = "powersave" ]; then
    xset dpms force on
    sleep 1
    echo "DPMS On"
else
    xset dpms force off
    sleep 1
    echo "DPMS Off"
fi
EOF

chmod +x /usr/local/bin/toggle_dpms.sh

tee /etc/motd <<'EOF'
PicoCalc Zero
Image Version: v1.0 (Build 2025-09-22)

Default Login:
  Username: cpi
  Password: cpi
  SSH is enabled. Please change your password before going online.

Mouse Mode:
  Press [Right SHIFT] to toggle mouse mode.
  In mouse mode:
    Arrow keys move the cursor
    Key [ / ] act as left/right mouse buttons

GUI Mode:
  Run \`startx\` to launch the desktop environment.

Happy Hacking!
clockworkpi.com
EOF

sed -i 's/quiet splash/ /g' /boot/cmdline.txt

EOF1

update_issue "$(basename "${EXPORT_DIR}")"
install -m 644 "${ROOTFS_DIR}/etc/rpi-issue" "${ROOTFS_DIR}/boot/issue.txt"

cp "$ROOTFS_DIR/etc/rpi-issue" "$INFO_FILE"


{
	if [ -f "$ROOTFS_DIR/usr/share/doc/raspberrypi-kernel/changelog.Debian.gz" ]; then
		firmware=$(zgrep "firmware as of" \
			"$ROOTFS_DIR/usr/share/doc/raspberrypi-kernel/changelog.Debian.gz" | \
			head -n1 | sed  -n 's|.* \([^ ]*\)$|\1|p')
		printf "\nFirmware: https://github.com/raspberrypi/firmware/tree/%s\n" "$firmware"

		kernel="$(curl -s -L "https://github.com/raspberrypi/firmware/raw/$firmware/extra/git_hash")"
		printf "Kernel: https://github.com/raspberrypi/linux/tree/%s\n" "$kernel"

		uname="$(curl -s -L "https://github.com/raspberrypi/firmware/raw/$firmware/extra/uname_string7")"
		printf "Uname string: %s\n" "$uname"
	fi

	printf "\nPackages:\n"
	dpkg -l --root "$ROOTFS_DIR"
} >> "$INFO_FILE"

mkdir -p "${DEPLOY_DIR}"

rm -f "${DEPLOY_DIR}/${ARCHIVE_FILENAME}${IMG_SUFFIX}.*"
rm -f "${DEPLOY_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.img"

mv "$INFO_FILE" "$DEPLOY_DIR/"

if [ "${USE_QCOW2}" = "0" ] && [ "${NO_PRERUN_QCOW2}" = "0" ]; then
	ROOT_DEV="$(mount | grep "${ROOTFS_DIR} " | cut -f1 -d' ')"

	unmount "${ROOTFS_DIR}"
	zerofree "${ROOT_DEV}"

	unmount_image "${IMG_FILE}"
else
	unload_qimage
	make_bootable_image "${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.qcow2" "$IMG_FILE"
fi

case "${DEPLOY_COMPRESSION}" in
zip)
	pushd "${STAGE_WORK_DIR}" > /dev/null
	zip -"${COMPRESSION_LEVEL}" \
	"${DEPLOY_DIR}/${ARCHIVE_FILENAME}${IMG_SUFFIX}.zip" "$(basename "${IMG_FILE}")"
	popd > /dev/null
	;;
gz)
	pigz --force -"${COMPRESSION_LEVEL}" "$IMG_FILE" --stdout > \
	"${DEPLOY_DIR}/${ARCHIVE_FILENAME}${IMG_SUFFIX}.img.gz"
	;;
xz)
	xz --compress --force --threads 0 --memlimit-compress=50% -"${COMPRESSION_LEVEL}" \
	--stdout "$IMG_FILE" > "${DEPLOY_DIR}/${ARCHIVE_FILENAME}${IMG_SUFFIX}.img.xz"
	;;
none | *)
	cp "$IMG_FILE" "$DEPLOY_DIR/"
;;
esac
