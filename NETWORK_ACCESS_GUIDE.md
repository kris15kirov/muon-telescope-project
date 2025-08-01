# 🌐 Network Access Guide for Muon Telescope

This guide explains how to access your Muon Telescope server from any WiFi network.

## 🚀 Quick Setup

### Step 1: Complete HTTPS Setup
```bash
# On your Raspberry Pi
sudo bash /home/pi/muon-telescope-project/setup/complete_https_setup.sh
```

### Step 2: Find Your Raspberry Pi's IP Address
```bash
# On your Raspberry Pi
hostname -I
# or
ip addr show wlan0
```

**Example output:** `192.168.1.100`

## 🌐 Accessing Your Server

### From Any Device on the Same WiFi:

1. **Open your web browser**
2. **Go to:** `https://<raspberry-pi-ip>`
3. **Example:** `https://192.168.1.100`

### Accept the Certificate Warning:
- Click **"Advanced"**
- Click **"Proceed to [IP] (unsafe)"**
- This is normal for self-signed certificates

## 📱 Access from Different Networks

### Home WiFi:
- **URL:** `https://192.168.1.100` (or whatever your Pi's IP is)
- **Works on:** All devices connected to your home WiFi

### University WiFi:
- **URL:** `https://192.168.1.100` (same IP)
- **Works on:** All devices connected to university WiFi

### Any Other WiFi:
- **URL:** `https://192.168.1.100` (same IP)
- **Works on:** All devices on that network

## 🔧 Troubleshooting

### If you can't access the server:

#### 1. Check if the server is running:
```bash
# On Raspberry Pi
sudo systemctl status muon-telescope-dev.service
```

#### 2. Check the IP address:
```bash
# On Raspberry Pi
hostname -I
```

#### 3. Test locally on the Pi:
```bash
# On Raspberry Pi
curl -k https://127.0.0.1
```

#### 4. Check if port 443 is open:
```bash
# On Raspberry Pi
sudo netstat -tlnp | grep :443
```

### If the IP address changes:

The IP address might change when you connect to different WiFi networks. To find the new IP:

```bash
# On Raspberry Pi
hostname -I
```

Then use the new IP address in your browser.

## 📋 Quick Commands

### Start the server:
```bash
sudo systemctl start muon-telescope-dev.service
```

### Stop the server:
```bash
sudo systemctl stop muon-telescope-dev.service
```

### Check status:
```bash
sudo systemctl status muon-telescope-dev.service
```

### View logs:
```bash
sudo journalctl -u muon-telescope-dev.service -f
```

## 🔒 Security Notes

- **Self-signed certificate:** You'll see a browser warning - this is normal
- **Local network only:** The server is only accessible on the same WiFi network
- **No internet access:** The server doesn't need internet to work
- **Admin login:** Username: `admin`, Password: `admin`

## 📱 Mobile Access

You can also access your server from your phone:

1. **Connect your phone to the same WiFi**
2. **Open your phone's browser**
3. **Go to:** `https://192.168.1.100`
4. **Accept the certificate warning**
5. **Login with:** admin/admin

## 🎯 Summary

1. **Run the setup script** on your Raspberry Pi
2. **Find the IP address** using `hostname -I`
3. **Access from any device** on the same WiFi using `https://<IP>`
4. **Login with:** admin/admin

That's it! Your Muon Telescope server will work on any WiFi network. 🎉 