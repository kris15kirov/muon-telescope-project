# 🚀 Muon Telescope Deployment Guide

This guide explains how to deploy the Muon Telescope project to Raspberry Pi.

## 📋 Prerequisites

### Hardware Requirements
- Raspberry Pi 3B+ (or compatible)
- DM556 stepper motor driver
- Stepper motor (200 steps/revolution recommended)
- Power supply for motor driver
- Jumper wires for GPIO connections

### Software Requirements
- Raspberry Pi OS (Debian-based)
- SSH access to Raspberry Pi
- Internet connection for initial setup

## 🔧 Deployment Methods

### Method 1: Automated Deployment (Recommended)

#### Step 1: Prepare Your Local Machine
```bash
# Ensure you're in the project directory
cd ~/muon-telescope-project

# The deployment script is already created
ls -la deploy_to_pi.sh
```

#### Step 2: Find Raspberry Pi IP Address
```bash
# On Raspberry Pi, find the IP address
hostname -I
# or
ip addr show wlan0
```

#### Step 3: Run Automated Deployment
```bash
# Replace <raspberry-pi-ip> with actual IP
./deploy_to_pi.sh <raspberry-pi-ip>

# Example:
./deploy_to_pi.sh 192.168.1.100
```

### Method 2: Manual Git Clone

#### Step 1: On Raspberry Pi
```bash
# Navigate to home directory
cd /home/pi

# Clone the repository
git clone https://github.com/kris15kirov/muon-telescope-project.git

# Navigate to project directory
cd muon-telescope-project
```

#### Step 2: Create Environment File
```bash
# Create .env file
nano .env
```

Add the following content:
```env
DJANGO_SECRET_KEY=supersecretkey123456789abcdefghijklmnopqrstuvwxyz
DJANGO_DEBUG=False
DJANGO_DB_PATH=/home/pi/muon-telescope-project/db.sqlite3

# GPIO pin configuration
MOTOR_GPIO_PIN=17
LED_GPIO_PIN=27
```

### Method 3: Manual File Transfer

#### Step 1: Create Clean Archive
```bash
# On your local machine
git archive --format=zip --output=muon-telescope-clean.zip HEAD
```

#### Step 2: Transfer Files
```bash
# Transfer archive to Raspberry Pi
scp muon-telescope-clean.zip pi@<raspberry-pi-ip>:/home/pi/

# Transfer .env file
scp .env pi@<raspberry-pi-ip>:/home/pi/
```

#### Step 3: Extract on Raspberry Pi
```bash
# On Raspberry Pi
cd /home/pi
unzip muon-telescope-clean.zip
mv muon-telescope-project-* muon-telescope-project
cp .env muon-telescope-project/
cd muon-telescope-project
```

## 🔧 Installation and Setup

### Step 1: Automated Deployment (Recommended)
The deployment script now handles everything automatically:
```bash
# Run the deployment script from your local machine
./deploy_to_pi.sh <raspberry-pi-ip>

# This will:
# ✅ Transfer codebase and environment files
# ✅ Extract and set up the project
# ✅ Install Python dependencies in virtual environment
# ✅ Run database migrations
# ✅ Create admin user
# ✅ Test GPIO connections
# ✅ Set up systemd service for auto-start
# ✅ Set secure permissions on .env file
```

### Step 2: Start the System
```bash
# Manual start
sudo /usr/local/bin/start-muon-telescope.sh

# Or the systemd service should already be enabled
sudo systemctl status muon-telescope.service
```

### Step 3: Test Hardware (Optional)
```bash
# Test GPIO connections
python3 tests/gpio_test.py
```

## 🌐 Accessing the System

### Step 1: Connect to Wi-Fi
- **SSID**: `Muon Telescope`
- **Password**: `muon123456`

### Step 2: Access Web Interface
- Open any website in your browser
- You'll be automatically redirected to the login page
- Or navigate directly to: `http://192.168.4.1:8000`

### Step 3: Login
- **Username**: `admin`
- **Password**: `admin`

## 🔧 Hardware Setup

### GPIO Connections
| Raspberry Pi | DM556 Driver | Description |
|--------------|--------------|-------------|
| GPIO 17      | EN+          | Enable (active low) |
| GPIO 18      | DIR+         | Direction control |
| GPIO 27      | PUL+         | Step pulse |
| GND          | GND          | Common ground |
| 5V/3.3V      | VCC          | Power supply |

### Wiring Diagram
```
Raspberry Pi 3B+
┌─────────────┐
│ GPIO 17 ────┼──► EN+  DM556
│ GPIO 18 ────┼──► DIR+ Driver
│ GPIO 27 ────┼──► PUL+
│ GND ────────┼──► GND
│ 5V ─────────┼──► VCC
└─────────────┘
```

## 🐛 Troubleshooting

### Common Issues

**Motor not responding:**
```bash
# Check GPIO connections
python3 tests/gpio_test.py

# Verify driver power
# Check jumper wires
```

**Wi-Fi not appearing:**
```bash
# Check hostapd status
sudo systemctl status hostapd

# View logs
sudo journalctl -u hostapd -f
```

**Web interface not loading:**
```bash
# Check Django status
curl http://192.168.4.1:8000/

# Check iptables rules
sudo iptables -t nat -L -n -v
```

**Database errors:**
```bash
# Reinitialize database
python3 manage.py migrate

# Check file permissions
ls -la db.sqlite3
```

### Logs and Debugging

**View application logs:**
```bash
# Django logs (if configured)
tail -f logs/app.log

# System logs
sudo journalctl -f
```

**Reset everything:**
```bash
# Stop all services
sudo systemctl stop hostapd dnsmasq
```

## 🔒 Security Considerations

### Default Credentials
- **Web Interface**: admin / admin
- **Wi-Fi Network**: muon123456

**⚠️ Important**: Change default passwords in production!

### Environment Variables
The `.env` file contains sensitive information:
- `DJANGO_SECRET_KEY`: Used for session security
- `DJANGO_DB_PATH`: Database file location
- `MOTOR_GPIO_PIN`: GPIO pin for motor control
- `LED_GPIO_PIN`: GPIO pin for LED indicator

**⚠️ Important**: Keep the `.env` file secure and don't commit it to version control!
**🔒 Security**: The deployment script sets proper permissions (chmod 600) on the .env file.

## 📊 Performance Monitoring

### System Resources
```bash
# Check CPU and memory usage
htop

# Check disk space
df -h

# Check network interfaces
ip addr show
```

### Application Monitoring
```bash
# Check Django process
ps aux | grep python

# Check network services
sudo systemctl status hostapd dnsmasq
```

## 🚀 Quick Start Summary

1. **Transfer code**: Use `./deploy_to_pi.sh <ip>`
2. **Install system**: Run `./setup/install.sh`
3. **Test hardware**: Run `python3 tests/gpio_test.py`
4. **Start system**: Run `sudo /usr/local/bin/start-muon-telescope.sh`
5. **Connect to Wi-Fi**: "Muon Telescope" (password: muon123456)
6. **Access web interface**: http://192.168.4.1:8000
7. **Login**: admin / admin

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review system logs: `sudo journalctl -f`
3. Test hardware connections: `python3 tests/gpio_test.py`
4. Verify network configuration: `sudo systemctl status hostapd dnsmasq`

---

**🎉 Your Muon Telescope system is ready for deployment!** 