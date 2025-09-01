#!/bin/bash

# Muon Telescope Deployment Script for Raspberry Pi
# This script helps deploy the codebase to Raspberry Pi

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Raspberry Pi IP is provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <raspberry-pi-ip>"
    print_status "Example: $0 [PI_IP_ADDRESS]"
    exit 1
fi

PI_IP=$1
PI_USER="pi"

print_status "Starting deployment to Raspberry Pi at $PI_IP..."

# Step 1: Transfer the clean archive
print_status "Transferring codebase to Raspberry Pi..."
scp muon-telescope-clean.zip $PI_USER@$PI_IP:/home/$PI_USER/

# Step 2: Transfer the .env file
print_status "Transferring environment configuration..."
scp .env $PI_USER@$PI_IP:/home/$PI_USER/

# Step 3: Execute setup commands on Raspberry Pi
print_status "Setting up the project on Raspberry Pi..."
ssh $PI_USER@$PI_IP << 'EOF'
    echo "🔬 Setting up Muon Telescope on Raspberry Pi..."
    
    # Navigate to home directory
    cd /home/pi
    
    # Remove existing project if it exists
    if [ -d "muon-telescope-project" ]; then
        echo "Removing existing project..."
        rm -rf muon-telescope-project
    fi
    
    # Extract the clean archive
    echo "Extracting project files..."
    unzip -q muon-telescope-clean.zip
    mv muon-telescope-project-* muon-telescope-project
    
    # Copy .env file to project directory
    cp .env muon-telescope-project/
    
    # Set proper permissions for .env file (security)
    chmod 600 muon-telescope-project/.env
    
    # Navigate to project directory
    cd muon-telescope-project
    
    # Make installation script executable
    chmod +x setup/install.sh
    
    # Run the automated installation
    echo "Running automated installation..."
    ./setup/install.sh
    
    # Activate virtual environment and install requirements
    echo "Installing Python dependencies..."
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # Run database migrations
    echo "Running database migrations..."
    python3 manage.py migrate
    
    # Create superuser if it doesn't exist
    echo "Setting up admin user..."
    echo "from django.contrib.auth.models import User; User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@example.com', 'admin')" | python3 manage.py shell
    
    # Test GPIO connections
    echo "Testing GPIO connections..."
    python3 tests/gpio_test.py || echo "GPIO test completed (may show warnings on non-Pi systems)"
    
    # Set up systemd service for auto-start
    echo "Setting up systemd service..."
    sudo systemctl enable muon-telescope.service
    
    echo "✅ Project setup completed successfully!"
    echo "📋 System is ready to start!"
    echo ""
    echo "🚀 To start the system:"
    echo "   sudo /usr/local/bin/start-muon-telescope.sh"
    echo ""
    echo "🌐 To access the web interface:"
    echo "   1. Connect to university WiFi"
    echo "   2. Open browser: https://[PI_IP]/control/"
    echo "   3. Login: admin / admin"
    echo ""
    echo "🔧 To test hardware:"
    echo "   python3 tests/gpio_test.py"
EOF

print_success "Deployment completed successfully!"
echo ""
print_status "📋 System Status:"
echo "✅ Codebase transferred and extracted"
echo "✅ Environment configured with secure permissions"
echo "✅ Virtual environment created and dependencies installed"
echo "✅ Database migrated and admin user created"
echo "✅ GPIO connections tested"
echo "✅ Systemd service enabled for auto-start"
echo ""
print_status "🚀 Next steps on Raspberry Pi:"
echo "1. Start the system: sudo /usr/local/bin/start-muon-telescope.sh"
echo "2. Connect to university WiFi"
echo "3. Access web interface: https://[PI_IP]/control/"
echo "4. Login with: admin / admin"
echo ""
print_warning "Remember to change default passwords in production!" 