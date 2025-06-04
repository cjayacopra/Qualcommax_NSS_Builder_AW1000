#!/bin/sh

. /usr/lib/custom_script/logger.sh

initialize_led() {
    local led_name=$1
    local color=$2

    # Check if LED configuration exists
    if ! uci get system."$led_name" >/dev/null 2>&1; then
        # Create new LED configuration
        uci set system."$led_name"=led
        
        # Set proper name based on LED type
        case "$led_name" in
            "led_5g")
                uci set system."$led_name".name='5G'
                ;;
            "led_wwan")
                uci set system."$led_name".name='Internet'
                ;;
            "led_wifi")
                uci set system."$led_name".name='WiFi'
                ;;
            *)
                uci set system."$led_name".name="$led_name"
                ;;
        esac

        uci set system."$led_name".sysfs="$color"
        uci set system."$led_name".trigger='default-on'
        uci commit system
        
        # Log the initialization
        log "Initialized new LED: $led_name with name: $(uci get system.$led_name.name)"
    fi
}

set_led() {
    local led_name=$1
    local color=$2
    local trigger=$3

    # Ensure the LED entry exists
    initialize_led "$led_name" "$color"

    # Log previous state
    local prev_color=$(uci get system."$led_name".sysfs)
    local prev_trigger=$(uci get system."$led_name".trigger)
    log "Previous LED state - $led_name: Color=$prev_color, Trigger=$prev_trigger"

    # Set the LED color and trigger
    uci set system."$led_name".sysfs="$color"
    uci set system."$led_name".trigger="$trigger"
    
    # Commit and verify the changes
    uci commit system
    local new_color=$(uci get system."$led_name".sysfs)
    local new_trigger=$(uci get system."$led_name".trigger)
    
    # Restart the LED service to apply changes
    /etc/init.d/led restart

    # Verify hardware state after restart
    if [ -e "/sys/class/leds/$new_color" ]; then
        log "LED hardware path exists: /sys/class/leds/$new_color"
    else
        log "Warning: LED hardware path not found: /sys/class/leds/$new_color"
    fi

    # Log the changes
    log "LED $led_name changed - Color: $prev_color -> $new_color, Trigger: $prev_trigger -> $new_trigger"
}
