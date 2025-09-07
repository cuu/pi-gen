#!/bin/bash -e

install -m 777 files/backlight-governor.service  "${ROOTFS_DIR}/etc/systemd/system/"
install -m 755 files/backlight-governor.sh "${ROOTFS_DIR}/usr/local/bin/"


on_chroot << EOF
  # 禁用 piwiz（首次引导向导）
  rm -f /etc/xdg/autostart/piwiz.desktop
  rm -f /var/lib/raspi-config/firstboot
  rm -f /boot/firstrun.sh


  chmod +x /usr/local/bin/backlight-governor.sh

  systemctl enable backlight-governor.service

EOF
