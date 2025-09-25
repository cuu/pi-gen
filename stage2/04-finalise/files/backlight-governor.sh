#!/bin/bash

BACKLIGHT="/sys/class/backlight/picocalc_lcd_backlight/actual_brightness"
LAST_STATE=""

while true; do
    if [[ -f "$BACKLIGHT" ]]; then
        BRIGHTNESS=$(cat "$BACKLIGHT")
        if [[ "$BRIGHTNESS" -eq 0 ]]; then
            if [[ "$LAST_STATE" != "powersave" ]]; then
                sudo cpufreq-set -g powersave
                sudo systemctl stop  fbcp-ili9341.service
                LAST_STATE="powersave"
            fi
        else
            if [[ "$LAST_STATE" != "ondemand" ]]; then
                sudo cpufreq-set -g ondemand
                sudo systemctl start  fbcp-ili9341.service
                LAST_STATE="ondemand"
            fi
        fi
    else
        echo "Backlight device not found: $BACKLIGHT"
        exit 1
    fi
    sleep 1
done
