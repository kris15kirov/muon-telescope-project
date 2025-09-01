#!/bin/bash

# Deploy monitoring and recovery tools to Raspberry Pi
# This script sets up power monitoring, auto-recovery, and endpoint testing

echo "=== Deploying Monitoring and Recovery Tools ==="

# Check if Pi is reachable
PI_IP=${1:-"[PI_IP]"}  # Default IP, can be overridden
if ! ping -c 1 $PI_IP > /dev/null 2>&1; then
    echo "❌ Raspberry Pi is not reachable at $PI_IP"
    echo "Please ensure the Pi is powered on and connected to the network"
    echo "Usage: $0 [PI_IP_ADDRESS]"
    exit 1
fi

echo "✅ Pi is reachable at $PI_IP, deploying tools..."

# Copy monitoring scripts to Pi
echo "📁 Copying monitoring scripts..."
scp setup/monitor-power.sh pi@$PI_IP:/tmp/
scp setup/auto-recovery.sh pi@$PI_IP:/tmp/
scp setup/test-all-endpoints.sh pi@$PI_IP:/tmp/

# Execute setup commands on Pi
ssh pi@$PI_IP << 'EOF'
    echo "🔧 Setting up monitoring tools..."
    
    # Make scripts executable
    chmod +x /tmp/monitor-power.sh
    chmod +x /tmp/auto-recovery.sh
    chmod +x /tmp/test-all-endpoints.sh
    
    # Move to proper location
    sudo mv /tmp/monitor-power.sh /usr/local/bin/
    sudo mv /tmp/auto-recovery.sh /usr/local/bin/
    sudo mv /tmp/test-all-endpoints.sh /usr/local/bin/
    
    # Create systemd service for power monitoring
    sudo tee /etc/systemd/system/muon-power-monitor.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Muon Telescope Power Monitor
After=network.target

[Service]
Type=simple
User=pi
ExecStart=/usr/local/bin/monitor-power.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    # Create systemd service for auto-recovery
    sudo tee /etc/systemd/system/muon-auto-recovery.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Muon Telescope Auto Recovery
After=network.target

[Service]
Type=simple
User=pi
ExecStart=/usr/local/bin/auto-recovery.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    # Reload systemd and enable services
    sudo systemctl daemon-reload
    sudo systemctl enable muon-power-monitor.service
    sudo systemctl enable muon-auto-recovery.service
    
    # Start monitoring services
    sudo systemctl start muon-power-monitor.service
    sudo systemctl start muon-auto-recovery.service
    
    # Check service status
    echo "📊 Service Status:"
    sudo systemctl status muon-power-monitor.service --no-pager
    sudo systemctl status muon-auto-recovery.service --no-pager
    
    # Install bc for power monitoring (if not already installed)
    sudo apt-get update && sudo apt-get install -y bc
    
    echo "✅ Monitoring tools deployed successfully!"
EOF

echo "🚀 Monitoring deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Wait for Pi to stabilize"
echo "2. Run: ssh pi@$PI_IP 'sudo /usr/local/bin/test-all-endpoints.sh'"
echo "3. Check logs: ssh pi@$PI_IP 'tail -f /var/log/muon-power.log'"
echo "4. Monitor recovery: ssh pi@$PI_IP 'tail -f /var/log/muon-recovery.log'" 