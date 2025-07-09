#!/bin/bash

# Muon Telescope Installation Script
# This script automates the installation of the Muon Telescope system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        print_status "Please run as a regular user (pi)"
        exit 1
    fi
}

# Check if we're on a Raspberry Pi
check_raspberry_pi() {
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        print_warning "This script is designed for Raspberry Pi"
        print_status "Continuing anyway..."
    fi
}

# Update system
update_system() {
    print_status "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    print_success "System updated successfully"
}

# Install system dependencies
install_system_deps() {
    print_status "Installing system dependencies..."
    
    # Install required packages
    sudo apt install -y python3-pip python3-venv hostapd dnsmasq iptables-persistent git
    
    # Enable services
    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd
    sudo systemctl enable dnsmasq
    
    print_success "System dependencies installed"
}

# Install Python dependencies
install_python_deps() {
    print_status "Installing Python dependencies..."
    
    # Create virtual environment
    python3 -m venv venv
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install requirements
    pip install -r backend/requirements.txt
    
    print_success "Python dependencies installed"
}

# Initialize database
init_database() {
    print_status "Initializing database..."
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Run database initialization
    python3 setup/init_db.py
    
    print_success "Database initialized"
}

# Configure network interface
configure_network() {
    print_status "Configuring network interface..."
    
    # Backup original dhcpcd.conf
    sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.backup
    
    # Add static IP configuration
    echo "" | sudo tee -a /etc/dhcpcd.conf
    echo "# Static IP for Wi-Fi AP" | sudo tee -a /etc/dhcpcd.conf
    echo "interface wlan0" | sudo tee -a /etc/dhcpcd.conf
    echo "static ip_address=192.168.4.1/24" | sudo tee -a /etc/dhcpcd.conf
    echo "nohook wpa_supplicant" | sudo tee -a /etc/dhcpcd.conf
    
    print_success "Network interface configured"
}

# Configure hostapd
configure_hostapd() {
    print_status "Configuring hostapd..."
    
    # Create hostapd configuration
    sudo tee /etc/hostapd/hostapd.conf > /dev/null <<EOF
# Wi-Fi Access Point Configuration
interface=wlan0
driver=nl80211
ssid=Muon Telescope
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=muon123456
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
    
    # Configure hostapd to use our config
    sudo sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd
    
    print_success "hostapd configured"
}

# Configure dnsmasq
configure_dnsmasq() {
    print_status "Configuring dnsmasq..."
    
    # Backup original config
    sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
    
    # Create new dnsmasq configuration
    sudo tee /etc/dnsmasq.conf > /dev/null <<EOF
# DHCP and DNS Configuration
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
dhcp-option=3,192.168.4.1
dhcp-option=6,192.168.4.1
server=8.8.8.8
log-queries
log-dhcp
listen-address=192.168.4.1
bind-interfaces
EOF
    
    print_success "dnsmasq configured"
}

# Configure IP forwarding
configure_ip_forwarding() {
    print_status "Configuring IP forwarding..."
    
    # Enable IP forwarding
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    
    # Apply changes
    sudo sysctl -p
    
    print_success "IP forwarding enabled"
}

# Create iptables script
create_iptables_script() {
    print_status "Creating iptables configuration..."
    
    sudo tee /usr/local/bin/setup-captive-portal.sh > /dev/null <<'EOF'
#!/bin/bash

# Flush existing rules
iptables -F
iptables -t nat -F

# Set default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow SSH (if needed)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow DNS
iptables -A INPUT -p udp --dport 53 -j ACCEPT

# Allow DHCP
iptables -A INPUT -p udp --dport 67:68 -j ACCEPT

# Allow HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 8000 -j ACCEPT

# NAT for internet access (optional)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Redirect HTTP traffic to login page
iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j DNAT --to-destination 192.168.4.1:8000

# Allow forwarding for wlan0
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o wlan0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
EOF
    
    sudo chmod +x /usr/local/bin/setup-captive-portal.sh
    
    print_success "iptables script created"
}

# Create startup script
create_startup_script() {
    print_status "Creating startup script..."
    
    sudo tee /usr/local/bin/start-muon-telescope.sh > /dev/null <<'EOF'
#!/bin/bash

# Start Muon Telescope System
echo "Starting Muon Telescope System..."

# Setup iptables
/usr/local/bin/setup-captive-portal.sh

# Start services
sudo systemctl start hostapd
sudo systemctl start dnsmasq

# Start the web application
cd /home/pi/muon-telescope-project
source venv/bin/activate
python3 backend/main.py
EOF
    
    sudo chmod +x /usr/local/bin/start-muon-telescope.sh
    
    print_success "Startup script created"
}

# Create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    sudo tee /etc/systemd/system/muon-telescope.service > /dev/null <<EOF
[Unit]
Description=Muon Telescope Control System
After=network.target hostapd.service dnsmasq.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/muon-telescope-project
ExecStart=/usr/local/bin/start-muon-telescope.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl enable muon-telescope.service
    
    print_success "Systemd service created and enabled"
}

# Test GPIO
test_gpio() {
    print_status "Testing GPIO connections..."
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Run GPIO test
    python3 tests/gpio_test.py
    
    print_success "GPIO test completed"
}

# Main installation function
main() {
    echo "🔬 Muon Telescope Installation Script"
    echo "====================================="
    echo ""
    
    # Check prerequisites
    check_root
    check_raspberry_pi
    
    # Installation steps
    update_system
    install_system_deps
    install_python_deps
    init_database
    configure_network
    configure_hostapd
    configure_dnsmasq
    configure_ip_forwarding
    create_iptables_script
    create_startup_script
    create_systemd_service
    
    echo ""
    print_success "Installation completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Test GPIO connections: python3 tests/gpio_test.py"
    echo "2. Start the system: sudo /usr/local/bin/start-muon-telescope.sh"
    echo "3. Connect to Wi-Fi: Muon Telescope (password: muon123456)"
    echo "4. Access web interface: http://192.168.4.1:8000"
    echo "5. Login with: admin / admin"
    echo ""
    print_warning "Remember to change default passwords in production!"
    echo ""
}

# Run main function
main "$@" 