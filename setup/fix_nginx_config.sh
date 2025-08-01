#!/bin/bash

# Fix Nginx Configuration for Current IP
# This script updates Nginx configuration to work with the actual IP address

set -e

echo "🔧 Fixing Nginx configuration for current IP..."

# Get current IP address
CURRENT_IP=$(hostname -I | awk '{print $1}')

if [ -z "$CURRENT_IP" ]; then
    echo "❌ Could not determine IP address"
    exit 1
fi

echo "📱 Current IP: $CURRENT_IP"

# Stop Nginx
sudo systemctl stop nginx

# Create updated Nginx configuration
echo "⚙️ Creating updated Nginx configuration..."
sudo tee /etc/nginx/sites-available/muon-telescope > /dev/null <<EOF
# Muon Telescope Nginx Configuration
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name $CURRENT_IP localhost 127.0.0.1;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $CURRENT_IP localhost 127.0.0.1;

    # SSL configuration
    ssl_certificate /etc/ssl/muon-telescope/muon-telescope.crt;
    ssl_certificate_key /etc/ssl/muon-telescope/muon-telescope.key;
    ssl_dhparam /etc/ssl/muon-telescope/dhparam.pem;

    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to Django application
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Static files
    location /static/ {
        alias /home/pi/muon-telescope-project/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

# Start Nginx
echo "🚀 Starting Nginx..."
sudo systemctl start nginx

# Restart Django service
echo "🔄 Restarting Django service..."
sudo systemctl restart muon-telescope-dev.service

echo "✅ Nginx configuration fixed!"
echo "🌐 You can now access your server at:"
echo "   - HTTPS: https://$CURRENT_IP"
echo "   - HTTPS: https://localhost"
echo "   - HTTPS: https://127.0.0.1"
echo ""
echo "🔍 Test with:"
echo "   curl -k https://$CURRENT_IP" 