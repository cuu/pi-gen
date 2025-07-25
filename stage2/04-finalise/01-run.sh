on_chroot << EOF
  # 禁用 piwiz（首次引导向导）
  rm -f /etc/xdg/autostart/piwiz.desktop
  rm -f /var/lib/raspi-config/firstboot
  rm -f /boot/firstrun.sh
EOF
