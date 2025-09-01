#!/usr/bin/env python3
"""
Database initialization script for Muon Telescope application.
Creates the database and admin user with hashed password.
"""

import sys
import os
import logging
from db import db  # type: ignore

# Add the backend directory to the Python path
backend_path = os.path.join(os.path.dirname(__file__), "..", "backend")
sys.path.insert(0, backend_path)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def init_database():
    """Initialize the database and create admin user."""
    try:
        logger.info("Initializing Muon Telescope database...")

        # The database is automatically initialized when the Database class is instantiated
        # This happens in the db.py module when we import it

        # Create admin user
        admin_username = "admin"
        admin_password = "admin"  # Change this in production!

        success = db.create_admin_user(admin_username, admin_password)

        if success:
            logger.info(f"✅ Admin user '{admin_username}' created successfully")
            logger.info("📝 Default credentials: admin/admin")
            logger.warning("⚠️  IMPORTANT: Change the default password in production!")
        else:
            logger.warning(f"⚠️  Admin user '{admin_username}' already exists")

        logger.info("✅ Database initialization complete")
        return True

    except Exception as e:
        logger.error(f"❌ Error initializing database: {e}")
        return False


def main():
    """Main function."""
    print("🔬 Muon Telescope Database Initialization")
    print("=" * 50)

    if init_database():
        print("\n✅ Database setup completed successfully!")
        print("\n📋 Next steps:")
        print("1. Install Python dependencies: pip install -r backend/requirements.txt")
        print("2. Test GPIO connections: python tests/gpio_test.py")
        print("3. Start the web server: python backend/main.py")
        print("4. Configure university WiFi connection")
        print("\n🌐 Access the web interface at: http://[PI_IP]:8000")
        print("👤 Login with: admin / admin")
    else:
        print("\n❌ Database setup failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
