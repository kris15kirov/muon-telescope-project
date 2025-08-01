#!/bin/bash

# Update ALLOWED_HOSTS with current IP address
# This script automatically adds the current IP to Django's ALLOWED_HOSTS

set -e

echo "🔧 Updating ALLOWED_HOSTS with current IP..."

# Get current IP address
CURRENT_IP=$(hostname -I | awk '{print $1}')

if [ -z "$CURRENT_IP" ]; then
    echo "❌ Could not determine IP address"
    exit 1
fi

echo "📱 Current IP: $CURRENT_IP"

# Navigate to project directory
cd /home/pi/muon-telescope-project

# Create a Python script to update settings
python3 -c "
import os
import re

# Read the settings file
with open('muon_telescope/settings.py', 'r') as f:
    content = f.read()

# Check if IP is already in ALLOWED_HOSTS
if '$CURRENT_IP' not in content:
    # Add IP to ALLOWED_HOSTS
    pattern = r'ALLOWED_HOSTS = \[([^\]]+)\]'
    replacement = f'ALLOWED_HOSTS = [\\1, \"$CURRENT_IP\"]'
    content = re.sub(pattern, replacement, content)
    
    # Write back to file
    with open('muon_telescope/settings.py', 'w') as f:
        f.write(content)
    
    print(f'✅ Added $CURRENT_IP to ALLOWED_HOSTS')
else:
    print(f'✅ $CURRENT_IP is already in ALLOWED_HOSTS')
"

echo "🔄 Restarting Django service..."
sudo systemctl restart muon-telescope-dev.service

echo "✅ ALLOWED_HOSTS updated!"
echo "🌐 You can now access your server at: https://$CURRENT_IP" 