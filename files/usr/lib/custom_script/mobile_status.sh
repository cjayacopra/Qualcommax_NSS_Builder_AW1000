#!/bin/sh

. /usr/lib/custom_script/logger.sh
. /usr/lib/custom_script/led_control.sh

handle_mobile_status() {
    local DEVICE="$1"
    
    # Clear previous output
    echo "" > /tmp/network_type.log

    # Use socat instead of picocom for more reliable AT command handling
    # Send both commands in sequence
    (
        sleep 1
        echo -e "AT+QENG=\"servingcell\"\r"
        sleep 1
        echo -e "AT+QNWINFO\r"
        sleep 2
    ) | socat - "$DEVICE,b115200,raw,echo=0" > /tmp/network_type.log

    # Read and clean the output, removing empty lines and terminal control chars
    local OUTPUT=$(cat /tmp/network_type.log | sed 's/\r//g' | grep -v '^$' | grep -v '^OK')
    
    # Log raw output for debugging
    log "Raw modem output: [$OUTPUT]"
    
    # Handle signal quality LED
    handle_signal_status "$OUTPUT"

    # Initialize network type as unknown
    network_type="Unknown"
    MOBILE_COLOR="red:5g"
    MOBILE_TRIGGER="default-on"

    # Check for specific network strings in the output
    if echo "$OUTPUT" | grep -q "+QENG: \"servingcell\""; then
        log "Processing QENG response"
        if echo "$OUTPUT" | grep -q "\"NR5G-SA\""; then
            network_type="NR5G-SA"
            MOBILE_COLOR="green:5g"
            MOBILE_TRIGGER="default-on"
        elif echo "$OUTPUT" | grep -q "\"NR5G-NSA\""; then
            network_type="NR5G-NSA"
            MOBILE_COLOR="green:5g"
            MOBILE_TRIGGER="default-on"
        elif echo "$OUTPUT" | grep -q "\"LTE\".*\"A\"" || echo "$OUTPUT" | grep -q "\"LTE-A\""; then
            network_type="LTE-A"
            MOBILE_COLOR="blue:5g"
            MOBILE_TRIGGER="default-on"
        elif echo "$OUTPUT" | grep -q "\"LTE\""; then
            network_type="LTE"
            MOBILE_COLOR="blue:5g"
            MOBILE_TRIGGER="default-on"
        fi
    fi

    # Fallback to QNWINFO if QENG didn't give us a network type
    if [ "$network_type" = "Unknown" ] && echo "$OUTPUT" | grep -q "+QNWINFO:"; then
        log "Processing QNWINFO response"
        local QNWINFO=$(echo "$OUTPUT" | grep "+QNWINFO:" | cut -d'"' -f2)
        log "QNWINFO network: [$QNWINFO]"
        
        case "$QNWINFO" in
            *"NR5G"*)
                network_type="NR5G-SA"
                MOBILE_COLOR="green:5g"
                MOBILE_TRIGGER="default-on"
                ;;
            *"EN-DC"*)
                network_type="NR5G-NSA"
                MOBILE_COLOR="green:5g"
                MOBILE_TRIGGER="default-on"
                ;;
            *"LTE-A"*|*"LTE+"*)
                network_type="LTE-A"
                MOBILE_COLOR="blue:5g"
                MOBILE_TRIGGER="default-on"
                ;;
            *"LTE"*)
                network_type="LTE"
                MOBILE_COLOR="blue:5g"
                MOBILE_TRIGGER="default-on"
                ;;
        esac
    fi

    # Get current LED state before changing
    local CURRENT_COLOR=$(uci get system.led_5g.sysfs 2>/dev/null)
    local CURRENT_TRIGGER=$(uci get system.led_5g.trigger 2>/dev/null)
    log "Current LED state - Color: $CURRENT_COLOR, Trigger: $CURRENT_TRIGGER"
    
    if [ "$CURRENT_COLOR" != "$MOBILE_COLOR" ]; then
        log "Updating LED - Old Color: $CURRENT_COLOR, New Color: $MOBILE_COLOR"
        set_led "led_5g" "$MOBILE_COLOR" "$MOBILE_TRIGGER"
    fi

    # Log final status
    MOBILE_STATUS=$(uci get system.led_5g.sysfs)
    MOBILE_TRIGGER=$(uci get system.led_5g.trigger)
    log "Current Network type: [$network_type]"
    log "Current 5G LED status: $MOBILE_STATUS, Trigger: $MOBILE_TRIGGER"
}
