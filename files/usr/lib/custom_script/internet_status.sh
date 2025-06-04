#!/bin/sh

. /usr/lib/custom_script/logger.sh
. /usr/lib/custom_script/led_control.sh

handle_internet_status() {
    local curl_output
    curl_output=$(curl -s --connect-timeout 5 https://myip.wtf/yaml)
    if [ $? -eq 0 ]; then
        INTERNET_STATUS="online"
        INTERNET_COLOR="green:internet"
        INTERNET_TRIGGER="default-on"

        # Extract public IP values from YAML response
        PUBLIC_IP=$(echo "$curl_output" | grep "YourFuckingIPAddress:" | awk '{print $2}')
        CITY=$(echo "$curl_output" | grep "YourFuckingCity:" | awk '{print $2}')
        COUNTRY=$(echo "$curl_output" | grep "YourFuckingCountry:" | awk '{print $2}')
        ISP=$(echo "$curl_output" | grep "YourFuckingISP:" | awk '{print $2}')

        # Write the public IP information to files
        echo "$PUBLIC_IP" >/tmp/public_ip
        echo "$CITY" >/tmp/public_ip_city
        echo "$COUNTRY" >/tmp/public_ip_country
        echo "$ISP" >/tmp/public_ip_isp
    else
        INTERNET_STATUS="offline"
        INTERNET_COLOR="green:internet"
        INTERNET_TRIGGER="none"
        log "No internet connection detected"
    fi

    # Update the internet LED
    CURRENT_INTERNET_COLOR=$(uci get system.led_wwan.sysfs)
    CURRENT_INTERNET_TRIGGER=$(uci get system.led_wwan.trigger)
    if [ "$CURRENT_INTERNET_COLOR" != "$INTERNET_COLOR" ] || [ "$CURRENT_INTERNET_TRIGGER" != "$INTERNET_TRIGGER" ]; then
        set_led "led_wwan" "$INTERNET_COLOR" "$INTERNET_TRIGGER"
    fi

    # Log status
    INTERNET_LED_STATUS=$(uci get system.led_wwan.sysfs)
    INTERNET_LED_TRIGGER=$(uci get system.led_wwan.trigger)
    log "Current Internet LED status: $INTERNET_LED_STATUS, Trigger: $INTERNET_TRIGGER"
    [ -n "$PUBLIC_IP" ] && log "Public IP: $PUBLIC_IP, City: $CITY, Country: $COUNTRY, ISP: $ISP"
}
