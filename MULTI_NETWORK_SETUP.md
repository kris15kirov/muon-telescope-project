# 🌐 Multi-Network Setup Guide for Muon Telescope

This guide helps you configure your Raspberry Pi to work seamlessly with both your home WiFi and university WiFi networks.

## 🎯 Overview

The multi-network setup provides:
- **Automatic network switching** between home and university WiFi
- **Priority-based connection** (university preferred over home)
- **Dynamic IP handling** - web interface updates automatically
- **Seamless access** from any device on either network

## 🚀 Quick Setup

### Step 1: Connect to the Pi

**Option A: Direct Connection (Recommended)**
```bash
# Connect HDMI monitor and keyboard to the Pi
# Login with: pi / raspberry
```

**Option B: SSH Connection**
```bash
# Use current IP from terminal screenshots
ssh pi@192.168.2.186
```

### Step 2: Run Multi-Network Configuration

```bash
# Navigate to project directory
cd ~/muon-telescope-project

# Run the multi-network configuration script
sudo ./setup/configure_multi_network.sh
```

The script will:
- Ask for both home and university WiFi credentials
- Configure network priority (university > home)
- Set up automatic IP updates
- Create monitoring tools
- Test connectivity

## 📋 Configuration Details

### Network Priority
- **University WiFi**: Priority 2 (preferred)
- **Home WiFi**: Priority 1 (fallback)

### Automatic Features
- **Network switching**: Pi connects to university when available
- **IP updates**: Web interface URL updates automatically
- **Service restart**: Django and Nginx restart when IP changes
- **Status monitoring**: Easy status checking with `muon-status`

## 🔧 Manual Configuration (Alternative)

If the automated script doesn't work:

### 1. Configure WiFi Networks

Edit the WiFi configuration:
```bash
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```

Add both networks with priority:
```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

# University network (higher priority)
network={
    ssid="YOUR_UNIVERSITY_WIFI_SSID"
    psk="YOUR_UNIVERSITY_WIFI_PASSWORD"
    key_mgmt=WPA-PSK
    scan_ssid=1
    priority=2
}

# Home network (lower priority)
network={
    ssid="YOUR_HOME_WIFI_SSID"
    psk="YOUR_HOME_WIFI_PASSWORD"
    key_mgmt=WPA-PSK
    scan_ssid=1
    priority=1
}
```

### 2. Restart Networking

```bash
sudo systemctl restart wpa_supplicant
sudo systemctl restart dhcpcd
```

### 3. Update Application Settings

```bash
# Get new IP address
NEW_IP=$(hostname -I | awk '{print $1}')

# Update Django settings
cd ~/muon-telescope-project
sed -i "s/ALLOWED_HOSTS = \[/ALLOWED_HOSTS = [\"$NEW_IP\", /" muon_telescope/settings.py
sed -i "s/CSRF_TRUSTED_ORIGINS = \[/CSRF_TRUSTED_ORIGINS = [\"https:\/\/$NEW_IP\", /" muon_telescope/settings.py

# Update Nginx configuration
sudo sed -i "s/server_name [0-9.]*;/server_name $NEW_IP;/" /etc/nginx/sites-available/muon-telescope
sudo nginx -t && sudo systemctl reload nginx

# Restart Django service
sudo systemctl restart muon-telescope-dev.service
```

## 🌐 Access Information

After configuration, access the telescope from:

### Home Network
- **URL**: `https://[HOME_IP]/control/`
- **Login**: `admin` / `admin`

### University Network
- **URL**: `https://[UNIVERSITY_IP]/control/`
- **Login**: `admin` / `admin`

### Find Current IP
```bash
# Quick status check
muon-status

# Or check network status
sudo ./setup/check_network_status.sh
```

## 🔍 Troubleshooting

### Common Issues

**1. Pi won't connect to either network**
```bash
# Check WiFi status
sudo iwconfig wlan0

# Check network logs
sudo journalctl -u wpa_supplicant -f

# Restart networking
sudo systemctl restart wpa_supplicant
```

**2. Web interface not accessible**
```bash
# Check service status
sudo systemctl status muon-telescope-dev.service nginx

# Restart services
sudo systemctl restart muon-telescope-dev.service
sudo systemctl restart nginx

# Manual IP update
sudo /usr/local/bin/update-muon-ip.sh
```

**3. University network blocks device**
- Contact university IT for device registration
- Some universities require MAC address registration
- Check if university uses enterprise WiFi (WPA2-Enterprise)

### Network Diagnostics

```bash
# Check current IP and network
muon-status

# Detailed network check
sudo ./setup/check_network_status.sh

# Check WiFi connection
iwconfig wlan0

# Test internet connectivity
ping -c 3 8.8.8.8

# Check DNS resolution
nslookup google.com
```

## 📱 Mobile Access

Once configured, access the telescope from any device:

### From Home
1. **Connect to home WiFi** on your phone/laptop
2. **Open browser**: `https://[HOME_IP]/control/`
3. **Login**: `admin` / `admin`

### From University
1. **Connect to university WiFi** on your phone/laptop
2. **Open browser**: `https://[UNIVERSITY_IP]/control/`
3. **Login**: `admin` / `admin`

## 🔒 Security Notes

- Web interface uses HTTPS with self-signed certificate
- Accept certificate warnings in your browser
- Change default admin password in production
- University networks may have additional security policies

## 📞 Support

If you encounter issues:

1. **Check network status**: `muon-status`
2. **Review logs**: `sudo journalctl -u wpa_supplicant -f`
3. **Contact university IT** for network-specific issues
4. **Check project documentation** for application issues

## 🎯 Success Indicators

Your multi-network setup is working correctly when:

- ✅ Pi connects to university WiFi when available
- ✅ Pi falls back to home WiFi when university is unavailable
- ✅ Web interface accessible from both networks
- ✅ IP address updates automatically when switching networks
- ✅ Motor controls respond to commands from both networks
- ✅ Can access from multiple devices on both networks

## 🔄 Network Switching Behavior

The Pi will automatically:
1. **Try university WiFi first** (priority 2)
2. **Fall back to home WiFi** if university is unavailable (priority 1)
3. **Update web interface IP** when switching networks
4. **Restart services** to ensure proper configuration
5. **Maintain connectivity** during network transitions 