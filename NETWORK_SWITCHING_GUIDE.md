# 🔄 Network Switching Guide for Muon Telescope

Quick reference for switching between different network configurations based on your location.

## 🏫 At University (University-Only Mode)

When you're at the university and want the Pi to only connect to university WiFi:

### Switch to University-Only Mode
```bash
# Connect to Pi (via HDMI/monitor or SSH)
ssh pi@[CURRENT_IP]

# Navigate to project directory
cd ~/muon-telescope-project

# Run university-only configuration
sudo ./setup/switch_to_university.sh
```

**What this does:**
- ✅ Removes home WiFi configuration
- ✅ Keeps only university WiFi
- ✅ Updates Django settings for university IP
- ✅ Creates backup of previous configuration
- ✅ Creates restore script for later use

### Access Information
- **URL**: `https://[UNIVERSITY_IP]/control/`
- **Login**: `admin` / `admin`
- **Status Check**: `muon-status`

## 🏠 At Home (Multi-Network Mode)

When you return home and want the Pi to work with both networks:

### Switch to Multi-Network Mode
```bash
# Connect to Pi (via HDMI/monitor or SSH)
ssh pi@[CURRENT_IP]

# Navigate to project directory
cd ~/muon-telescope-project

# Run multi-network configuration
sudo ./setup/switch_to_multi_network.sh
```

**What this does:**
- ✅ Configures both home and university WiFi
- ✅ Sets priority (university > home)
- ✅ Enables automatic network switching
- ✅ Updates Django settings for current IP

### Access Information
- **Home Network**: `https://[HOME_IP]/control/`
- **University Network**: `https://[UNIVERSITY_IP]/control/`
- **Login**: `admin` / `admin`
- **Status Check**: `muon-status`

## 🔧 Quick Commands

### Check Current Status
```bash
# Quick status check
muon-status

# Detailed network check
sudo ./setup/check_network_status.sh

# Check current IP
hostname -I
```

### Manual Network Management
```bash
# Restart networking
sudo systemctl restart wpa_supplicant
sudo systemctl restart dhcpcd

# Restart application services
sudo systemctl restart muon-telescope-dev.service
sudo systemctl restart nginx

# Manual IP update
sudo /usr/local/bin/update-muon-ip.sh
```

### Troubleshooting
```bash
# Check WiFi status
sudo iwconfig wlan0

# Check network logs
sudo journalctl -u wpa_supplicant -f

# Check application logs
sudo journalctl -u muon-telescope-dev.service -f
```

## 📋 Network Configuration Files

### WiFi Configuration
- **File**: `/etc/wpa_supplicant/wpa_supplicant.conf`
- **Backup**: Automatically created with timestamp
- **Restore**: Use restore script or manual configuration

### Django Settings
- **File**: `/home/pi/muon-telescope-project/muon_telescope/settings.py`
- **Updated**: Automatically when switching networks
- **IPs**: Added to ALLOWED_HOSTS and CSRF_TRUSTED_ORIGINS

### Nginx Configuration
- **File**: `/etc/nginx/sites-available/muon-telescope`
- **Updated**: Automatically when switching networks
- **Server Name**: Updated to current IP

## 🎯 When to Use Each Mode

### University-Only Mode
- ✅ **At university** - Pi only connects to university WiFi
- ✅ **Clean configuration** - No home network interference
- ✅ **Security** - No home network credentials stored
- ✅ **Performance** - Faster connection to university network

### Multi-Network Mode
- ✅ **At home** - Pi can connect to both networks
- ✅ **Automatic switching** - University when available, home as fallback
- ✅ **Flexibility** - Works in both locations
- ✅ **Convenience** - No manual switching needed

## 🔄 Switching Workflow

### Going to University
1. **Connect to Pi** (via HDMI/monitor or SSH)
2. **Run**: `sudo ./setup/switch_to_university.sh`
3. **Provide university WiFi credentials**
4. **Test access**: `muon-status`
5. **Access telescope**: `https://[UNIVERSITY_IP]/control/`

### Returning Home
1. **Connect to Pi** (via HDMI/monitor or SSH)
2. **Run**: `sudo ./setup/switch_to_multi_network.sh`
3. **Provide both home and university WiFi credentials**
4. **Test access**: `muon-status`
5. **Access telescope**: `https://[HOME_IP]/control/`

## 🚨 Important Notes

### Security
- **WiFi passwords** are stored in configuration files
- **HTTPS certificates** are self-signed (accept browser warnings)
- **Admin credentials** are `admin` / `admin` (change in production)

### Backup
- **Automatic backups** are created before each switch
- **Backup location**: `/etc/wpa_supplicant/wpa_supplicant.conf.backup.*`
- **Restore scripts** are created for easy recovery

### Troubleshooting
- **Network issues**: Check `sudo journalctl -u wpa_supplicant -f`
- **Application issues**: Check `sudo journalctl -u muon-telescope-dev.service -f`
- **Web interface issues**: Check `sudo systemctl status nginx`

## 📞 Quick Reference

| Action | Command | Location |
|--------|---------|----------|
| Switch to University | `sudo ./setup/switch_to_university.sh` | University |
| Switch to Multi-Network | `sudo ./setup/switch_to_multi_network.sh` | Home |
| Check Status | `muon-status` | Anywhere |
| Restart Services | `sudo systemctl restart muon-telescope-dev.service nginx` | Anywhere |
| View Logs | `sudo journalctl -u muon-telescope-dev.service -f` | Anywhere | 