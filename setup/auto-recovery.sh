#!/bin/bash

# Auto-recovery script for Muon Telescope services
# This script checks if services are running and restarts them if needed

LOG_FILE="/var/log/muon-recovery.log"
SERVICES=("muon-telescope-dev.service" "nginx")

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

echo "$(date): Starting auto-recovery monitoring..." | tee -a "$LOG_FILE"

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    restarted_services=()
    
    # Check each service
    for service in "${SERVICES[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            echo "$timestamp: Service $service is down, restarting..." | tee -a "$LOG_FILE"
            
            # Restart the service
            if sudo systemctl restart "$service"; then
                echo "$timestamp: Successfully restarted $service" | tee -a "$LOG_FILE"
                restarted_services+=("$service")
            else
                echo "$timestamp: Failed to restart $service" | tee -a "$LOG_FILE"
            fi
        fi
    done
    
    # Log if any services were restarted
    if [ ${#restarted_services[@]} -gt 0 ]; then
        echo "$timestamp: Restarted services: ${restarted_services[*]}" | tee -a "$LOG_FILE"
    fi
    
    # Sleep for 60 seconds before next check
    sleep 60
done 