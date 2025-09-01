#!/bin/bash

# Nginx Installation and Configuration Script for Muon Telescope
# This script installs Nginx and configures it as a reverse proxy with HTTPS

set -e

echo "🌐 Installing and configuring Nginx for Muon Telescope..."

# Update package list
sudo apt update

# Install Nginx
echo "📦 Installing Nginx..."
sudo apt install -y nginx

# Stop Nginx to configure it
sudo systemctl stop nginx

# Create Nginx configuration for Muon Telescope
echo "⚙️ Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/muon-telescope > /dev/null <<'EOF'
# Muon Telescope Nginx Configuration
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name _;

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
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        
        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
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

# Enable the site
echo "🔗 Enabling Muon Telescope site..."
sudo ln -sf /etc/nginx/sites-available/muon-telescope /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

# Start Nginx
echo "🚀 Starting Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

echo "✅ Nginx installed and configured successfully!"
echo "🌐 Access your application at: https://[PI_IP]"
echo "⚠️  Note: You'll see a browser warning for self-signed certificate - this is normal for development" 