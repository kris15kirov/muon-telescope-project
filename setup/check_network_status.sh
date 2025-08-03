#!/bin/bash

# Network Status Checker for University WiFi
# This script checks the current network status and provides troubleshooting info

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

echo "🌐 Network Status Checker for University WiFi"
echo "============================================"

# Check current IP
CURRENT_IP=$(hostname -I | awk '{print $1}')
print_status "Current IP: $CURRENT_IP"

# Check WiFi interface status
print_status "WiFi Interface Status:"
if ip link show wlan0 | grep -q "UP"; then
    print_success "WiFi interface is UP"
else
    print_error "WiFi interface is DOWN"
fi

# Check WiFi connection
print_status "WiFi Connection Status:"
if iwconfig wlan0 2>/dev/null | grep -q "ESSID"; then
    CONNECTED_SSID=$(iwconfig wlan0 2>/dev/null | grep ESSID | sed 's/.*ESSID:"\([^"]*\)".*/\1/')
    print_success "Connected to: $CONNECTED_SSID"
else
    print_error "Not connected to any WiFi network"
fi

# Check internet connectivity
print_status "Internet Connectivity:"
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    print_success "Internet: OK"
else
    print_warning "Internet: FAILED"
fi

# Check local network
print_status "Local Network:"
if ping -c 1 $CURRENT_IP > /dev/null 2>&1; then
    print_success "Local network: OK"
else
    print_warning "Local network: FAILED"
fi

# Check application services
print_status "Application Services:"
if systemctl is-active --quiet muon-telescope-dev.service; then
    print_success "Django: RUNNING"
else
    print_error "Django: NOT RUNNING"
fi

if systemctl is-active --quiet nginx; then
    print_success "Nginx: RUNNING"
else
    print_error "Nginx: NOT RUNNING"
fi

# Check if web interface is accessible
print_status "Web Interface:"
if curl -k -s -o /dev/null -w "%{http_code}" https://$CURRENT_IP/api/health/ 2>/dev/null | grep -q "200"; then
    print_success "Web interface: ACCESSIBLE"
    echo "   URL: https://$CURRENT_IP/control/"
    echo "   Login: admin / admin"
else
    print_warning "Web interface: NOT ACCESSIBLE"
fi

echo ""
print_status "Troubleshooting Commands:"
echo "1. Check WiFi status: sudo iwconfig wlan0"
echo "2. Check network logs: sudo journalctl -u wpa_supplicant -f"
echo "3. Restart networking: sudo systemctl restart wpa_supplicant"
echo "4. Restart Django: sudo systemctl restart muon-telescope-dev.service"
echo "5. Restart Nginx: sudo systemctl restart nginx"
echo "6. Check all services: sudo systemctl status muon-telescope-dev.service nginx" 