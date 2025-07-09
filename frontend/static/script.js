// Muon Telescope Control System JavaScript

// Add debug flag and logError function at the top
const DEBUG = false;
function logError(...args) {
    if (DEBUG) console.error(...args);
}

class MotorController {
    constructor() {
        this.isMoving = false;
        this.updateInterval = null;
        this.init();
    }

    init() {
        this.bindEvents();
        this.startStatusUpdates();
        this.loadLogs();
    }

    bindEvents() {
        // Motor control form
        const motorForm = document.getElementById('motor-form');
        if (motorForm) {
            motorForm.addEventListener('submit', (e) => this.handleMoveMotor(e));
        }

        // Stop button
        const stopBtn = document.getElementById('stop-btn');
        if (stopBtn) {
            stopBtn.addEventListener('click', () => this.handleStopMotor());
        }

        // Reset button
        const resetBtn = document.getElementById('reset-btn');
        if (resetBtn) {
            resetBtn.addEventListener('click', () => this.handleResetPosition());
        }

        // Set Zero Position button
        const setZeroBtn = document.getElementById('set-zero-btn');
        if (setZeroBtn) {
            setZeroBtn.onclick = async function () {
                try {
                    const zero = parseInt(document.getElementById('zero-pos').value, 10);
                    if (isNaN(zero)) {
                        showMessage('Please enter a valid number for zero position.', 'error');
                        return;
                    }
                    const response = await fetch('/api/set_zero_position', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(zero)
                    });
                    if (response.ok) {
                        showMessage('Zero position set!');
                    } else {
                        const err = await response.text();
                        showMessage('Failed to set zero position. ' + err, 'error');
                        logError('422 or other error:', err);
                    }
                } catch (e) {
                    showMessage('Network or JS error: ' + e, 'error');
                    logError(e);
                }
            };
        }

        // Go to Angle button
        const gotoAngleBtn = document.getElementById('goto-angle-btn');
        if (gotoAngleBtn) {
            gotoAngleBtn.onclick = async function () {
                try {
                    const angle = parseFloat(document.getElementById('angle-slider').value);
                    if (isNaN(angle)) {
                        showMessage('Please select a valid angle.', 'error');
                        return;
                    }
                    const response = await fetch('/api/goto_angle', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ angle: angle })
                    });
                    if (response.ok) {
                        showMessage('Moving to angle...');
                    } else {
                        const err = await response.text();
                        showMessage('Failed to move to angle. ' + err, 'error');
                        logError('422 or other error:', err);
                    }
                } catch (e) {
                    showMessage('Network or JS error: ' + e, 'error');
                    logError(e);
                }
            };
        }

        // Robust Quit button (logout)

        // Angle slider value display
        const angleSlider = document.getElementById('angle-slider');
        const angleValue = document.getElementById('angle-value');
        if (angleSlider && angleValue) {
            angleSlider.addEventListener('input', function () {
                angleValue.textContent = this.value;
            });
        }

        // Advanced controls toggle (admin only)
        const advToggle = document.getElementById('advanced-toggle');
        const advControls = document.getElementById('advanced-controls');
        if (advToggle && advControls) {
            advToggle.addEventListener('change', function () {
                advControls.classList.toggle('active', this.checked);
            });
        }

        // Shutdown button (admin only)
        const shutdownBtn = document.getElementById('shutdown-btn');
        if (shutdownBtn) {
            shutdownBtn.onclick = async function () {
                if (confirm('Are you sure you want to shut down the Raspberry Pi?')) {
                    await fetch('/api/shutdown', { method: 'POST' });
                    showMessage('Shutdown command sent. The device will power off.');
                }
            };
        }

        // Advanced controls (admin only)
        const enableStepperBtn = document.getElementById('enable-stepper-btn');
        if (enableStepperBtn) {
            enableStepperBtn.onclick = async function () {
                try {
                    const response = await fetch('/api/enable_stepper', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({})
                    });
                    if (!response.ok) {
                        const err = await response.text();
                        showMessage('Failed to enable stepper. ' + err, 'error');
                    }
                } catch (e) {
                    showMessage('Network or JS error: ' + e, 'error');
                    logError(e);
                }
            };
        }
        const disableStepperBtn = document.getElementById('disable-stepper-btn');
        if (disableStepperBtn) {
            disableStepperBtn.onclick = async function () {
                try {
                    const response = await fetch('/api/disable_stepper', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({})
                    });
                    if (!response.ok) {
                        const err = await response.text();
                        showMessage('Failed to disable stepper. ' + err, 'error');
                    }
                } catch (e) {
                    showMessage('Network or JS error: ' + e, 'error');
                    logError(e);
                }
            };
        }
        const dirPlusBtn = document.getElementById('dir-plus-btn');
        if (!dirPlusBtn) {
            showMessage('Control button missing from page.', 'error');
        } else {
            dirPlusBtn.onclick = async function () {
                try {
                    const response = await fetch('/api/set_direction', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ direction: 'plus' })
                    });
                    if (!response.ok) {
                        const err = await response.text();
                        showMessage('Failed to set direction +. ' + err, 'error');
                    }
                } catch (e) {
                    showMessage('Network or JS error: ' + e, 'error');
                    logError(e);
                }
            };
        }
        const dirMinusBtn = document.getElementById('dir-minus-btn');
        if (dirMinusBtn) {
            dirMinusBtn.onclick = async function () {
                try {
                    const response = await fetch('/api/set_direction', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ direction: 'minus' })
                    });
                    if (!response.ok) {
                        const err = await response.text();
                        showMessage('Failed to set direction -. ' + err, 'error');
                    }
                } catch (e) {
                    showMessage('Network or JS error: ' + e, 'error');
                    logError(e);
                }
            };
        }
        const setStepPeriodBtn = document.getElementById('set-step-period-btn');
        if (setStepPeriodBtn) {
            setStepPeriodBtn.onclick = async function () {
                try {
                    const period = parseInt(document.getElementById('step-period').value, 10);
                    if (isNaN(period) || period < 1) {
                        showMessage('Please enter a valid step period.', 'error');
                        return;
                    }
                    const response = await fetch('/api/set_step_period', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ period_ms: period })
                    });
                    if (!response.ok) {
                        const err = await response.text();
                        showMessage('Failed to set step period. ' + err, 'error');
                    }
                } catch (e) {
                    showMessage('Network or JS error: ' + e, 'error');
                    logError(e);
                }
            };
        }
        const doStepsBtn = document.getElementById('do-steps-btn');
        if (doStepsBtn) {
            doStepsBtn.onclick = async function () {
                try {
                    const steps = parseInt(document.getElementById('step-count').value, 10);
                    if (isNaN(steps)) {
                        showMessage('Please enter a valid number of steps.', 'error');
                        return;
                    }
                    const response = await fetch('/api/do_steps', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ steps: steps })
                    });
                    if (!response.ok) {
                        const err = await response.text();
                        showMessage('Failed to do steps. ' + err, 'error');
                    }
                } catch (e) {
                    showMessage('Network or JS error: ' + e, 'error');
                    logError(e);
                }
            };
        }
    }

    async handleMoveMotor(e) {
        e.preventDefault();

        const formData = new FormData(e.target);
        const direction = formData.get('direction');
        const degrees = parseFloat(formData.get('degrees'));

        if (!degrees || degrees <= 0 || degrees > 360) {
            showMessage('Please enter a valid angle between 0 and 360 degrees', 'error');
            return;
        }

        const moveBtn = document.getElementById('move-btn');
        if (!moveBtn) {
            showMessage('Move button missing from page.', 'error');
            return;
        }
        moveBtn.classList.add('loading');
        moveBtn.disabled = true;

        try {
            const response = await fetch('/api/motor/move', {
                method: 'POST',
                body: formData
            });

            const result = await response.json();

            if (response.ok) {
                showMessage(result.message, 'success');
                this.isMoving = true;
                this.updateMotorStatus();
            } else {
                showMessage(result.detail || 'Failed to start motor movement', 'error');
            }
        } catch (error) {
            logError('Error moving motor:', error);
            showMessage('Network error. Please try again.', 'error');
        } finally {
            moveBtn.classList.remove('loading');
            moveBtn.disabled = false;
        }
    }

    async handleStopMotor() {
        const stopBtn = document.getElementById('stop-btn');
        if (!stopBtn) {
            showMessage('Stop button missing from page.', 'error');
            return;
        }
        stopBtn.disabled = true;

        try {
            const response = await fetch('/api/motor/stop', {
                method: 'POST'
            });

            const result = await response.json();

            if (response.ok) {
                showMessage(result.message, 'success');
                this.isMoving = false;
                this.updateMotorStatus();
            } else {
                showMessage(result.detail || 'Failed to stop motor', 'error');
            }
        } catch (error) {
            logError('Error stopping motor:', error);
            showMessage('Network error. Please try again.', 'error');
        } finally {
            stopBtn.disabled = false;
        }
    }

    async handleResetPosition() {
        const resetBtn = document.getElementById('reset-btn');
        if (!resetBtn) {
            showMessage('Reset button missing from page.', 'error');
            return;
        }
        resetBtn.disabled = true;

        try {
            const response = await fetch('/api/motor/reset', {
                method: 'POST'
            });

            const result = await response.json();

            if (response.ok) {
                showMessage(result.message, 'success');
                this.updateMotorStatus();
            } else {
                showMessage(result.detail || 'Failed to reset position', 'error');
            }
        } catch (error) {
            logError('Error resetting position:', error);
            showMessage('Network error. Please try again.', 'error');
        } finally {
            resetBtn.disabled = false;
        }
    }

    async updateMotorStatus() {
        try {
            const response = await fetch('/api/status');
            const data = await response.json();

            if (response.ok) {
                this.updateStatusDisplay(data.motor);
            }
        } catch (error) {
            logError('Error updating status:', error);
        }
    }

    updateStatusDisplay(motorStatus) {
        // Update position
        const positionEl = document.getElementById('position');
        if (positionEl) {
            positionEl.textContent = `${motorStatus.degrees.toFixed(1)}°`;
        }

        // Update steps
        const stepsEl = document.getElementById('steps');
        if (stepsEl) {
            stepsEl.textContent = motorStatus.steps;
        }

        // Update status
        const statusEl = document.getElementById('status');
        if (statusEl) {
            if (motorStatus.is_moving) {
                statusEl.innerHTML = '<span class="status-moving">Moving</span>';
            } else {
                statusEl.innerHTML = '<span class="status-stopped">Stopped</span>';
            }
        }

        // Update enabled status
        const enabledEl = document.getElementById('enabled');
        if (enabledEl) {
            if (motorStatus.is_enabled) {
                enabledEl.innerHTML = '<span class="status-enabled">Yes</span>';
            } else {
                enabledEl.innerHTML = '<span class="status-disabled">No</span>';
            }
        }

        // Update button states
        this.updateButtonStates(motorStatus.is_moving);
    }

    updateButtonStates(isMoving) {
        const moveBtn = document.getElementById('move-btn');
        if (!moveBtn) {
            showMessage('Move button missing from page.', 'error');
            return;
        }
        const stopBtn = document.getElementById('stop-btn');
        if (!stopBtn) {
            showMessage('Stop button missing from page.', 'error');
            return;
        }

        moveBtn.disabled = isMoving;
        stopBtn.disabled = !isMoving;
    }

    startStatusUpdates() {
        // Update status every 2 seconds
        this.updateInterval = setInterval(() => {
            this.updateMotorStatus();
        }, 2000);
    }

    async loadLogs() {
        const logsContainer = document.getElementById('logs-container');
        if (!logsContainer) return;

        try {
            const response = await fetch('/api/logs?limit=20');
            const data = await response.json();

            if (response.ok) {
                this.displayLogs(data.logs);
            } else {
                logsContainer.innerHTML = '<div class="error">Failed to load logs</div>';
            }
        } catch (error) {
            logError('Error loading logs:', error);
            logsContainer.innerHTML = '<div class="error">Failed to load logs</div>';
        }
    }

    displayLogs(logs) {
        const logsContainer = document.getElementById('logs-container');
        if (!logsContainer) return;

        if (logs.length === 0) {
            logsContainer.innerHTML = '<div class="loading">No movements recorded yet</div>';
            return;
        }

        const logsHTML = logs.map(log => {
            const [direction, degrees, steps, created_at, username] = log;
            const date = new Date(created_at);
            const timeString = date.toLocaleString();

            return `
                <div class="log-item">
                    <div class="log-info">
                        <div class="log-direction">${direction.replace('_', ' ')} - ${degrees}°</div>
                        <div class="log-details">${steps} steps by ${username}</div>
                    </div>
                    <div class="log-time">${timeString}</div>
                </div>
            `;
        }).join('');

        logsContainer.innerHTML = logsHTML;
    }

    showMessage(message, type = 'success') {
        // Remove existing messages
        const existingMessages = document.querySelectorAll('.message');
        existingMessages.forEach(msg => msg.remove());

        // Create new message
        const messageEl = document.createElement('div');
        messageEl.className = `message ${type}`;
        messageEl.textContent = message;

        // Insert at the top of the main content
        const mainContent = document.querySelector('.main-content');
        if (mainContent) {
            mainContent.insertBefore(messageEl, mainContent.firstChild);

            // Auto-remove after 5 seconds
            setTimeout(() => {
                messageEl.remove();
            }, 5000);
        }
    }

    destroy() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
        }
    }
}

// Initialize the motor controller when the page loads
document.addEventListener('DOMContentLoaded', function () {
    window.motorController = new MotorController();

    // Remove any global form submit handlers
    // Only bind to forms with class 'ajax-form' (for login/register)
    document.querySelectorAll('form.ajax-form').forEach(form => {
        form.addEventListener('submit', e => {
            // Your AJAX login/register code or validation here
        });
    });

    // Global JS error logging
    // Remove global window.onerror handler
});

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (window.motorController) {
        window.motorController.destroy();
    }
});

// -----------------------------
// explicit logout navigation
// ----------------------------- 