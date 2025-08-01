#!/bin/bash

# Complete HTTPS Setup for Muon Telescope
# This script completes the HTTPS setup and gets the server running

set -e

echo "🚀 Completing HTTPS setup for Muon Telescope..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Step 1: Generate SSL certificate (if not exists)
echo "📝 Step 1: Generating SSL certificate..."
if [ ! -f /etc/ssl/muon-telescope/muon-telescope.crt ]; then
    bash /home/pi/muon-telescope-project/setup/generate_ssl_cert.sh
else
    echo "✅ SSL certificate already exists"
fi

# Step 2: Create systemd service
echo "⚙️ Step 2: Creating systemd service..."
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

# Step 3: Create startup script
echo "🚀 Step 3: Creating startup script..."
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

# Step 4: Reload systemd and enable service
echo "⚙️ Step 4: Enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable muon-telescope-dev.service

# Step 5: Start the service
echo "🚀 Step 5: Starting the service..."
sudo systemctl start muon-telescope-dev.service

# Step 6: Wait a moment and check status
echo "⏳ Waiting for services to start..."
sleep 5

echo "✅ Setup complete!"
echo ""
echo "🌐 Access your application at:"
echo "   - HTTPS: https://127.0.0.1"
echo "   - HTTPS: https://localhost"
echo "   - HTTP (redirects to HTTPS): http://127.0.0.1"
echo ""
echo "📊 Service status:"
sudo systemctl status muon-telescope-dev.service --no-pager
echo ""
echo "🔍 To test:"
echo "   curl -k https://127.0.0.1" 