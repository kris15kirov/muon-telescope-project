#!/bin/bash

# Update iptables for HTTPS support
# This script updates the existing iptables rules to properly handle HTTPS traffic

set -e

echo "🔒 Updating iptables for HTTPS support..."

# Create updated iptables script
sudo tee /usr/local/bin/setup-captive-portal-https.sh > /dev/null <<'EOF'
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

# Allow HTTP/HTTPS traffic
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 8000 -j ACCEPT

# NAT for internet access (optional)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Redirect HTTP traffic to HTTPS (if not using Nginx)
# iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j DNAT --to-destination 192.168.4.1:443

# Allow forwarding for wlan0
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o wlan0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
EOF

sudo chmod +x /usr/local/bin/setup-captive-portal-https.sh

echo "✅ iptables updated for HTTPS support!"
echo "📝 New script: /usr/local/bin/setup-captive-portal-https.sh" 