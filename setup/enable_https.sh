#!/bin/bash

# HTTPS Enablement Script for Muon Telescope
# This script enables HTTPS for the entire system
# Supports both development and production environments

set -e

echo "🔐 Enabling HTTPS for Muon Telescope..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Detect environment
if [ -f /etc/os-release ] && grep -q "Raspberry Pi" /etc/os-release; then
    ENVIRONMENT="production"
    echo "🏭 Detected production environment (Raspberry Pi)"
else
    ENVIRONMENT="development"
    echo "💻 Detected development environment"
fi

# Step 1: Generate SSL certificate
echo "📝 Step 1: Generating SSL certificate..."
if [ ! -f /etc/ssl/muon-telescope/muon-telescope.crt ]; then
    bash /home/pi/muon-telescope-project/setup/generate_ssl_cert.sh
else
    echo "✅ SSL certificate already exists"
fi

# Step 2: Install and configure Nginx
echo "🌐 Step 2: Installing and configuring Nginx..."
bash /home/pi/muon-telescope-project/setup/install_nginx.sh

# Step 3: Update iptables (only on Raspberry Pi)
if [ "$ENVIRONMENT" = "production" ]; then
    echo "🔒 Step 3: Updating iptables for HTTPS..."
    bash /home/pi/muon-telescope-project/setup/update_iptables_https.sh
else
    echo "⏭️ Skipping iptables update (development environment)"
fi

# Step 4: Update Django settings
echo "⚙️ Step 4: Updating Django settings..."
cd /home/pi/muon-telescope-project

# Set environment-specific settings
if [ "$ENVIRONMENT" = "production" ]; then
    export DJANGO_DEBUG=False
    export DJANGO_SECRET_KEY=$(python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")
else
    export DJANGO_DEBUG=True
    echo "🔧 Using development settings (DEBUG=True)"
fi

# Collect static files
echo "📦 Collecting static files..."
python3 manage.py collectstatic --noinput

# Run migrations
echo "🗄️ Running database migrations..."
python3 manage.py migrate

# Step 5: Create environment-specific startup script
echo "🚀 Step 5: Creating startup script..."
if [ "$ENVIRONMENT" = "production" ]; then
    sudo tee /usr/local/bin/start-muon-telescope-https.sh > /dev/null <<'EOF'
#!/bin/bash

# Start Muon Telescope System with HTTPS (Production)
echo "Starting Muon Telescope System with HTTPS..."

# Setup iptables
/usr/local/bin/setup-captive-portal-https.sh

# Start services
sudo systemctl start hostapd
sudo systemctl start dnsmasq
sudo systemctl start nginx

# Start the Django application
cd /home/pi/muon-telescope-project
source venv/bin/activate
export DJANGO_DEBUG=False
python3 manage.py runserver 127.0.0.1:8000
EOF
else
    sudo tee /usr/local/bin/start-muon-telescope-https.sh > /dev/null <<'EOF'
#!/bin/bash

# Start Muon Telescope System with HTTPS (Development)
echo "Starting Muon Telescope System with HTTPS (Development)..."

# Start Nginx only
sudo systemctl start nginx

# Start the Django application
cd /home/pi/muon-telescope-project
source venv/bin/activate
export DJANGO_DEBUG=True
python3 manage.py runserver 127.0.0.1:8000
EOF
fi

sudo chmod +x /usr/local/bin/start-muon-telescope-https.sh

# Step 6: Update systemd service
echo "⚙️ Step 6: Updating systemd service..."
if [ "$ENVIRONMENT" = "production" ]; then
    sudo tee /etc/systemd/system/muon-telescope-https.service > /dev/null <<EOF
[Unit]
Description=Muon Telescope Control System with HTTPS (Production)
After=network.target hostapd.service dnsmasq.service nginx.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/muon-telescope-project
Environment=DJANGO_DEBUG=False
ExecStart=/usr/local/bin/start-muon-telescope-https.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
else
    sudo tee /etc/systemd/system/muon-telescope-https.service > /dev/null <<EOF
[Unit]
Description=Muon Telescope Control System with HTTPS (Development)
After=network.target nginx.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/muon-telescope-project
Environment=DJANGO_DEBUG=True
ExecStart=/usr/local/bin/start-muon-telescope-https.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
fi

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable muon-telescope-https.service

echo "✅ HTTPS setup complete for $ENVIRONMENT environment!"
echo ""
echo "🌐 Access your application at:"
echo "   - HTTPS: https://192.168.4.1"
echo "   - HTTP (redirects to HTTPS): http://192.168.4.1"
echo ""
echo "⚠️  Important notes:"
echo "   - You'll see a browser warning for self-signed certificate"
echo "   - This is normal for development/testing"
echo "   - For production, use a proper CA-signed certificate"
echo ""
echo "🚀 To start the system:"
echo "   sudo systemctl start muon-telescope-https.service"
echo ""
echo "📊 To check status:"
echo "   sudo systemctl status muon-telescope-https.service" 