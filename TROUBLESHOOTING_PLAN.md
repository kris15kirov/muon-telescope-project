# Muon Telescope Troubleshooting Plan

## Current Issues Identified

### 1. Power Issues
- **Problem**: Raspberry Pi powers off unexpectedly
- **Symptoms**: SSH connection lost, ping fails, system unreachable
- **Impact**: Interrupts development and testing

### 2. API Endpoint Issues
- **Problem**: POST endpoints returning 502 Bad Gateway
- **Symptoms**: GET endpoints work, POST endpoints fail
- **Root Cause**: Django service likely crashed or stopped

## Solution Steps

### Phase 1: Power Issue Resolution

#### 1.1 Hardware Diagnostics
```bash
# Check power supply voltage
vcgencmd measure_volts

# Check temperature
vcgencmd measure_temp

# Check power consumption
vcgencmd get_throttled

# Check kernel messages for power issues
dmesg | grep -i "power\|voltage\|throttle"
```

#### 1.2 Power Supply Solutions
- **Option A**: Use official Raspberry Pi power supply (5V/3A)
- **Option B**: Check USB cable quality (some cables don't provide enough power)
- **Option C**: Add power monitoring script

#### 1.3 Power Monitoring Script
Create `/usr/local/bin/monitor-power.sh`:
```bash
#!/bin/bash
while true; do
    voltage=$(vcgencmd measure_volts | cut -d'=' -f2 | cut -d'V' -f1)
    temp=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
    throttled=$(vcgencmd get_throttled)
    
    echo "$(date): Voltage=$voltage V, Temp=${temp}°C, Throttled=$throttled"
    
    # Alert if voltage is low
    if (( $(echo "$voltage < 4.8" | bc -l) )); then
        echo "WARNING: Low voltage detected: $voltage V"
    fi
    
    sleep 30
done
```

### Phase 2: Service Recovery

#### 2.1 Django Service Fix
```bash
# Check service status
sudo systemctl status muon-telescope-dev.service

# View service logs
sudo journalctl -u muon-telescope-dev.service -f

# Restart service
sudo systemctl restart muon-telescope-dev.service

# Enable auto-restart
sudo systemctl enable muon-telescope-dev.service
```

#### 2.2 Nginx Configuration Check
```bash
# Test nginx configuration
sudo nginx -t

# Check nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Phase 3: API Endpoint Testing

#### 3.1 Comprehensive Endpoint Test
```bash
# Test all GET endpoints
curl -k https://192.168.100.36/api/health/
curl -k https://192.168.100.36/api/status/
curl -k https://192.168.100.36/api/logs/

# Test all POST endpoints
curl -k -X POST -H "Content-Type: application/json" -d '{"direction": "forward", "steps": 10}' https://192.168.100.36/api/motor/move/
curl -k -X POST https://192.168.100.36/api/motor/stop/
curl -k -X POST -H "Content-Type: application/json" -d '{"position": 0}' https://192.168.100.36/api/set_zero_position/
curl -k -X POST https://192.168.100.36/api/pause_motor/
curl -k -X POST https://192.168.100.36/api/resume_motor/
```

### Phase 4: Prevention Measures

#### 4.1 Auto-Recovery Script
Create `/usr/local/bin/auto-recovery.sh`:
```bash
#!/bin/bash
# Check if Django service is running
if ! systemctl is-active --quiet muon-telescope-dev.service; then
    echo "$(date): Django service down, restarting..."
    sudo systemctl restart muon-telescope-dev.service
fi

# Check if nginx is running
if ! systemctl is-active --quiet nginx; then
    echo "$(date): Nginx down, restarting..."
    sudo systemctl restart nginx
fi
```

#### 4.2 Crontab Setup
```bash
# Add to crontab for regular checks
*/5 * * * * /usr/local/bin/auto-recovery.sh
```

## Immediate Actions Needed

1. **Wait for Pi to come back online**
2. **Check power supply and connections**
3. **Restart Django service**
4. **Test all endpoints**
5. **Implement monitoring scripts**

## Success Criteria

- [ ] Pi stays online for >24 hours
- [ ] All GET endpoints return 200 OK
- [ ] All POST endpoints return 200 OK
- [ ] No 502 Bad Gateway errors
- [ ] Services auto-restart if they crash 