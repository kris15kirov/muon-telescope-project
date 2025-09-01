# 🔬 Computer-Controlled Muon Telescope via Web Interface

A complete Raspberry Pi-based system for controlling a stepper motor telescope via a web interface with secure authentication.

## 🌟 Features

- **Web Interface**: Modern, responsive UI for motor control
- **Authentication**: Secure login system with session management
- **Motor Control**: Precise stepper motor control via DM556 driver
- **Real-time Updates**: Live status updates and movement logging
- **Network Access**: Works on university network for easy access
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
│                 │    │ │   Nginx     │    │    │ │   GPIO      │ │
│                 │    │ │   HTTPS     │    │    │ │  Control    │ │
│                 │    │ │   Proxy     │    │    │ └─────────────┘ │
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
- Nginx (web server)
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
sudo apt install -y python3-pip python3-venv nginx

# Enable services
sudo systemctl enable nginx
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

### Step 7: Configure Network Access

**University WiFi Setup (Recommended):**
- Connect Pi to university WiFi network
- Run: `sudo ./setup/configure_university_wifi.sh`
- Follow: `UNIVERSITY_SETUP.md`

### Step 8: Start the Application
```bash
# Manual start
python3 manage.py runserver 0.0.0.0:8000

# Or use systemd service (if configured)
sudo systemctl start muon-telescope-dev.service
```

## 🌐 Usage

### Connecting to the System

**University WiFi Setup:**
1. **Connect Pi to university WiFi** using the setup script
2. **Access from university network**: `https://[PI_IP]/control/`
3. **Login**: Use the admin account you created

**Find Pi IP Address:**
```bash
# On the Pi
hostname -I

# Or check network status
sudo ./setup/check_network_status.sh
```

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
├── setup/                   # Setup scripts
│   ├── configure_university_wifi.sh  # University WiFi setup
│   ├── check_network_status.sh       # Network diagnostics
│   └── install_nginx.sh              # Web server setup
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

## 🧱 Software Stack (Python/Django)

**🐍 Main Language:**  
- Python 3.11+

**🔌 Hardware Control:**  
- RPi.GPIO (or mock GPIO for development)
- time – step and delay control

**🧠 Backend:**  
- Django 4.2+ – stable and secure web framework
- SQLite3 – local database for users and logs
- Django admin – for user and settings management
- Django session-based authentication

**🔐 Login & Security:**  
- Password hashing (Django built-in)
- Session and role-based access (admin/user)
- Option: Captive Portal if Raspberry Pi is in Access Point mode (configuration is external and not part of this repository)

**🌐 Frontend:**  
- HTML/CSS + JavaScript (plain JS)
- Jinja2/Django templates for dynamic pages
- Static files served by Django/WhiteNoise

**📶 Network & Access:**  
- Raspberry Pi in a local network
- (Optional) Wi-Fi Access Point mode via hostapd + dnsmasq

---

## Environment & Configuration

- All sensitive data (SECRET_KEY, passwords, Wi-Fi credentials) should be stored in a `.env` file and loaded via `django-environ` or a similar package.
- Example variables:
  - `DJANGO_SECRET_KEY`
  - `DJANGO_DEBUG`
  - `DJANGO_DB_PATH`
- It is recommended to change all default credentials during initial installation.
