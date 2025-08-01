#!/bin/bash

# HTTPS Verification Script for Muon Telescope
# This script verifies that HTTPS is working correctly

set -e

echo "🔍 Verifying HTTPS setup for Muon Telescope..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check 1: SSL certificate exists
echo "📋 Checking SSL certificate..."
if [ -f /etc/ssl/muon-telescope/muon-telescope.crt ]; then
    print_status "SSL certificate exists"
    echo "   Certificate: /etc/ssl/muon-telescope/muon-telescope.crt"
    echo "   Valid until: $(openssl x509 -in /etc/ssl/muon-telescope/muon-telescope.crt -noout -enddate | cut -d= -f2)"
else
    print_error "SSL certificate not found"
    exit 1
fi

# Check 2: Private key exists
echo "🔑 Checking private key..."
if [ -f /etc/ssl/muon-telescope/muon-telescope.key ]; then
    print_status "Private key exists"
    echo "   Key permissions: $(ls -la /etc/ssl/muon-telescope/muon-telescope.key | awk '{print $1}')"
else
    print_error "Private key not found"
    exit 1
fi

# Check 3: Nginx is running
echo "🌐 Checking Nginx status..."
if systemctl is-active --quiet nginx; then
    print_status "Nginx is running"
else
    print_error "Nginx is not running"
    echo "   Start with: sudo systemctl start nginx"
    exit 1
fi

# Check 4: Nginx configuration is valid
echo "⚙️ Checking Nginx configuration..."
if nginx -t > /dev/null 2>&1; then
    print_status "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    nginx -t
    exit 1
fi

# Check 5: Django is running
echo "🐍 Checking Django application..."
if pgrep -f "manage.py runserver" > /dev/null; then
    print_status "Django application is running"
else
    print_warning "Django application is not running"
    echo "   Start with: sudo systemctl start muon-telescope-https.service"
fi

# Check 6: Port 443 is listening
echo "🔌 Checking HTTPS port..."
if netstat -tlnp | grep ":443 " > /dev/null; then
    print_status "Port 443 is listening"
else
    print_error "Port 443 is not listening"
    exit 1
fi

# Check 7: Test HTTPS connection
echo "🌐 Testing HTTPS connection..."
if curl -k -s -o /dev/null -w "%{http_code}" https://192.168.4.1 | grep -q "200\|301\|302"; then
    print_status "HTTPS connection successful"
else
    print_error "HTTPS connection failed"
    echo "   Try: curl -k https://192.168.4.1"
fi

# Check 8: Test HTTP to HTTPS redirect
echo "🔄 Testing HTTP to HTTPS redirect..."
REDIRECT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.4.1)
if [ "$REDIRECT_STATUS" = "301" ] || [ "$REDIRECT_STATUS" = "302" ]; then
    print_status "HTTP to HTTPS redirect working"
else
    print_warning "HTTP to HTTPS redirect may not be working"
    echo "   HTTP status: $REDIRECT_STATUS"
fi

# Check 9: Certificate details
echo "📜 Certificate details:"
openssl x509 -in /etc/ssl/muon-telescope/muon-telescope.crt -noout -subject -issuer -dates

# Check 10: SSL/TLS protocols
echo "🔒 Testing SSL/TLS protocols..."
echo "   Testing TLS 1.2:"
if openssl s_client -connect 192.168.4.1:443 -tls1_2 -servername 192.168.4.1 < /dev/null > /dev/null 2>&1; then
    print_status "TLS 1.2 supported"
else
    print_warning "TLS 1.2 not supported"
fi

echo "   Testing TLS 1.3:"
if openssl s_client -connect 192.168.4.1:443 -tls1_3 -servername 192.168.4.1 < /dev/null > /dev/null 2>&1; then
    print_status "TLS 1.3 supported"
else
    print_warning "TLS 1.3 not supported"
fi

echo ""
echo "🎉 HTTPS verification complete!"
echo ""
echo "🌐 Access your application:"
echo "   - HTTPS: https://192.168.4.1"
echo "   - HTTP: http://192.168.4.1 (redirects to HTTPS)"
echo ""
echo "📊 Service status:"
echo "   sudo systemctl status nginx"
echo "   sudo systemctl status muon-telescope-https.service"
echo ""
echo "📝 Logs:"
echo "   sudo journalctl -u nginx -f"
echo "   sudo journalctl -u muon-telescope-https.service -f" 