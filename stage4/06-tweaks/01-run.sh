#!/bin/bash -e

on_chroot <<EOF
systemctl set-default multi-user.target
EOF
