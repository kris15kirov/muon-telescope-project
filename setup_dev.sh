#!/bin/bash

# Development Setup Script for Muon Telescope
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

echo "🔧 Muon Telescope Development Setup"
echo "=================================="
echo ""

if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    print_status "Raspberry Pi detected - using production requirements"
    REQUIREMENTS_FILE="backend/requirements.txt"
else
    print_warning "Non-Raspberry Pi system detected - using development requirements"
    REQUIREMENTS_FILE="backend/requirements-dev.txt"
fi

print_status "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

print_status "Upgrading pip..."
pip install --upgrade pip

print_status "Installing Python dependencies..."
pip install -r $REQUIREMENTS_FILE

print_status "Initializing database..."
python setup/init_db.py

print_success "Development environment setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Activate virtual environment: source venv/bin/activate"
echo "2. Run the application: python backend/main.py"
echo "3. Access web interface: http://localhost:8000"
echo "4. Login with: admin / admin"
echo ""
print_warning "Note: GPIO functionality will be mocked on non-Raspberry Pi systems"
echo "" 