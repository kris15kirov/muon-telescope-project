#!/bin/bash

# Fix CSRF Trusted Origins for Muon Telescope
# This script adds the current IP to Django's CSRF_TRUSTED_ORIGINS

set -e

echo "🔧 Fixing CSRF trusted origins..."

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

# Check if CSRF_TRUSTED_ORIGINS already exists
if 'CSRF_TRUSTED_ORIGINS' not in content:
    # Add CSRF_TRUSTED_ORIGINS after ALLOWED_HOSTS
    pattern = r'(ALLOWED_HOSTS = \[[^\]]+\])'
    replacement = f'\\1\n\nCSRF_TRUSTED_ORIGINS = [\n    \"https://$CURRENT_IP\",\n    \"https://localhost\",\n    \"https://127.0.0.1\",\n]'
    content = re.sub(pattern, replacement, content)
    
    # Write back to file
    with open('muon_telescope/settings.py', 'w') as f:
        f.write(content)
    
    print(f'✅ Added CSRF_TRUSTED_ORIGINS with $CURRENT_IP')
else:
    # Update existing CSRF_TRUSTED_ORIGINS
    pattern = r'CSRF_TRUSTED_ORIGINS = \[([^\]]*)\]'
    if f'\"https://$CURRENT_IP\"' not in content:
        replacement = f'CSRF_TRUSTED_ORIGINS = [\\1, \"https://$CURRENT_IP\"]'
        content = re.sub(pattern, replacement, content)
        
        # Write back to file
        with open('muon_telescope/settings.py', 'w') as f:
            f.write(content)
        
        print(f'✅ Added $CURRENT_IP to existing CSRF_TRUSTED_ORIGINS')
    else:
        print(f'✅ $CURRENT_IP is already in CSRF_TRUSTED_ORIGINS')
"

echo "🔄 Restarting Django service..."
sudo systemctl restart muon-telescope-dev.service

echo "✅ CSRF trusted origins fixed!"
echo "🌐 You can now access your server at: https://$CURRENT_IP"
echo "📝 Login credentials: admin/admin" 