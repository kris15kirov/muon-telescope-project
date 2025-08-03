#!/bin/bash

# Multi-Network Configuration Script for Muon Telescope
# This script configures the Raspberry Pi to work with both home and university WiFi

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🌐 Multi-Network Configuration for Muon Telescope"
echo "================================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script should be run with sudo"
    exit 1
fi

# Function to backup current configuration
backup_config() {
    print_status "Backing up current network configuration..."
    cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.backup.$(date +%Y%m%d_%H%M%S)
    print_success "Configuration backed up"
}

# Function to scan for available networks
scan_networks() {
    print_status "Scanning for available WiFi networks..."
    echo "Available networks:"
    iwlist wlan0 scan | grep -i essid | sed 's/.*ESSID:"\([^"]*\)".*/- \1/' | sort | uniq
    echo ""
}

# Function to configure both networks
configure_networks() {
    print_status "Configuring WiFi for both home and university networks..."
    
    # Get network details
    echo "Please provide the network details:"
    echo ""
    echo "HOME NETWORK:"
    read -p "Home WiFi SSID: " HOME_SSID
    read -s -p "Home WiFi Password: " HOME_PASSWORD
    echo ""
    echo ""
    echo "UNIVERSITY NETWORK:"
    read -p "University WiFi SSID: " UNIVERSITY_SSID
    read -s -p "University WiFi Password: " UNIVERSITY_PASSWORD
    echo ""
    
    if [ -z "$HOME_SSID" ] || [ -z "$UNIVERSITY_SSID" ]; then
        print_error "Both SSIDs are required"
        exit 1
    fi
    
    # Create wpa_supplicant configuration with priority
    print_status "Creating WiFi configuration with priority..."
    cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

# University network (higher priority)
network={
    ssid="$UNIVERSITY_SSID"
    psk="$UNIVERSITY_PASSWORD"
    key_mgmt=WPA-PSK
    scan_ssid=1
    priority=2
}

# Home network (lower priority)
network={
    ssid="$HOME_SSID"
    psk="$HOME_PASSWORD"
    key_mgmt=WPA-PSK
    scan_ssid=1
    priority=1
}
EOF
    
    print_success "Multi-network configuration created"
    print_status "Priority: University network (2) > Home network (1)"
}

# Function to configure dynamic IP handling
configure_dynamic_ip() {
    print_status "Configuring dynamic IP handling..."
    
    # Create a script to update Django settings when IP changes
    cat > /usr/local/bin/update-muon-ip.sh << 'EOF'
#!/bin/bash

# Update Muon Telescope IP configuration
CURRENT_IP=$(hostname -I | awk '{print $1}')
PROJECT_DIR="/home/pi/muon-telescope-project"

if [ -n "$CURRENT_IP" ] && [ -d "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR"
    
    # Update Django settings
    if ! grep -q "$CURRENT_IP" muon_telescope/settings.py; then
        sed -i "s/ALLOWED_HOSTS = \[/ALLOWED_HOSTS = [\"$CURRENT_IP\", /" muon_telescope/settings.py
        sed -i "s/CSRF_TRUSTED_ORIGINS = \[/CSRF_TRUSTED_ORIGINS = [\"https:\/\/$CURRENT_IP\", /" muon_telescope/settings.py
    fi
    
    # Update Nginx configuration
    if [ -f "/etc/nginx/sites-available/muon-telescope" ]; then
        sed -i "s/server_name [0-9.]*;/server_name $CURRENT_IP;/" /etc/nginx/sites-available/muon-telescope
        nginx -t && systemctl reload nginx
    fi
    
    # Restart Django service
    systemctl restart muon-telescope-dev.service
    
    echo "Updated Muon Telescope for IP: $CURRENT_IP"
fi
EOF
    
    chmod +x /usr/local/bin/update-muon-ip.sh
    
    # Create systemd service to run on network changes
    cat > /etc/systemd/system/muon-ip-update.service << EOF
[Unit]
Description=Update Muon Telescope IP Configuration
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update-muon-ip.sh
User=root

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable muon-ip-update.service
    print_success "Dynamic IP handling configured"
}

# Function to create network status monitoring
create_network_monitor() {
    print_status "Creating network status monitoring..."
    
    cat > /usr/local/bin/muon-network-status.sh << 'EOF'
#!/bin/bash

# Muon Telescope Network Status Monitor
CURRENT_IP=$(hostname -I | awk '{print $1}')
CONNECTED_SSID=$(iwconfig wlan0 2>/dev/null | grep ESSID | sed 's/.*ESSID:"\([^"]*\)".*/\1/')

echo "🌐 Muon Telescope Network Status"
echo "================================"
echo "Current IP: $CURRENT_IP"
echo "Connected to: $CONNECTED_SSID"
echo ""

# Test connectivity
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ Internet: OK"
else
    echo "❌ Internet: FAILED"
fi

# Test web interface
if curl -k -s -o /dev/null -w "%{http_code}" https://$CURRENT_IP/api/health/ 2>/dev/null | grep -q "200"; then
    echo "✅ Web Interface: ACCESSIBLE"
    echo "   URL: https://$CURRENT_IP/control/"
else
    echo "❌ Web Interface: NOT ACCESSIBLE"
fi

echo ""
echo "🔧 Quick Commands:"
echo "  Check network: sudo ./setup/check_network_status.sh"
echo "  Restart services: sudo systemctl restart muon-telescope-dev.service nginx"
echo "  View logs: sudo journalctl -u muon-telescope-dev.service -f"
EOF
    
    chmod +x /usr/local/bin/muon-network-status.sh
    
    # Create alias for easy access
    echo "alias muon-status='/usr/local/bin/muon-network-status.sh'" >> /home/pi/.bashrc
    
    print_success "Network monitoring configured"
}

# Function to restart services
restart_services() {
    print_status "Restarting network and application services..."
    
    # Restart networking
    systemctl restart wpa_supplicant
    systemctl restart dhcpcd
    
    # Wait for network to stabilize
    sleep 15
    
    # Update IP configuration
    /usr/local/bin/update-muon-ip.sh
    
    # Restart application services
    systemctl restart muon-telescope-dev.service
    systemctl restart nginx
    
    print_success "Services restarted"
}

# Function to test connectivity
test_connectivity() {
    print_status "Testing connectivity..."
    
    # Wait a bit for network to stabilize
    sleep 5
    
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    CONNECTED_SSID=$(iwconfig wlan0 2>/dev/null | grep ESSID | sed 's/.*ESSID:"\([^"]*\)".*/\1/')
    
    print_status "Current IP: $CURRENT_IP"
    print_status "Connected to: $CONNECTED_SSID"
    
    # Test internet connectivity
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        print_success "Internet connectivity: OK"
    else
        print_warning "Internet connectivity: FAILED"
    fi
    
    # Test local network
    if ping -c 1 $CURRENT_IP > /dev/null 2>&1; then
        print_success "Local network: OK"
    else
        print_warning "Local network: FAILED"
    fi
    
    # Test web interface
    if curl -k -s -o /dev/null -w "%{http_code}" https://$CURRENT_IP/api/health/ 2>/dev/null | grep -q "200"; then
        print_success "Web interface: ACCESSIBLE"
    else
        print_warning "Web interface: NOT ACCESSIBLE"
    fi
}

# Main execution
main() {
    print_status "Starting multi-network configuration..."
    
    # Backup current config
    backup_config
    
    # Scan for networks
    scan_networks
    
    # Configure networks
    configure_networks
    
    # Configure dynamic IP handling
    configure_dynamic_ip
    
    # Create network monitoring
    create_network_monitor
    
    # Restart services
    restart_services
    
    # Test connectivity
    test_connectivity
    
    echo ""
    print_success "Multi-network configuration completed!"
    echo ""
    print_status "Network Priority:"
    echo "1. University WiFi (priority 2)"
    echo "2. Home WiFi (priority 1)"
    echo ""
    print_status "Access Information:"
    echo "Current IP: $(hostname -I | awk '{print $1}')"
    echo "Web Interface: https://$(hostname -I | awk '{print $1}')/control/"
    echo "Login: admin / admin"
    echo ""
    print_status "Useful Commands:"
    echo "- Check status: muon-status"
    echo "- Network diagnostics: sudo ./setup/check_network_status.sh"
    echo "- Manual IP update: sudo /usr/local/bin/update-muon-ip.sh"
    echo ""
    print_warning "The Pi will automatically:"
    echo "- Connect to university WiFi when available"
    echo "- Fall back to home WiFi when university is not available"
    echo "- Update web interface IP automatically"
}

# Run main function
main 