# 🔬 Computer-Controlled Muon Telescope via Web Interface

A complete Raspberry Pi-based system for controlling a stepper motor telescope via a web interface with captive portal authentication.

## 🌟 Features

- **Wi-Fi Access Point**: Creates "Muon Telescope" network with captive portal
- **Web Interface**: Modern, responsive UI for motor control
- **Authentication**: Secure login system with session management
- **Motor Control**: Precise stepper motor control via DM556 driver
- **Real-time Updates**: Live status updates and movement logging
- **Offline Operation**: Works entirely without internet connection
- **Database Logging**: Tracks all motor movements and user actions

## 🏗️ Architecture

```
┌─────────────────┐    ┌────────────────────┐    ┌─────────────────┐
│   User Device   │    │  Raspberry Pi      │    │  Stepper Motor  │
│                 │    │                    │    │                 │
│ ┌─────────────┐ │    │ ┌───────────────┐  │    │ ┌─────────────┐ │
│ │   Browser   │◄────►│ │   Django      │  │    │ │   DM556     │ │
│ │             │ │    │ │   Backend     │  │    │ │   Driver    │ │
│ └─────────────┘ │    │ └───────────────┘  │    │ └─────────────┘ │
│                 │    │ ┌─────────────┐    │    │ ┌─────────────┐ │
│                 │    │ │  hostapd    │    │    │ │   GPIO      │ │
│                 │    │ │  dnsmasq    │    │    │ │  Control    │ │
│                 │    │ │  iptables   │    │    │ └─────────────┘ │
│                 │    │ └─────────────┘    │    └─────────────────┘
└─────────────────┘    └────────────────────┘
```

## 📋 Requirements

### Hardware
- Raspberry Pi 3B+ (or compatible)
- DM556 stepper motor driver
- Stepper motor (200 steps/revolution recommended)
- Power supply for motor driver
- Jumper wires for GPIO connections

### Software
- Raspberry Pi OS (Debian-based)
- Python 3.11+
- Django 4.2+
- Required packages (see installation)

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

## Installation

### Step 1: Clone the Repository
```bash
git clone <repository-url>
cd muon-telescope-project
```

### Step 2: Install System Dependencies
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3-pip python3-venv hostapd dnsmasq iptables-persistent

# Enable services
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq
```

### Step 3: Install Python Dependencies
```bash
# Create virtual environment (optional but recommended)
python3 -m venv venv
source venv/bin/activate

# Install Python packages
pip install -r requirements.txt
```

### Step 4: Initialize Database
```bash
python3 manage.py migrate
```

### Step 5: Create Superuser (Admin)
```bash
python3 manage.py createsuperuser
```

### Step 6: Test GPIO Connections
```bash
python3 tests/gpio_test.py
```

### Step 7: Configure Captive Portal
Follow the detailed instructions in `captive_portal/README.md`

### Step 8: Start the Application
```bash
# Manual start
python3 manage.py runserver 0.0.0.0:8000
```

## 🌐 Usage

### Connecting to the System

1. **Connect to Wi-Fi**:
   - SSID: `Muon Telescope`
   - Password: `muon123456`

2. **Access Web Interface**:
   - Open any website in your browser
   - You'll be automatically redirected to the login page
   - Or navigate directly to: `http://192.168.4.1:8000`

3. **Login**:
   - Use the admin account you created, or register a new user

### Controlling the Motor

1. **Set Direction**: Choose clockwise or counter-clockwise
2. **Enter Angle or Steps**: Specify degrees or steps
3. **Start Movement**: Click "Start Movement"
4. **Monitor Status**: Watch real-time position updates
5. **Stop if Needed**: Use "Stop Motor" button

## 📁 Project Structure

```
muon-telescope-project/
├── control/                 # Django app for motor control and UI
│   ├── views.py             # Django views (API and web)
│   ├── models.py            # (Optional) Custom models
│   ├── templates/           # HTML templates
│   └── static/              # CSS/JS files
├── muon_telescope/          # Django project settings
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── frontend/                # Additional static assets
│   └── static/
├── captive_portal/          # Network configuration
│   └── README.md            # Setup instructions
├── setup/                   # Setup scripts
│   └── init_db.py           # (Legacy) Database initialization
├── tests/                   # Test scripts
│   └── gpio_test.py         # GPIO test script
├── requirements.txt         # Python dependencies
└── README.md                # This file
```

## 🔧 Configuration

### Motor Parameters
Edit `muon_telescope/motor_control.py` to adjust:
- `STEPS_PER_REVOLUTION`: Motor steps per revolution (default: 200)
- `MICROSTEPS`: Driver microstepping (default: 16)
- `PWM_FREQ`: Step pulse frequency (default: 500 Hz)

### Network Settings
Edit captive portal configuration:
- Wi-Fi SSID: `/etc/hostapd/hostapd.conf`
- IP range: `/etc/dnsmasq.conf`
- Port: Django's `manage.py runserver` and iptables rules

### Security
- Change default passwords in production
- Update Wi-Fi password in hostapd config
- Use HTTPS in production environments

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

## 🔌 Enabling Web Shutdown on Raspberry Pi or Linux

To allow the Django web app to shut down the system without a password prompt, you must add a line to your sudoers file. This allows the user running your Django server to execute the shutdown command without being prompted for a password.

1. Open a terminal on your Raspberry Pi (or Linux server).
2. Run:
   ```bash
   sudo visudo
   ```
3. Add this line at the end (replace `pi` with your Django user if different):
   ```
   pi ALL=NOPASSWD: /sbin/shutdown
   ```
4. Save and exit.

**Note:**
- Do not add your Mac username or Mac-specific sudoers lines to the codebase.
- This is a deployment/server configuration step, not a code change.
- The shutdown command in the code is platform-agnostic and works on both Raspberry Pi and macOS/Linux:
  ```python
  subprocess.run(["sudo", "shutdown", "-h", "+5"], check=True)
  ```
