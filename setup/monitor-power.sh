#!/bin/bash

# Power monitoring script for Raspberry Pi
# This script monitors voltage, temperature, and throttling status

LOG_FILE="/var/log/muon-power.log"
ALERT_FILE="/tmp/power-alert.txt"

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

echo "$(date): Starting power monitoring..." | tee -a "$LOG_FILE"

while true; do
    # Get system metrics
    voltage=$(vcgencmd measure_volts | cut -d'=' -f2 | cut -d'V' -f1)
    temp=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
    throttled=$(vcgencmd get_throttled)
    
    # Get current timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log the metrics
    echo "$timestamp: Voltage=$voltage V, Temp=${temp}°C, Throttled=$throttled" | tee -a "$LOG_FILE"
    
    # Check for low voltage (below 4.8V is concerning)
    if (( $(echo "$voltage < 4.8" | bc -l 2>/dev/null || echo "0") )); then
        echo "$timestamp: WARNING: Low voltage detected: $voltage V" | tee -a "$LOG_FILE"
        echo "$timestamp: WARNING: Low voltage detected: $voltage V" > "$ALERT_FILE"
    fi
    
    # Check for high temperature (above 70°C is concerning)
    if (( $(echo "$temp > 70" | bc -l 2>/dev/null || echo "0") )); then
        echo "$timestamp: WARNING: High temperature detected: ${temp}°C" | tee -a "$LOG_FILE"
        echo "$timestamp: WARNING: High temperature detected: ${temp}°C" >> "$ALERT_FILE"
    fi
    
    # Check throttling status
    if [[ "$throttled" != "0x0" ]]; then
        echo "$timestamp: WARNING: Throttling detected: $throttled" | tee -a "$LOG_FILE"
        echo "$timestamp: WARNING: Throttling detected: $throttled" >> "$ALERT_FILE"
    fi
    
    # Sleep for 30 seconds
    sleep 30
done 