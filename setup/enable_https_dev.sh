#!/bin/bash

# Development HTTPS Setup Script for Muon Telescope
# This script enables HTTPS for development/testing environments
# Simpler setup without captive portal services

set -e

echo "🔐 Enabling HTTPS for Muon Telescope (Development Mode)..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Step 1: Generate SSL certificate
echo "📝 Step 1: Generating SSL certificate..."
if [ ! -f /etc/ssl/muon-telescope/muon-telescope.crt ]; then
    bash /home/pi/muon-telescope-project/setup/generate_ssl_cert.sh
else
    echo "✅ SSL certificate already exists"
fi

# Step 2: Install and configure Nginx (simplified)
echo "🌐 Step 2: Installing and configuring Nginx..."
sudo apt update
sudo apt install -y nginx

# Stop Nginx to configure it
sudo systemctl stop nginx

# Create simplified Nginx configuration for development
echo "⚙️ Creating development Nginx configuration..."
sudo tee /etc/nginx/sites-available/muon-telescope-dev > /dev/null <<'EOF'
# Muon Telescope Development Nginx Configuration
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name localhost 127.0.0.1;
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name localhost 127.0.0.1;

    # SSL configuration
    ssl_certificate /etc/ssl/muon-telescope/muon-telescope.crt;
    ssl_certificate_key /etc/ssl/muon-telescope/muon-telescope.key;

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
echo "🔗 Enabling Muon Telescope development site..."
sudo ln -sf /etc/nginx/sites-available/muon-telescope-dev /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

# Start Nginx
echo "🚀 Starting Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Step 3: Update Django settings for development
echo "⚙️ Step 3: Updating Django settings..."
cd /home/pi/muon-telescope-project

# Set development environment
export DJANGO_DEBUG=True

# Collect static files
echo "📦 Collecting static files..."
python3 manage.py collectstatic --noinput

# Run migrations
echo "🗄️ Running database migrations..."
python3 manage.py migrate

# Step 4: Create development startup script
echo "🚀 Step 4: Creating development startup script..."
sudo tee /usr/local/bin/start-muon-telescope-dev.sh > /dev/null <<'EOF'
#!/bin/bash

# Start Muon Telescope System with HTTPS (Development)
echo "Starting Muon Telescope System with HTTPS (Development)..."

# Start Nginx
sudo systemctl start nginx

# Start the Django application
cd /home/pi/muon-telescope-project
source venv/bin/activate
export DJANGO_DEBUG=True
python3 manage.py runserver 127.0.0.1:8000
EOF

sudo chmod +x /usr/local/bin/start-muon-telescope-dev.sh

# Step 5: Create development systemd service
echo "⚙️ Step 5: Creating development systemd service..."
sudo tee /etc/systemd/system/muon-telescope-dev.service > /dev/null <<EOF
[Unit]
Description=Muon Telescope Control System with HTTPS (Development)
After=network.target nginx.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/muon-telescope-project
Environment=DJANGO_DEBUG=True
ExecStart=/usr/local/bin/start-muon-telescope-dev.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable muon-telescope-dev.service

echo "✅ Development HTTPS setup complete!"
echo ""
echo "🌐 Access your application at:"
echo "   - HTTPS: https://127.0.0.1"
echo "   - HTTPS: https://localhost"
echo "   - HTTP (redirects to HTTPS): http://127.0.0.1"
echo ""
echo "⚠️  Important notes:"
echo "   - You'll see a browser warning for self-signed certificate"
echo "   - This is normal for development"
echo "   - Click 'Advanced' → 'Proceed to 127.0.0.1 (unsafe)'"
echo ""
echo "🚀 To start the system:"
echo "   sudo systemctl start muon-telescope-dev.service"
echo ""
echo "📊 To check status:"
echo "   sudo systemctl status muon-telescope-dev.service"
echo ""
echo "🔍 To test manually:"
echo "   # Terminal 1: Start Django"
echo "   cd /home/pi/muon-telescope-project"
echo "   source venv/bin/activate"
echo "   python3 manage.py runserver 127.0.0.1:8000"
echo ""
echo "   # Terminal 2: Test HTTPS"
echo "   curl -k https://127.0.0.1" 