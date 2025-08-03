# 🏫 University WiFi Setup Guide for Muon Telescope

This guide helps you configure your Raspberry Pi-based muon telescope to work on university WiFi networks.

## 📋 Prerequisites

- Raspberry Pi with muon telescope software installed
- University WiFi credentials (SSID and password)
- Physical access to the Pi (via HDMI/monitor or SSH)

## 🚀 Quick Setup

### Step 1: Connect to the Pi

**Option A: Direct Connection (Recommended)**
1. Connect HDMI monitor and keyboard to the Pi
2. Power on the Pi
3. Login with: `pi` / `raspberry`

**Option B: SSH Connection**
```bash
ssh pi@192.168.2.186  # Use current IP from terminal
```

### Step 2: Run University WiFi Configuration

```bash
# Navigate to project directory
cd ~/muon-telescope-project

# Run the configuration script
sudo ./setup/configure_university_wifi.sh
```

The script will:
- Scan for available WiFi networks
- Ask for university WiFi credentials
- Configure the Pi to connect to university WiFi
- Update Django and Nginx settings
- Test connectivity

### Step 3: Verify Setup

```bash
# Check network status
sudo ./setup/check_network_status.sh
```

## 🔧 Manual Configuration (Alternative)

If the automated script doesn't work, you can configure manually:

### 1. Configure WiFi

Edit the WiFi configuration:
```bash
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```

Add your university network:
```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YOUR_UNIVERSITY_WIFI_SSID"
    psk="YOUR_UNIVERSITY_WIFI_PASSWORD"
    key_mgmt=WPA-PSK
    scan_ssid=1
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
sudo sed -i "s/server_name 192.168.100.36/server_name $NEW_IP/" /etc/nginx/sites-available/muon-telescope
sudo nginx -t && sudo systemctl reload nginx

# Restart Django service
sudo systemctl restart muon-telescope-dev.service
```

## 🌐 Access Information

After successful configuration:

- **Web Interface**: `https://[NEW_IP]/control/`
- **Login**: `admin` / `admin`
- **API Health**: `https://[NEW_IP]/api/health/`

Replace `[NEW_IP]` with the actual IP address assigned by the university network.

## 🔍 Troubleshooting

### Common Issues

**1. Pi won't connect to university WiFi**
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

# Check logs
sudo journalctl -u muon-telescope-dev.service -f
```

**3. University network blocks device**
- Contact university IT for device registration
- Some universities require MAC address registration
- Check if university uses enterprise WiFi (WPA2-Enterprise)

### Network Diagnostics

```bash
# Check current IP
hostname -I

# Check WiFi connection
iwconfig wlan0

# Test internet connectivity
ping -c 3 8.8.8.8

# Test local network
ping -c 3 $(hostname -I | awk '{print $1}')

# Check DNS resolution
nslookup google.com
```

## 📱 Mobile Access

Once configured, you can access the telescope from any device on the university network:

1. **Connect your phone/laptop to university WiFi**
2. **Open browser and go to**: `https://[PI_IP]/control/`
3. **Login with**: `admin` / `admin`
4. **Control the telescope remotely**

## 🔒 Security Notes

- The web interface uses HTTPS with a self-signed certificate
- Accept the certificate warning in your browser
- Change default admin password in production
- University networks may have additional security policies

## 📞 Support

If you encounter issues:

1. **Check network status**: `sudo ./setup/check_network_status.sh`
2. **Review logs**: `sudo journalctl -u wpa_supplicant -f`
3. **Contact university IT** for network-specific issues
4. **Check project documentation** for application issues

## 🎯 Success Indicators

Your setup is working correctly when:

- ✅ Pi connects to university WiFi automatically
- ✅ Web interface accessible from university network
- ✅ Motor controls respond to commands
- ✅ API health endpoint returns `{"status": "healthy"}`
- ✅ Can access from multiple devices on university network 