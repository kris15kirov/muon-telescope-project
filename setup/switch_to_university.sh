#!/bin/bash

# Switch to University-Only Mode
# This script removes home WiFi configuration and keeps only university WiFi

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

echo "🏫 Switching to University-Only Mode"
echo "==================================="

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

# Function to check current WiFi configuration
check_current_config() {
    print_status "Checking current WiFi configuration..."
    
    if [ -f "/etc/wpa_supplicant/wpa_supplicant.conf" ]; then
        echo "Current networks configured:"
        grep -A 5 "network={" /etc/wpa_supplicant/wpa_supplicant.conf | grep "ssid" | sed 's/.*ssid="\([^"]*\)".*/- \1/'
        echo ""
    else
        print_error "No WiFi configuration found"
        exit 1
    fi
}

# Function to configure university-only WiFi
configure_university_only() {
    print_status "Configuring university-only WiFi..."
    
    # Get university WiFi details
    echo "Please provide the university WiFi details:"
    read -p "University WiFi SSID: " UNIVERSITY_SSID
    read -s -p "University WiFi Password: " UNIVERSITY_PASSWORD
    echo ""
    
    if [ -z "$UNIVERSITY_SSID" ]; then
        print_error "SSID cannot be empty"
        exit 1
    fi
    
    # Create university-only wpa_supplicant configuration
    print_status "Creating university-only WiFi configuration..."
    cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

# University network only
network={
    ssid="$UNIVERSITY_SSID"
    psk="$UNIVERSITY_PASSWORD"
    key_mgmt=WPA-PSK
    scan_ssid=1
}
EOF
    
    print_success "University-only configuration created"
}

# Function to update Django settings for university IP
update_django_settings() {
    print_status "Updating Django settings for university network..."
    
    # Get current IP
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    
    if [ -n "$CURRENT_IP" ]; then
        print_status "Current IP: $CURRENT_IP"
        
        # Update Django settings
        if [ -f "/home/pi/muon-telescope-project/muon_telescope/settings.py" ]; then
            cd /home/pi/muon-telescope-project
            
            # Remove all IPs from ALLOWED_HOSTS and add current one
            sed -i "s/ALLOWED_HOSTS = \[.*\]/ALLOWED_HOSTS = [\"$CURRENT_IP\", \"127.0.0.1\", \"localhost\"]/" muon_telescope/settings.py
            
            # Remove all IPs from CSRF_TRUSTED_ORIGINS and add current one
            sed -i "s/CSRF_TRUSTED_ORIGINS = \[.*\]/CSRF_TRUSTED_ORIGINS = [\"https:\/\/$CURRENT_IP\", \"https:\/\/localhost\", \"https:\/\/127.0.0.1\"]/" muon_telescope/settings.py
            
            print_success "Django settings updated for university IP"
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

# Function to create restore script
create_restore_script() {
    print_status "Creating restore script for home network..."
    
    cat > /usr/local/bin/restore-home-network.sh << 'EOF'
#!/bin/bash

# Restore Home Network Configuration
echo "🏠 Restoring home network configuration..."

# Check if backup exists
if [ -f "/etc/wpa_supplicant/wpa_supplicant.conf.backup" ]; then
    cp /etc/wpa_supplicant/wpa_supplicant.conf.backup /etc/wpa_supplicant/wpa_supplicant.conf
    systemctl restart wpa_supplicant
    systemctl restart dhcpcd
    echo "✅ Home network configuration restored"
else
    echo "❌ No backup found. Run multi-network setup first."
fi
EOF
    
    chmod +x /usr/local/bin/restore-home-network.sh
    print_success "Restore script created: /usr/local/bin/restore-home-network.sh"
}

# Main execution
main() {
    print_status "Starting university-only configuration..."
    
    # Backup current config
    backup_config
    
    # Check current configuration
    check_current_config
    
    # Configure university-only WiFi
    configure_university_only
    
    # Restart networking
    restart_services
    
    # Update application settings
    update_django_settings
    update_nginx_config
    
    # Create restore script
    create_restore_script
    
    # Test connectivity
    test_connectivity
    
    echo ""
    print_success "University-only configuration completed!"
    echo ""
    print_status "Configuration:"
    echo "- Only university WiFi configured"
    echo "- Home WiFi removed"
    echo "- Django settings updated for university IP"
    echo ""
    print_status "Access Information:"
    echo "Current IP: $(hostname -I | awk '{print $1}')"
    echo "Web Interface: https://$(hostname -I | awk '{print $1}')/control/"
    echo "Login: admin / admin"
    echo ""
    print_status "To restore home network later:"
    echo "sudo /usr/local/bin/restore-home-network.sh"
    echo ""
    print_warning "The Pi will now only connect to university WiFi"
}

# Run main function
main 