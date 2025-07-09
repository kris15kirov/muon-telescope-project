# Captive Portal Setup for Muon Telescope

This guide explains how to set up a captive portal on the Raspberry Pi so that when users connect to the "Muon Telescope" Wi-Fi network, they are automatically redirected to the login page.

## Overview

The captive portal consists of:
- **hostapd**: Creates the Wi-Fi access point
- **dnsmasq**: Provides DHCP and DNS services
- **iptables**: Redirects HTTP traffic to the login page
- **FastAPI**: Serves the web interface

## Prerequisites

1. Raspberry Pi 3B+ with Raspberry Pi OS
2. Internet connection for initial setup
3. Root/sudo access

## Step 1: Install Required Packages

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y hostapd dnsmasq iptables-persistent

# Enable services
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq
```

## Step 2: Configure Network Interface

Edit the network configuration:

```bash
sudo nano /etc/dhcpcd.conf
```

Add these lines at the end:

```
# Static IP for Wi-Fi AP
interface wlan0
static ip_address=192.168.4.1/24
nohook wpa_supplicant
```

## Step 3: Configure hostapd

Create the hostapd configuration file:

```bash
sudo nano /etc/hostapd/hostapd.conf
```

Add this content:

```
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
```

Update hostapd to use this config:

```bash
sudo nano /etc/default/hostapd
```

Change the line to:
```
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```

## Step 4: Configure dnsmasq

Backup the original config and create a new one:

```bash
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo nano /etc/dnsmasq.conf
```

Add this content:

```
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
```

## Step 5: Configure IP Forwarding

Enable IP forwarding:

```bash
sudo nano /etc/sysctl.conf
```

Uncomment or add:
```
net.ipv4.ip_forward=1
```

Apply changes:
```bash
sudo sysctl -p
```

## Step 6: Configure iptables Rules

Create a script to set up iptables rules:

```bash
sudo nano /usr/local/bin/setup-captive-portal.sh
```

Add this content:

```bash
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
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/setup-captive-portal.sh
```

## Step 7: Create Startup Script

Create a script to start everything:

```bash
sudo nano /usr/local/bin/start-muon-telescope.sh
```

Add this content:

```bash
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
python3 backend/main.py
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/start-muon-telescope.sh
```

## Step 8: Create Systemd Service (Optional)

Create a systemd service to auto-start the application:

```bash
sudo nano /etc/systemd/system/muon-telescope.service
```

Add this content:

```ini
[Unit]
Description=Muon Telescope Control System
After=network.target hostapd.service dnsmasq.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/muon-telescope-project
ExecStart=/usr/bin/python3 backend/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable the service:
```bash
sudo systemctl enable muon-telescope.service
```

## Step 9: Test the Setup

1. **Start the services manually:**
   ```bash
   sudo /usr/local/bin/start-muon-telescope.sh
   ```

2. **Connect to Wi-Fi:**
   - SSID: `Muon Telescope`
   - Password: `muon123456`

3. **Test captive portal:**
   - Open any website in a browser
   - Should redirect to `http://192.168.4.1:8000`

## Troubleshooting

### Check Services Status
```bash
sudo systemctl status hostapd
sudo systemctl status dnsmasq
```

### Check iptables Rules
```bash
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v
```

### Check Network Interface
```bash
ip addr show wlan0
```

### View Logs
```bash
sudo journalctl -u hostapd -f
sudo journalctl -u dnsmasq -f
```

### Reset Everything
```bash
sudo systemctl stop hostapd dnsmasq
sudo iptables -F
sudo iptables -t nat -F
sudo /usr/local/bin/setup-captive-portal.sh
sudo systemctl start hostapd dnsmasq
```

## Security Notes

1. **Change default passwords:**
   - Wi-Fi password: Edit `/etc/hostapd/hostapd.conf`
   - Web interface password: Use the web interface to change admin password

2. **Firewall rules:**
   - The iptables rules provided are basic
   - Consider adding more restrictive rules for production

3. **Network isolation:**
   - The current setup allows internet access through eth0
   - For complete isolation, remove the MASQUERADE rule

## Customization

### Change Wi-Fi Settings
Edit `/etc/hostapd/hostapd.conf`:
- `ssid`: Change the network name
- `wpa_passphrase`: Change the password
- `channel`: Change the Wi-Fi channel

### Change IP Range
Edit `/etc/dnsmasq.conf`:
- `dhcp-range`: Change the DHCP range
- Update iptables rules accordingly

### Change Web Interface Port
Edit the FastAPI app and iptables rules to use a different port.

## Files Created

- `/etc/hostapd/hostapd.conf` - Wi-Fi AP configuration
- `/etc/dnsmasq.conf` - DHCP/DNS configuration
- `/usr/local/bin/setup-captive-portal.sh` - iptables setup script
- `/usr/local/bin/start-muon-telescope.sh` - Startup script
- `/etc/systemd/system/muon-telescope.service` - Systemd service (optional) 