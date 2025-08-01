#!/bin/bash

# Fix Django Environment and Complete HTTPS Setup
# This script fixes the virtual environment issue and completes the HTTPS setup

set -e

echo "🔧 Fixing Django environment and completing HTTPS setup..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Navigate to project directory
cd /home/pi/muon-telescope-project

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Creating one..."
    python3 -m venv venv
fi

# Activate virtual environment and install dependencies
echo "📦 Activating virtual environment and installing dependencies..."
source venv/bin/activate
pip install -r requirements.txt

# Set development environment
export DJANGO_DEBUG=True

# Collect static files
echo "📦 Collecting static files..."
python3 manage.py collectstatic --noinput

# Run migrations
echo "🗄️ Running database migrations..."
python3 manage.py migrate

# Create admin user if it doesn't exist
echo "👤 Creating admin user..."
python3 manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
    print('Admin user created: admin/admin')
else:
    print('Admin user already exists')
"

echo "✅ Django environment fixed!"
echo ""
echo "🚀 To start the system:"
echo "   sudo systemctl start muon-telescope-dev.service"
echo ""
echo "🔍 To test manually:"
echo "   # Terminal 1: Start Django"
echo "   cd /home/pi/muon-telescope-project"
echo "   source venv/bin/activate"
echo "   python3 manage.py runserver 127.0.0.1:8000"
echo ""
echo "   # Terminal 2: Test HTTPS"
echo "   curl -k https://127.0.0.1" 