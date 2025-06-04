#!/bin/sh

. /usr/lib/custom_script/logger.sh
. /usr/lib/custom_script/led_control.sh

# Constants for signal thresholds
SIGNAL_EXCELLENT=80
SIGNAL_GOOD=51
SIGNAL_POOR=0

# LED states
LED_NAME="led_signal"
LED_GREEN="signal:green"
LED_BLUE="signal:blue"
LED_RED="signal:red"

calculate_signal_quality() {
    local rssi=$1
    local sinr=$2

    # RSSI typical range: -51 (excellent) to -113 (poor)
    # Normalize RSSI to 0-100 scale
    local rssi_norm=$(( ((rssi + 113) * 100) / (51 + 113) ))
    
    # SINR typical range: -20 to +30
    # Normalize SINR to 0-100 scale
    local sinr_norm=$(( ((sinr + 20) * 100) / 50 ))
    
    # Combined quality score (70% RSSI, 30% SINR)
    local quality=$(( (rssi_norm * 70 + sinr_norm * 30) / 100 ))
    
    # Ensure quality stays within 0-100
    [ $quality -gt 100 ] && quality=100
    [ $quality -lt 0 ] && quality=0
    
    echo $quality
}

set_signal_led() {
    local quality=$1
    local current_color
    local new_color
    local trigger="timer"  # Use timer trigger for PWM effect
    
    # Determine appropriate color based on quality
    if [ $quality -ge $SIGNAL_EXCELLENT ]; then
        new_color=$LED_GREEN
    elif [ $quality -ge $SIGNAL_GOOD ]; then
        new_color=$LED_BLUE
    else
        new_color=$LED_RED
    fi
    
    # Get current LED color
    current_color=$(uci get system.$LED_NAME.sysfs 2>/dev/null)
    
    # Only update if color changed
    if [ "$current_color" != "$new_color" ]; then
        set_led "$LED_NAME" "$new_color" "$trigger"
        
        # Configure PWM parameters based on quality
        # Higher quality = faster blinking
        local delay_on=$((quality * 10))
        local delay_off=$((1000 - delay_on))
        
        # Set PWM timing
        echo $delay_on > "/sys/class/leds/$new_color/delay_on"
        echo $delay_off > "/sys/class/leds/$new_color/delay_off"
        
        log "Signal LED updated - Quality: $quality%, Color: $new_color, PWM: on=${delay_on}ms off=${delay_off}ms"
    fi
}

handle_signal_status() {
    # Extract signal metrics from modem output
    local modem_output="$1"
    
    # Parse QENG response for RSSI and SINR
    local rssi=$(echo "$modem_output" | grep -o 'QENG:.*' | awk -F',' '{print $(NF-5)}')
    local sinr=$(echo "$modem_output" | grep -o 'QENG:.*' | awk -F',' '{print $(NF-4)}')
    
    if [ -n "$rssi" ] && [ -n "$sinr" ]; then
        local quality=$(calculate_signal_quality "$rssi" "$sinr")
        set_signal_led "$quality"
        log "Signal metrics - RSSI: ${rssi}dBm, SINR: ${sinr}dB, Quality: ${quality}%"
    else
        log "Warning: Could not parse signal metrics from modem output"
        set_signal_led 0  # Set to poorest quality when metrics unavailable
    fi
}
