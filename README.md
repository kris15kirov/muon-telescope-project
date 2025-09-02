# 🔬 Computer-Controlled Muon Telescope via Web Interface

A complete Raspberry Pi-based system for controlling a stepper motor telescope via a web interface with secure authentication.

## 🌟 Features

- **Web Interface**: Modern, responsive UI for motor control
- **Authentication**: Secure login system with session management
- **Motor Control**: Precise stepper motor control via DM556 driver
- **Real-time Updates**: Live status updates (Angle, Counts per Second)
- **Advanced Controls**: Step frequency control, manual stepping, direction control
- **Network Access**: Works on university network for easy access


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
- Raspberry Pi 3B+
- DM556 stepper motor driver
- Stepper motor (DM556)
- Power supply for motor driver
- Jumper wires for GPIO connections

### Software
- Raspberry Pi OS (Debian-based)
- Python 3.11+
- Django 4.2+
- Nginx (web server)

## 🔧 Hardware Setup

**Power Requirements:**
- **Raspberry Pi:** 5V/3A via micro USB
- **DM556 Logic:** 3.3V from Pi (Pin 1 or 17)
- **Motor Power:** 24-48V external power supply
- **Ground:** Multiple GND connections (Pin 6, 30, 34)

### GPIO Connections

| Raspberry Pi | DM556 Driver | Description |
|--------------|--------------|-------------|
| GPIO 17 (Pin 11) | EN+          | Enable (active low) |
| GPIO 27 (Pin 13) | DIR+         | Direction control |
| GPIO 22 (Pin 15) | PUL+         | Step pulse |
| 3.3V (Pin 1/17) | VCC           | Logic power supply |
| GND (Pin 6,30,34) | GND         | Common ground |
| External 24-48V | Motor Power   | Motor power supply |

### Wiring Diagram
```
Raspberry Pi 3B+    DM556 Driver
┌─────────────┐     ┌─────────────┐
│ GPIO 17 ────┼────►│ EN+         │ (Enable - Pin 11)
│ (Pin 11)    │     │             │
│ GPIO 27 ────┼────►│ DIR+        │ (Direction - Pin 13)
│ (Pin 13)    │     │             │
│ GPIO 22 ────┼────►│ PUL+        │ (Step - Pin 15)
│ (Pin 15)    │     │             │
│ 3.3V ───────┼────►│ VCC         │ (Logic power - Pin 1 or 17)
│ (Pin 1/17)  │     │             │
│ GND ────────┼────►│ GND         │ (Ground - Pin 6,30,34)
│ (Pin 6,30,34)│    │             │
└─────────────┘     └─────────────┘
                    │             │
                    │ 24-48V ─────┼──► Motor Power (External)
                    │ (External)  │
                    └─────────────┘
```

## 🚀 Installation

```bash
# Clone & setup
git clone <repository-url>
cd muon-telescope-project

# Install dependencies
sudo apt update && sudo apt install -y python3-pip python3-venv nginx
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# Initialize & start
python3 manage.py migrate
python3 manage.py createsuperuser
python3 manage.py runserver 0.0.0.0:8000
```

## 🌐 Usage

### Basic Controls
1. **Set Zero Position**: Reset motor reference point
2. **Go to Angle**: Use slider (-75° to +75°) for precise positioning
3. **Logout**: Secure session termination

### Advanced Controls (Admin Only)
1. **Enable/Disable Stepper**: Motor power control
2. **Direction Control**: Clockwise/Counter-clockwise
3. **Step Frequency**: Set motor speed (steps/second)
4. **Step Count**: Specify number of steps to move
5. **Execute Movement**: Run motor with current settings

### Network Access
- **University WiFi**: Use setup scripts in `setup/` directory
- **Access URL**: `https://[PI_IP]/control/`
- **Find IP**: Run `hostname -I` on Pi

## 📁 Project Structure

```
muon-telescope-project/
├── control/                 # Django app for motor control and UI
│   ├── views.py             # API endpoints and web views
│   ├── templates/           # HTML templates
│   └── urls.py              # URL routing
├── muon_telescope/          # Django project settings
│   ├── settings.py          # Project configuration
│   ├── motor_control.py     # GPIO motor control logic
│   └── wsgi.py              # WSGI application
├── frontend/                # Static assets (CSS, JS)
├── setup/                   # Setup and deployment scripts
├── tests/                   # Test scripts
└── requirements.txt         # Python dependencies
```

## 🔧 Configuration

### Motor Parameters
Edit `muon_telescope/motor_control.py`:
- `ENABLE_PIN`: GPIO 17 (Pin 11)
- `DIR_PIN`: GPIO 27 (Pin 13)  
- `STEP_PIN`: GPIO 22 (Pin 15)

### Network Settings
- Automatic university WiFi connection
- Dynamic IP address updates
- No manual configuration required

## 🧱 Software Stack

**🐍 Core Language:** Python 3.11+

**🔌 Hardware Control:** 
- RPi.GPIO (production) / MockGPIO (development)
- Threading for non-blocking motor operations

**🧠 Backend Framework:** 
- Django 4.2+ with SQLite3 database
- RESTful API endpoints for motor control
- Session-based authentication system

**🌐 Frontend:** 
- HTML5/CSS3 with vanilla JavaScript
- Django templates (Jinja2)
- Responsive design for mobile/desktop

**📶 Network & Security:** 
- Nginx reverse proxy with HTTPS
- University WiFi client mode
- CSRF protection and secure headers

**🔧 Development Tools:** 
- Flake8 linting and code formatting
- Pre-commit hooks for quality control
- Virtual environment management

## 🌍 Environment & Configuration

- **Environment Variables**: Store sensitive data in `.env` file
- **Database**: SQLite3 for user authentication and sessions
- **Static Files**: Served via Django/WhiteNoise
- **Logging**: In-memory movement logging (non-persistent)
- **Security**: Password hashing, session management, role-based access
