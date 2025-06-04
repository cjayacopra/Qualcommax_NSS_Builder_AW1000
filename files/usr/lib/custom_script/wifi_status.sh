#!/bin/sh

. /usr/lib/custom_script/logger.sh
. /usr/lib/custom_script/led_control.sh

handle_wifi_status() {
    local WIFI_UP=0
    for iface in $(iwinfo | grep "ESSID" | cut -d" " -f1); do
        if iwinfo "$iface" info | grep -q "ESSID:.*"; then
            WIFI_UP=1
            break
        fi
    done

    local WIFI_COLOR="green:wifi"
    local WIFI_TRIGGER
    if [ "$WIFI_UP" -eq 1 ]; then
        WIFI_TRIGGER="default-on"
    else
        WIFI_TRIGGER="none"
    fi

    # Update the WiFi LED
    local CURRENT_WIFI_COLOR=$(uci get system.led_wifi.sysfs)
    local CURRENT_WIFI_TRIGGER=$(uci get system.led_wifi.trigger)
    if [ "$CURRENT_WIFI_COLOR" != "$WIFI_COLOR" ] || [ "$CURRENT_WIFI_TRIGGER" != "$WIFI_TRIGGER" ]; then
        set_led "led_wifi" "$WIFI_COLOR" "$WIFI_TRIGGER"
    fi

    # Log status
    local WIFI_STATUS=$(uci get system.led_wifi.sysfs)
    local WIFI_TRIGGER=$(uci get system.led_wifi.trigger)
    log "Current WiFi LED status: $WIFI_STATUS, Trigger: $WIFI_TRIGGER"
}
