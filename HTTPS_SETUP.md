# 🔐 HTTPS Setup Guide for Muon Telescope

This guide explains how to enable HTTPS for your Muon Telescope project on Raspberry Pi.

## 📋 Overview

Your project stack is **fully compatible** with HTTPS:

- ✅ **Raspberry Pi OS 32-bit**: Excellent HTTPS support with OpenSSL
- ✅ **Django 4.2.23**: Built-in HTTPS security features
- ✅ **Nginx**: Excellent SSL/TLS reverse proxy support
- ✅ **SSL Certificates**: Self-signed and CA certificates supported

## 🚀 Quick Setup

### Automated HTTPS Enablement

```bash
# On your Raspberry Pi, run:
sudo bash /home/pi/muon-telescope-project/setup/enable_https.sh
```

This single command will:
1. Generate SSL certificate
2. Install and configure Nginx
3. Update iptables for HTTPS
4. Configure Django for production
5. Create systemd service
6. Enable HTTPS for your application

### Verify HTTPS Setup

```bash
# Verify everything is working:
bash /home/pi/muon-telescope-project/setup/verify_https.sh
```

## 🔧 Manual Setup Steps

### Step 1: Generate SSL Certificate

```bash
# Generate self-signed certificate
sudo bash /home/pi/muon-telescope-project/setup/generate_ssl_cert.sh
```

**What this does:**
- Creates `/etc/ssl/muon-telescope/` directory
- Generates 2048-bit RSA private key
- Creates self-signed certificate valid for 1 year
- Sets proper file permissions (600 for key, 644 for cert)

### Step 2: Install and Configure Nginx

```bash
# Install Nginx with HTTPS configuration
sudo bash /home/pi/muon-telescope-project/setup/install_nginx.sh
```

**What this does:**
- Installs Nginx from package manager
- Creates HTTPS configuration with:
  - HTTP to HTTPS redirect
  - SSL/TLS 1.2 and 1.3 support
  - Security headers (HSTS, X-Frame-Options, etc.)
  - Reverse proxy to Django on port 8000
  - Static file serving
- Enables the site and starts Nginx

### Step 3: Update iptables for HTTPS

```bash
# Update firewall rules for HTTPS
sudo bash /home/pi/muon-telescope-project/setup/update_iptables_https.sh
```

**What this does:**
- Allows traffic on ports 80, 443, and 8000
- Configures NAT for internet access
- Sets up proper forwarding rules

### Step 4: Configure Django for Production

The Django settings have been updated to support HTTPS:

```python
# Security settings for production
if not DEBUG:
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_SSL_REDIRECT = True
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
```

## 🌐 Accessing Your Application

### URLs
- **HTTPS**: `https://192.168.4.1`
- **HTTP**: `http://192.168.4.1` (redirects to HTTPS)

### Browser Behavior
- **Self-signed certificate warning**: Normal for development
- **Click "Advanced" → "Proceed to 192.168.4.1 (unsafe)"**
- **For production**: Use CA-signed certificate

## 🔍 Verification Commands

### Check SSL Certificate
```bash
# View certificate details
openssl x509 -in /etc/ssl/muon-telescope/muon-telescope.crt -noout -text

# Check certificate validity
openssl x509 -in /etc/ssl/muon-telescope/muon-telescope.crt -noout -dates
```

### Test HTTPS Connection
```bash
# Test with curl (ignore certificate warnings)
curl -k https://192.168.4.1

# Test with openssl
openssl s_client -connect 192.168.4.1:443 -servername 192.168.4.1
```

### Check Services
```bash
# Check Nginx status
sudo systemctl status nginx

# Check Django application
sudo systemctl status muon-telescope-https.service

# View logs
sudo journalctl -u nginx -f
sudo journalctl -u muon-telescope-https.service -f
```

## 🔒 Security Features

### SSL/TLS Configuration
- **Protocols**: TLS 1.2 and 1.3 only
- **Ciphers**: Strong cipher suite (ECDHE-RSA-AES256-GCM-SHA512)
- **DH Parameters**: 2048-bit Diffie-Hellman parameters
- **Session Cache**: 10-minute SSL session cache

### Security Headers
- **HSTS**: Strict-Transport-Security header
- **X-Frame-Options**: DENY (prevents clickjacking)
- **X-Content-Type-Options**: nosniff
- **X-XSS-Protection**: 1; mode=block

### Django Security
- **Secure Cookies**: Session and CSRF cookies only over HTTPS
- **SSL Redirect**: Automatic HTTP to HTTPS redirect
- **HSTS**: HTTP Strict Transport Security

## 🚨 Troubleshooting

### Common Issues

**1. Nginx won't start:**
```bash
# Check configuration
sudo nginx -t

# View error logs
sudo tail -f /var/log/nginx/error.log
```

**2. Certificate errors:**
```bash
# Regenerate certificate
sudo bash /home/pi/muon-telescope-project/setup/generate_ssl_cert.sh

# Restart Nginx
sudo systemctl restart nginx
```

**3. Django not accessible:**
```bash
# Check if Django is running
ps aux | grep manage.py

# Start Django manually
cd /home/pi/muon-telescope-project
source venv/bin/activate
python3 manage.py runserver 127.0.0.1:8000
```

**4. Port 443 not listening:**
```bash
# Check if Nginx is listening
sudo netstat -tlnp | grep :443

# Check iptables
sudo iptables -L -n | grep 443
```

### Log Locations
- **Nginx access logs**: `/var/log/nginx/access.log`
- **Nginx error logs**: `/var/log/nginx/error.log`
- **Django logs**: Check systemd journal
- **System logs**: `sudo journalctl -f`

## 🔄 Production Considerations

### For Public Access
1. **Use CA-signed certificate** (Let's Encrypt, etc.)
2. **Update ALLOWED_HOSTS** in Django settings
3. **Configure proper DNS** records
4. **Set up firewall** rules for external access
5. **Monitor logs** for security events

### Certificate Renewal
```bash
# For self-signed certificates (development)
sudo bash /home/pi/muon-telescope-project/setup/generate_ssl_cert.sh

# For CA-signed certificates (production)
# Use certbot or your CA's renewal process
```

### Performance Optimization
- **Enable gzip compression** in Nginx
- **Use HTTP/2** (already enabled)
- **Optimize static files** serving
- **Monitor resource usage** on Raspberry Pi

## 📊 Monitoring

### System Resources
```bash
# Check CPU and memory
htop

# Check disk space
df -h

# Check network connections
ss -tlnp
```

### Application Health
```bash
# Health check endpoint
curl -k https://192.168.4.1/health

# Check all services
sudo systemctl status nginx hostapd dnsmasq muon-telescope-https.service
```

## 🎉 Success Indicators

You'll know HTTPS is working when:

1. ✅ **Browser shows HTTPS** in address bar
2. ✅ **Certificate warning** appears (normal for self-signed)
3. ✅ **HTTP redirects** to HTTPS automatically
4. ✅ **All Django features** work normally
5. ✅ **Static files** load correctly
6. ✅ **API endpoints** respond over HTTPS

## 📞 Support

If you encounter issues:
1. Run the verification script: `bash setup/verify_https.sh`
2. Check service logs: `sudo journalctl -f`
3. Test connectivity: `curl -k https://192.168.4.1`
4. Review this documentation for troubleshooting steps

---

**🔐 Your Muon Telescope now supports secure HTTPS connections!** 