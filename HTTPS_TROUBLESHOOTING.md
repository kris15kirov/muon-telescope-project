# 🔧 HTTPS Troubleshooting Guide

This guide helps you resolve common HTTPS issues with your Muon Telescope project.

## 🚨 Common Issues & Solutions

### Issue 1: `ERR_CONNECTION_REFUSED` on `127.0.0.1`

**Symptoms:**
- Browser shows "ERR_CONNECTION_REFUSED"
- `curl -k https://127.0.0.1` fails
- Nginx is running but Django isn't accessible

**Root Cause:** Django is not running or not bound to the correct address.

**Solution:**

#### Step 1: Check Django Status
```bash
# Check if Django is running
ps aux | grep manage.py

# If not running, start it manually
cd /home/pi/muon-telescope-project
source venv/bin/activate
python3 manage.py runserver 127.0.0.1:8000
```

#### Step 2: Test Django Directly
```bash
# Test Django without Nginx
curl http://127.0.0.1:8000

# Should return Django response
```

#### Step 3: Check Nginx Configuration
```bash
# Test Nginx config
sudo nginx -t

# Check Nginx status
sudo systemctl status nginx

# View Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

#### Step 4: Verify Port Binding
```bash
# Check what's listening on port 8000
sudo netstat -tlnp | grep :8000

# Check what's listening on port 443
sudo netstat -tlnp | grep :443
```

### Issue 2: Certificate Errors

**Symptoms:**
- Browser shows certificate warnings
- `curl` fails with certificate errors

**Solution:**
```bash
# Regenerate certificate
sudo bash /home/pi/muon-telescope-project/setup/generate_ssl_cert.sh

# Restart Nginx
sudo systemctl restart nginx

# Test with curl (ignore certificate)
curl -k https://127.0.0.1
```

### Issue 3: Nginx Won't Start

**Symptoms:**
- `sudo systemctl start nginx` fails
- Configuration errors

**Solution:**
```bash
# Check configuration
sudo nginx -t

# View detailed errors
sudo journalctl -u nginx -f

# Check if port 443 is already in use
sudo lsof -i :443
```

### Issue 4: Django Not Starting

**Symptoms:**
- Django fails to start
- Import errors or missing dependencies

**Solution:**
```bash
# Activate virtual environment
cd /home/pi/muon-telescope-project
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python3 manage.py migrate

# Collect static files
python3 manage.py collectstatic --noinput

# Try starting Django
python3 manage.py runserver 127.0.0.1:8000
```

## 🔍 Diagnostic Commands

### Check All Services
```bash
# Check all relevant services
sudo systemctl status nginx
sudo systemctl status muon-telescope-https.service
sudo systemctl status muon-telescope-dev.service

# Check if Django is running
ps aux | grep manage.py
```

### Test Network Connectivity
```bash
# Test HTTP (should redirect to HTTPS)
curl -I http://127.0.0.1

# Test HTTPS (ignore certificate)
curl -k -I https://127.0.0.1

# Test Django directly
curl -I http://127.0.0.1:8000
```

### Check Logs
```bash
# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Django logs (if configured)
sudo journalctl -u muon-telescope-https.service -f
sudo journalctl -u muon-telescope-dev.service -f

# System logs
sudo journalctl -f
```

## 🛠️ Manual Testing Steps

### Step-by-Step Debugging

#### 1. Start Fresh
```bash
# Stop all services
sudo systemctl stop nginx
sudo systemctl stop muon-telescope-https.service
sudo systemctl stop muon-telescope-dev.service

# Kill any remaining Django processes
sudo pkill -f manage.py
```

#### 2. Start Django First
```bash
# Terminal 1: Start Django
cd /home/pi/muon-telescope-project
source venv/bin/activate
export DJANGO_DEBUG=True
python3 manage.py runserver 127.0.0.1:8000
```

#### 3. Test Django Directly
```bash
# Terminal 2: Test Django
curl http://127.0.0.1:8000
# Should return Django response
```

#### 4. Start Nginx
```bash
# Terminal 3: Start Nginx
sudo systemctl start nginx
sudo systemctl status nginx
```

#### 5. Test HTTPS
```bash
# Terminal 2: Test HTTPS
curl -k https://127.0.0.1
# Should return Django response through Nginx
```

## 🔧 Environment-Specific Solutions

### Development Environment
```bash
# Use development setup
sudo bash /home/pi/muon-telescope-project/setup/enable_https_dev.sh

# Start development service
sudo systemctl start muon-telescope-dev.service
```

### Production Environment
```bash
# Use production setup
sudo bash /home/pi/muon-telescope-project/setup/enable_https.sh

# Start production service
sudo systemctl start muon-telescope-https.service
```

## 📋 Checklist for Working HTTPS

- [ ] SSL certificate exists: `/etc/ssl/muon-telescope/muon-telescope.crt`
- [ ] Private key exists: `/etc/ssl/muon-telescope/muon-telescope.key`
- [ ] Nginx is running: `sudo systemctl status nginx`
- [ ] Nginx config is valid: `sudo nginx -t`
- [ ] Django is running: `ps aux | grep manage.py`
- [ ] Django responds on port 8000: `curl http://127.0.0.1:8000`
- [ ] HTTPS responds: `curl -k https://127.0.0.1`
- [ ] Port 443 is listening: `sudo netstat -tlnp | grep :443`

## 🚀 Quick Fix Commands

### Reset Everything
```bash
# Stop all services
sudo systemctl stop nginx muon-telescope-https.service muon-telescope-dev.service

# Kill Django processes
sudo pkill -f manage.py

# Regenerate certificate
sudo bash /home/pi/muon-telescope-project/setup/generate_ssl_cert.sh

# Restart Nginx
sudo systemctl restart nginx

# Start Django manually
cd /home/pi/muon-telescope-project
source venv/bin/activate
python3 manage.py runserver 127.0.0.1:8000
```

### Test Everything
```bash
# Run verification script
bash /home/pi/muon-telescope-project/setup/verify_https.sh
```

## 📞 Getting Help

If you're still having issues:

1. **Run the verification script**: `bash setup/verify_https.sh`
2. **Check all logs**: `sudo journalctl -f`
3. **Test step by step**: Follow the manual testing steps above
4. **Provide these details**:
   - Output of `sudo nginx -t`
   - Output of `ps aux | grep manage.py`
   - Output of `sudo netstat -tlnp | grep :443`
   - Error messages from logs

---

**🔧 This troubleshooting guide should resolve most HTTPS issues!** 