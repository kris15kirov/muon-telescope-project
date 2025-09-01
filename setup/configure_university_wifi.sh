#!/bin/bash

# University WiFi Configuration Script for Muon Telescope
# This script configures the Raspberry Pi to connect to university WiFi

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

echo "🏫 University WiFi Configuration for Muon Telescope"
echo "=================================================="

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

# Function to configure university WiFi
configure_university_wifi() {
    print_status "Configuring university WiFi..."
    
    # Get university WiFi details
    echo "Please provide the university WiFi details:"
    read -p "University WiFi SSID: " UNIVERSITY_SSID
    read -s -p "University WiFi Password: " UNIVERSITY_PASSWORD
    echo ""
    
    if [ -z "$UNIVERSITY_SSID" ]; then
        print_error "SSID cannot be empty"
        exit 1
    fi
    
    # Create wpa_supplicant configuration
    print_status "Creating WiFi configuration..."
    cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="$UNIVERSITY_SSID"
    psk="$UNIVERSITY_PASSWORD"
    key_mgmt=WPA-PSK
    scan_ssid=1
}
EOF
    
    print_success "WiFi configuration created"
}

# Function to configure static IP (if needed)
configure_static_ip() {
    print_status "Configuring network settings..."
    
    echo "Do you want to configure a static IP? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        read -p "Static IP address (e.g., 62.44.98.100): " STATIC_IP
        read -p "Gateway (e.g., 62.44.98.3): " GATEWAY
        read -p "DNS servers (e.g., 8.8.8.8,8.8.4.4): " DNS_SERVERS
        
        # Configure dhcpcd for static IP
        cat >> /etc/dhcpcd.conf << EOF

# Static IP configuration for university network
interface wlan0
static ip_address=$STATIC_IP/24
static routers=$GATEWAY
static domain_name_servers=$DNS_SERVERS
EOF
        
        print_success "Static IP configuration added"
    else
        print_status "Using DHCP (automatic IP assignment)"
    fi
}

# Function to update Django settings for new IP
update_django_settings() {
    print_status "Updating Django settings for university network..."
    
    # Get current IP
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    
    if [ -n "$CURRENT_IP" ]; then
        print_status "Current IP: $CURRENT_IP"
        
        # Update Django settings
        if [ -f "/home/pi/muon-telescope-project/muon_telescope/settings.py" ]; then
            cd /home/pi/muon-telescope-project
            
            # Add IP to ALLOWED_HOSTS if not already present
            if ! grep -q "$CURRENT_IP" muon_telescope/settings.py; then
                sed -i "s/ALLOWED_HOSTS = \[/ALLOWED_HOSTS = [\"$CURRENT_IP\", /" muon_telescope/settings.py
            fi
            
            # Add IP to CSRF_TRUSTED_ORIGINS if not already present
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
        # Update Nginx server_name
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
    sleep 10
    
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
    print_status "Current IP: $CURRENT_IP"
    
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
}

# Main execution
main() {
    print_status "Starting university WiFi configuration..."
    
    # Backup current config
    backup_config
    
    # Scan for networks
    scan_networks
    
    # Configure WiFi
    configure_university_wifi
    
    # Configure static IP if needed
    configure_static_ip
    
    # Restart networking
    restart_services
    
    # Update application settings
    update_django_settings
    update_nginx_config
    
    # Test connectivity
    test_connectivity
    
    echo ""
    print_success "University WiFi configuration completed!"
    echo ""
    print_status "Next steps:"
    echo "1. Check if the Pi connected to university WiFi"
    echo "2. Note the new IP address: $(hostname -I | awk '{print $1}')"
    echo "3. Access the web interface at: https://$(hostname -I | awk '{print $1}')/control/"
    echo "4. Login with: admin / admin"
    echo ""
    print_warning "If connection fails, check:"
    echo "- WiFi credentials are correct"
    echo "- University network allows device registration"
    echo "- Run: sudo journalctl -u wpa_supplicant -f"
}

# Run main function
main 