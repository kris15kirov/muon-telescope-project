# 🔧 Development Setup Guide

This guide helps you set up the development environment and resolve import issues.

## 🐍 Python Environment Setup

### Option 1: Virtual Environment (Recommended)

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On Linux/Mac:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate

# Install dependencies
pip install -r backend/requirements.txt
```

### Option 2: Global Installation

```bash
# Install dependencies globally
pip3 install -r backend/requirements.txt
```

## 🔍 Resolving Import Issues

### Common Import Errors

**FastAPI not found:**
```bash
pip install fastapi uvicorn
```

**RPi.GPIO not found (on non-Raspberry Pi):**
```bash
# For development on non-Raspberry Pi systems
pip install RPi.GPIO
# Or comment out RPi.GPIO in requirements.txt for development
```

**Other missing imports:**
```bash
# Install all dependencies
pip install -r backend/requirements.txt

# Or install individually
pip install fastapi uvicorn python-multipart passlib jinja2 python-dotenv
```

### Development vs Production

**For Development (non-Raspberry Pi):**
```bash
# Comment out RPi.GPIO in requirements.txt
# pip install fastapi uvicorn python-multipart passlib jinja2 python-dotenv
```

**For Production (Raspberry Pi):**
```bash
# Install all dependencies including RPi.GPIO
pip install -r backend/requirements.txt
```

## 🛠️ IDE Configuration

### VS Code Setup

1. **Select Python Interpreter:**
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Python: Select Interpreter"
   - Choose your virtual environment

2. **Install Python Extension:**
   - Install the Python extension for VS Code
   - This provides better IntelliSense and error detection

3. **Configure Settings:**
   Create `.vscode/settings.json`:
   ```json
   {
       "python.defaultInterpreterPath": "./venv/bin/python",
       "python.linting.enabled": true,
       "python.linting.pylintEnabled": false,
       "python.linting.flake8Enabled": true
   }
   ```

### PyCharm Setup

1. **Create New Project:**
   - File → New Project
   - Choose "New environment using Virtualenv"
   - Set Python version to 3.11+

2. **Install Dependencies:**
   - File → Settings → Project → Python Interpreter
   - Click the gear icon → Install
   - Install packages from `requirements.txt`

## 🧪 Testing Without Hardware

### Mock GPIO for Development

Create `backend/mock_gpio.py` for development:

```python
"""
Mock GPIO module for development on non-Raspberry Pi systems.
"""

import time
import logging

class MockGPIO:
    BCM = "BCM"
    OUT = "OUT"
    HIGH = True
    LOW = False
    
    def __init__(self):
        self.pins = {}
        self.mode = None
        logging.info("Mock GPIO initialized")
    
    def setmode(self, mode):
        self.mode = mode
        logging.info(f"GPIO mode set to {mode}")
    
    def setup(self, pin, mode):
        self.pins[pin] = mode
        logging.info(f"GPIO pin {pin} set to {mode}")
    
    def output(self, pin, value):
        self.pins[pin] = value
        logging.info(f"GPIO pin {pin} set to {value}")
    
    def cleanup(self):
        self.pins.clear()
        logging.info("Mock GPIO cleanup")

# Replace RPi.GPIO with mock for development
try:
    import RPi.GPIO as GPIO
except ImportError:
    print("RPi.GPIO not available, using mock GPIO")
    GPIO = MockGPIO()
```

### Update motor_control.py for Development

Add this at the top of `backend/motor_control.py`:

```python
# Development fallback for GPIO
try:
    import RPi.GPIO as GPIO
except ImportError:
    print("Warning: RPi.GPIO not available. Using mock GPIO for development.")
    # Import mock GPIO here if needed
    # from .mock_gpio import MockGPIO as GPIO
```

## 🚀 Running the Application

### Development Mode

```bash
# Activate virtual environment
source venv/bin/activate

# Run the application
python backend/main.py
```

### Production Mode

```bash
# On Raspberry Pi
sudo /usr/local/bin/start-muon-telescope.sh
```

## 🔧 Troubleshooting

### Import Errors

**"No module named 'fastapi'":**
```bash
pip install fastapi uvicorn
```

**"No module named 'RPi'":**
```bash
# On Raspberry Pi:
sudo apt install python3-rpi.gpio
pip install RPi.GPIO

# On other systems (development):
# Use mock GPIO or comment out RPi.GPIO usage
```

**"No module named 'passlib'":**
```bash
pip install passlib[bcrypt]
```

### Linter Issues

**Pyright/Pylance errors:**
1. Make sure you're using the correct Python interpreter
2. Install missing packages: `pip install <package-name>`
3. Restart your IDE/editor

**Type checking errors:**
```bash
# Install type stubs
pip install types-requests types-urllib3
```

## 📁 Project Structure for Development

```
muon-telescope-project/
├── backend/
│   ├── main.py              # FastAPI app
│   ├── motor_control.py     # GPIO control
│   ├── auth.py              # Authentication
│   ├── db.py                # Database
│   ├── requirements.txt     # Dependencies
│   └── mock_gpio.py        # Development mock
├── frontend/
│   ├── templates/           # HTML templates
│   └── static/              # CSS/JS files
├── tests/
│   └── gpio_test.py        # GPIO test
├── setup/
│   ├── install.sh          # Installation script
│   └── init_db.py          # DB init
├── venv/                   # Virtual environment
└── README.md              # Main documentation
```

## 🎯 Development Workflow

1. **Setup Environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r backend/requirements.txt
   ```

2. **Initialize Database:**
   ```bash
   python setup/init_db.py
   ```

3. **Run Application:**
   ```bash
   python backend/main.py
   ```

4. **Test GPIO (on Raspberry Pi):**
   ```bash
   python tests/gpio_test.py
   ```

5. **Access Web Interface:**
   - Open browser to `http://localhost:8000`
   - Login with admin/admin

## 🔒 Security Notes

- Change default passwords in production
- Use HTTPS in production environments
- Secure the Raspberry Pi physically
- Update system packages regularly

## 📞 Getting Help

If you encounter issues:

1. **Check Dependencies:**
   ```bash
   pip list
   ```

2. **Verify Python Version:**
   ```bash
   python --version
   ```

3. **Check Virtual Environment:**
   ```bash
   which python
   ```

4. **Review Logs:**
   ```bash
   tail -f backend/logs/app.log
   ```

5. **Test Individual Components:**
   ```bash
   python -c "import fastapi; print('FastAPI OK')"
   python -c "import RPi.GPIO; print('GPIO OK')"
   ```

---

**Happy Coding! 🚀** 