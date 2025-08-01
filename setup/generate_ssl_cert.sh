#!/bin/bash

# SSL Certificate Generation Script for Muon Telescope
# This script generates a self-signed SSL certificate for local development/testing

set -e

echo "🔐 Generating SSL Certificate for Muon Telescope..."

# Create SSL directory
sudo mkdir -p /etc/ssl/muon-telescope
cd /etc/ssl/muon-telescope

# Generate private key
echo "📝 Generating private key..."
sudo openssl genrsa -out muon-telescope.key 2048

# Generate certificate signing request
echo "📋 Generating certificate signing request..."
sudo openssl req -new -key muon-telescope.key -out muon-telescope.csr -subj "/C=US/ST=State/L=City/O=Muon Telescope/CN=192.168.4.1"

# Generate self-signed certificate (valid for 1 year)
echo "🎫 Generating self-signed certificate..."
sudo openssl x509 -req -days 365 -in muon-telescope.csr -signkey muon-telescope.key -out muon-telescope.crt

# Set proper permissions
sudo chmod 600 muon-telescope.key
sudo chmod 644 muon-telescope.crt

echo "✅ SSL Certificate generated successfully!"
echo "📁 Certificate location: /etc/ssl/muon-telescope/"
echo "🔑 Private key: muon-telescope.key"
echo "🎫 Certificate: muon-telescope.crt"

# Optional: Generate DH parameters for stronger security
echo "🔒 Generating DH parameters (this may take a few minutes)..."
sudo openssl dhparam -out dhparam.pem 2048

echo "🎉 SSL setup complete!" 