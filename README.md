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
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Device   │    │  Raspberry Pi   │    │  Stepper Motor  │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   Browser   │◄────►│ │   FastAPI   │ │    │ │   DM556     │ │
│ │             │ │    │ │   Backend   │ │    │ │   Driver    │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│                 │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│                 │    │ │  hostapd    │ │    │ │   GPIO      │ │
│                 │    │ │  dnsmasq    │ │    │ │  Control    │ │
│                 │    │ │  iptables   │ │    │ └─────────────┘ │
│                 │    │ └─────────────┘ │    └─────────────────┘
└─────────────────┘    └─────────────────┘
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

## 🚀 Installation

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
pip install -r backend/requirements.txt
```

### Step 4: Initialize Database
```bash
python3 setup/init_db.py
```

### Step 5: Test GPIO Connections
```bash
python3 tests/gpio_test.py
```

### Step 6: Configure Captive Portal
Follow the detailed instructions in `captive_portal/README.md`

### Step 7: Start the Application
```bash
# Manual start
python3 backend/main.py

# Or use the startup script
sudo /usr/local/bin/start-muon-telescope.sh
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
   - Username: `admin`
   - Password: `admin`

### Controlling the Motor

1. **Set Direction**: Choose clockwise or counter-clockwise
2. **Enter Angle**: Specify degrees (0.1 to 360)
3. **Start Movement**: Click "Start Movement"
4. **Monitor Status**: Watch real-time position updates
5. **Stop if Needed**: Use "Stop Motor" button

## 📁 Project Structure

```
muon-telescope-project/
├── backend/                 # FastAPI backend
│   ├── main.py             # Main application
│   ├── motor_control.py    # GPIO motor control
│   ├── auth.py             # Authentication
│   ├── db.py               # Database operations
│   └── requirements.txt    # Python dependencies
├── frontend/               # Web interface
│   ├── templates/          # HTML templates
│   │   ├── login.html
│   │   └── control.html
│   └── static/             # CSS/JS files
│       ├── style.css
│       └── script.js
├── captive_portal/         # Network configuration
│   └── README.md          # Setup instructions
├── setup/                  # Setup scripts
│   └── init_db.py         # Database initialization
├── tests/                  # Test scripts
│   └── gpio_test.py       # GPIO test script
└── README.md              # This file
```

## 🔧 Configuration

### Motor Parameters
Edit `backend/motor_control.py` to adjust:
- `STEPS_PER_REVOLUTION`: Motor steps per revolution (default: 200)
- `MICROSTEPS`: Driver microstepping (default: 16)
- `PULSE_WIDTH`: Step pulse width (default: 1ms)

### Network Settings
Edit captive portal configuration:
- Wi-Fi SSID: `/etc/hostapd/hostapd.conf`
- IP range: `/etc/dnsmasq.conf`
- Port: `backend/main.py` and iptables rules

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
# Check FastAPI status
curl http://192.168.4.1:8000/health

# Check iptables rules
sudo iptables -t nat -L -n -v
```

**Database errors:**
```bash
# Reinitialize database
python3 setup/init_db.py

# Check file permissions
ls -la muon_telescope.db
```

### Logs and Debugging

**View application logs:**
```bash
# FastAPI logs
tail -f backend/logs/app.log

# System logs
sudo journalctl -f
```

**Reset everything:**
```bash
# Stop all services
sudo systemctl stop hostapd dnsmasq

# Clear iptables
sudo iptables -F
sudo iptables -t nat -F

# Restart
sudo /usr/local/bin/start-muon-telescope.sh
```

## 🔒 Security Considerations

1. **Change Default Passwords**:
   - Web interface: admin/admin
   - Wi-Fi: muon123456

2. **Network Security**:
   - Consider disabling internet access
   - Use stronger Wi-Fi encryption
   - Implement rate limiting

3. **Physical Security**:
   - Secure the Raspberry Pi
   - Protect GPIO connections
   - Use proper power supplies

## 📚 API Documentation

### Endpoints

- `GET /` - Redirect to login
- `GET /login` - Login page
- `POST /login` - Authenticate user
- `GET /control` - Motor control page
- `GET /logout` - Logout user

### API Endpoints

- `GET /api/status` - Get motor status
- `POST /api/motor/move` - Move motor
- `POST /api/motor/stop` - Stop motor
- `POST /api/motor/reset` - Reset position
- `GET /api/logs` - Get movement logs
- `GET /health` - Health check

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Raspberry Pi Foundation for the hardware platform
- FastAPI team for the web framework
- DM556 stepper driver manufacturers
- Open source community for various libraries

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs
3. Test with the GPIO test script
4. Open an issue on GitHub

---

**Happy Muon Hunting! 🔬✨** 