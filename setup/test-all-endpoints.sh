#!/bin/bash

# Comprehensive endpoint testing script
# Tests all GET and POST endpoints for the Muon Telescope API

BASE_URL="https://192.168.100.36"
LOG_FILE="/tmp/endpoint-test.log"

echo "=== Muon Telescope API Endpoint Test ===" | tee "$LOG_FILE"
echo "Timestamp: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Function to test an endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo "Testing: $description" | tee -a "$LOG_FILE"
    echo "Endpoint: $method $endpoint" | tee -a "$LOG_FILE"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -k -s -w "%{http_code}" "$BASE_URL$endpoint")
        http_code="${response: -3}"
        body="${response%???}"
    else
        response=$(curl -k -s -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$data" "$BASE_URL$endpoint")
        http_code="${response: -3}"
        body="${response%???}"
    fi
    
    if [ "$http_code" = "200" ]; then
        echo "✅ SUCCESS ($http_code)" | tee -a "$LOG_FILE"
        echo "Response: $body" | tee -a "$LOG_FILE"
    else
        echo "❌ FAILED ($http_code)" | tee -a "$LOG_FILE"
        echo "Response: $body" | tee -a "$LOG_FILE"
    fi
    echo "" | tee -a "$LOG_FILE"
}

# Test GET endpoints
echo "=== GET Endpoints ===" | tee -a "$LOG_FILE"
test_endpoint "GET" "/api/health/" "" "Health Check"
test_endpoint "GET" "/api/status/" "" "Motor Status"
test_endpoint "GET" "/api/logs/" "" "Movement Logs"

# Test POST endpoints
echo "=== POST Endpoints ===" | tee -a "$LOG_FILE"
test_endpoint "POST" "/api/motor/move/" '{"direction": "forward", "steps": 10}' "Move Motor"
test_endpoint "POST" "/api/motor/stop/" "" "Stop Motor"
test_endpoint "POST" "/api/motor/reset/" "" "Reset Position"
test_endpoint "POST" "/api/goto_angle/" '{"angle": 45}' "Go To Angle"
test_endpoint "POST" "/api/set_zero_position/" '{"position": 0}' "Set Zero Position"
test_endpoint "POST" "/api/enable_stepper/" "" "Enable Stepper"
test_endpoint "POST" "/api/disable_stepper/" "" "Disable Stepper"
test_endpoint "POST" "/api/set_direction/" '{"direction": "forward"}' "Set Direction"
test_endpoint "POST" "/api/set_step_period/" '{"period": 1000}' "Set Step Period"
test_endpoint "POST" "/api/do_steps/" '{"steps": 5}' "Do Steps"
test_endpoint "POST" "/api/do_steps_pwm/" '{"steps": 5}' "Do Steps PWM"
test_endpoint "POST" "/api/pause_motor/" "" "Pause Motor"
test_endpoint "POST" "/api/resume_motor/" "" "Resume Motor"
test_endpoint "POST" "/api/quit_motor/" "" "Quit Motor"

# Test web interface endpoints
echo "=== Web Interface Endpoints ===" | tee -a "$LOG_FILE"
test_endpoint "GET" "/login/" "" "Login Page"
test_endpoint "GET" "/control/" "" "Control Page"
test_endpoint "GET" "/register/" "" "Register Page"

echo "=== Test Complete ===" | tee -a "$LOG_FILE"
echo "Full log saved to: $LOG_FILE" 