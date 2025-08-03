#!/bin/bash

# Switch to Multi-Network Mode
# This script restores multi-network configuration for both home and university WiFi

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

echo "🏠 Switching to Multi-Network Mode"
echo "================================="

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

# Function to configure multi-network WiFi
configure_multi_network() {
    print_status "Configuring multi-network WiFi..."
    
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
    print_status "Creating multi-network WiFi configuration..."
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

# Function to update Django settings for current IP
update_django_settings() {
    print_status "Updating Django settings for current network..."
    
    # Get current IP
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    
    if [ -n "$CURRENT_IP" ]; then
        print_status "Current IP: $CURRENT_IP"
        
        # Update Django settings
        if [ -f "/home/pi/muon-telescope-project/muon_telescope/settings.py" ]; then
            cd /home/pi/muon-telescope-project
            
            # Add current IP to ALLOWED_HOSTS if not already present
            if ! grep -q "$CURRENT_IP" muon_telescope/settings.py; then
                sed -i "s/ALLOWED_HOSTS = \[/ALLOWED_HOSTS = [\"$CURRENT_IP\", /" muon_telescope/settings.py
            fi
            
            # Add current IP to CSRF_TRUSTED_ORIGINS if not already present
            if ! grep -q "$CURRENT_IP" muon_telescope/settings.py; then
                sed -i "s/CSRF_TRUSTED_ORIGINS = \[/CSRF_TRUSTED_ORIGINS = [\"https:\/\/$CURRENT_IP\", /" muon_telescope/settings.py
            fi
            
            print_success "Django settings updated"
        fi
    fi
}

# Function to update Nginx configuration
update_nginx_config() {
    print_status "Updating Nginx configuration..."
    
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    
    if [ -n "$CURRENT_IP" ] && [ -f "/etc/nginx/sites-available/muon-telescope" ]; then
        # Update Nginx server_name to current IP
        sed -i "s/server_name [0-9.]*;/server_name $CURRENT_IP;/" /etc/nginx/sites-available/muon-telescope
        
        # Test and reload Nginx
        nginx -t && systemctl reload nginx
        print_success "Nginx configuration updated"
    fi
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
    /usr/local/bin/update-muon-ip.sh 2>/dev/null || true
    
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
    
    # Configure multi-network WiFi
    configure_multi_network
    
    # Restart networking
    restart_services
    
    # Update application settings
    update_django_settings
    update_nginx_config
    
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
    print_status "The Pi will automatically:"
    echo "- Connect to university WiFi when available"
    echo "- Fall back to home WiFi when university is not available"
    echo "- Update web interface IP automatically"
}

# Run main function
main 