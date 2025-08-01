#!/bin/bash

# HTTPS Enablement Script for Muon Telescope
# This script enables HTTPS for the entire system

set -e

echo "🔐 Enabling HTTPS for Muon Telescope..."

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

# Step 2: Install and configure Nginx
echo "🌐 Step 2: Installing and configuring Nginx..."
bash /home/pi/muon-telescope-project/setup/install_nginx.sh

# Step 3: Update iptables
echo "🔒 Step 3: Updating iptables for HTTPS..."
bash /home/pi/muon-telescope-project/setup/update_iptables_https.sh

# Step 4: Update Django settings
echo "⚙️ Step 4: Updating Django settings..."
cd /home/pi/muon-telescope-project

# Set production environment
export DJANGO_DEBUG=False
export DJANGO_SECRET_KEY=$(python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")

# Collect static files
echo "📦 Collecting static files..."
python3 manage.py collectstatic --noinput

# Run migrations
echo "🗄️ Running database migrations..."
python3 manage.py migrate

# Step 5: Create updated startup script
echo "🚀 Step 5: Creating updated startup script..."
sudo tee /usr/local/bin/start-muon-telescope-https.sh > /dev/null <<'EOF'
#!/bin/bash

# Start Muon Telescope System with HTTPS
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

sudo chmod +x /usr/local/bin/start-muon-telescope-https.sh

# Step 6: Update systemd service
echo "⚙️ Step 6: Updating systemd service..."
sudo tee /etc/systemd/system/muon-telescope-https.service > /dev/null <<EOF
[Unit]
Description=Muon Telescope Control System with HTTPS
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

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable muon-telescope-https.service

echo "✅ HTTPS setup complete!"
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