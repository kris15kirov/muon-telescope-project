#!/bin/bash

echo "🔧 Updating admin email..."

# Activate virtual environment
source venv/bin/activate

# Use Django shell to update email
python3 manage.py shell << EOF
from django.contrib.auth.models import User
try:
    admin_user = User.objects.get(username='admin')
    print(f"Current email: {admin_user.email}")
    admin_user.email = 'admin@muon-telescope.local'
    admin_user.save()
    print(f"✅ Updated email to: {admin_user.email}")
except User.DoesNotExist:
    print("❌ Admin user not found")
    exit(1)
EOF

echo "✅ Admin email updated!"
echo "📧 New email: admin@muon-telescope.local" 