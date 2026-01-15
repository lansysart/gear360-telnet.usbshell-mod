<h1>Samsung Gear 360 (2016) Custom Script Run Guide</h1>

<p><strong>USBShell, Custom Sctipt Run, MODDING - Samsung Gear 360 (2016 model SM-C200).</strong></p>

<h2>📋 Required Materials</h2>
<ul>
<li>Samsung Gear 360 (SM-C200) 2016 Edition</li>
<li>MicroSD Card (formatted to FAT32)</li>
<li>Computer with telnet client</li>
</ul>

<hr>

<h2>📥 Step 1: Firmware Update</h2>

<h3>Download Latest Official Firmware:</h3>
<p>Get the firmware files from:</p>
<pre>https://github.com/LalaTheDog/2016Gear360FirmwareUpdate</pre>

<h3>Files to Copy to SD Card Root:</h3>
<pre>
C200GLU0AQK1_171121_1257_REV00_user.bin  (279,094,189 bytes)
info.tg                                   (12 bytes)
updater.adj                               (33 bytes)
updater.sh                                (123 bytes)
</pre>

<h3>Update Process:</h3>
<ol>
<li>Copy <strong>all four files</strong> to the root of your SD card</li>
<li>Insert SD card into Gear 360</li>
<li>Power on the device - it will automatically start updating</li>
<li>Wait for "Updated" message to appear</li>
<li>Power off the device</li>
<li><strong>Remove all files from SD card</strong></li>
</ol>

<div>
<strong>Note:</strong> The update process is automatic. Just wait for completion.
</div>

<hr>

<h2>⚙️ Step 2: Custom Software Modification</h2>

<h3>Prepare Custom Files:</h3>
<ol>
<li>Download the custom software package</li>
<li>Extract all files to your SD card root</li>
</ol>

<h3>Configuration Changes Required:</h3>

<h4>1. Network Configuration in <code>mods.sh</code>:</h4>
<p>Modify these lines according to your network settings:</p>
<pre>
/sbin/ifconfig wlan0 192.168.0.22 netmask 255.255.255.0 >> /mnt/mmc/log
/usr/sbin/ip route add default via 192.168.0.1 >> /mnt/mmc/log

sleep 1
/mnt/mmc/mods/tcpsvd -vE 0.0.0.0 21 ftpd -w / &</pre>

<h4>2. WiFi Configuration in <code>wpa_supplicant.conf</code>:</h4>
<p>Edit two files:</p>
<ul>
<li><code>wpa_supplicant.conf</code> in root</li>
<li><code>/mods/wpa_supplicant.conf</code> in mods folder</li>
</ul>
<pre>
ssid="YOUR_WIFI_NETWORK_NAME"
psk="YOUR_WIFI_PASSWORD"</pre>

<h3>Installation:</h3>
<ol>
<li>Insert configured SD card into Gear 360</li>
<li>Power on the device</li>
<li>Wait for LED blinking to stop (you'll hear a short confirmation sound)</li>
</ol>

<hr>

<h2>🔧 Step 3: Initial Setup via Telnet</h2>

<h3>Connect to Device:</h3>
<pre>telnet 192.168.0.22</pre>

<p>You should see:</p>
<pre>
Trying 192.168.0.22...
Connected to 192.168.0.22.
Escape character is '^]'.

\************************************************************
\*                 SAMSUNG LINUX PLATFORM                   *
\************************************************************

drime5 login:</pre>

<h3>Login and Execute Commands:</h3>
<p>Login as <code>root</code> (no password required), then run these commands:</p>

<pre>
mount -o remount,rw /
mkdir /opt/usr/bin
cp -r /mnt/mmc/* /opt/usr/bin
# Create backup of original script
cp /usr/bin/deviced-pre.sh /usr/bin/deviced-pre.sh.backup</pre>

<h4>Add Debug Mode Script:</h4>
<pre>
cat >> /usr/bin/deviced-pre.sh << 'EOF'
# =========== DEBUG MODE ===========
# Start USB Serial Console for debugging
# This script runs on EVERY boot
DEBUG_SCRIPT="/usr/bin/serial_console.sh"
# Check if we should enable debug mode
# You can add conditions here, for example:
# - Check for a file on SD card
# - Check a switch position
# - Always enable (for testing)
# For now, always enable in background
if [ -x "$DEBUG_SCRIPT" ]; then
    echo "Starting USB debug console..." >> /tmp/boot_debug.log
    $DEBUG_SCRIPT &
else
    echo "Debug script not found: $DEBUG_SCRIPT" >> /tmp/boot_debug.log
fi
EOF</pre>

<h4>Create USB Serial Console Script:</h4>
<pre>
cat > /usr/bin/serial_console.sh << 'EOF'
#!/bin/sh
# USB ACM Serial Console for Gear 360
# This script enables USB ACM mode for serial console access
LOG_FILE="/tmp/serial_console.log"
echo "[$(date)] Starting USB ACM Serial Console" >> $LOG_FILE
# Initial delay before any USB operations
echo "[$(date)] Waiting 10 seconds before USB initialization..." >> $LOG_FILE
sleep 10
# Wait for system to settle
echo "[$(date)] Waiting 5 seconds for system to settle..." >> $LOG_FILE
sleep 5
# Check if USB mode control exists
if [ ! -f /sys/class/usb_mode/usb0/funcs_fconf ]; then
    echo "[$(date)] ERROR: USB mode control not found at /sys/class/usb_mode/usb0/funcs_fconf" >> $LOG_FILE
else
    # Check current USB mode
    CURRENT_MODE=$(cat /sys/class/usb_mode/usb0/funcs_fconf 2>/dev/null)
    echo "[$(date)] Current USB mode: '$CURRENT_MODE'" >> $LOG_FILE
    # Only switch to ACM if not already in ACM mode
    if [ "$CURRENT_MODE" != "acm" ]; then
        echo "[$(date)] Switching to ACM mode..." >> $LOG_FILE
        # Disable USB first if possible
        if [ -f /sys/class/usb_mode/usb0/enable ]; then
            echo 0 > /sys/class/usb_mode/usb0/enable 2>/dev/null
            sleep 1
        fi
        # Set ACM mode
        echo "acm" > /sys/class/usb_mode/usb0/funcs_fconf 2>/dev/null
        # Enable USB if possible
        if [ -f /sys/class/usb_mode/usb0/enable ]; then
            echo 1 > /sys/class/usb_mode/usb0/enable 2>/dev/null
            sleep 2
        fi
        echo "[$(date)] USB ACM mode set" >> $LOG_FILE
    else
        echo "[$(date)] Already in ACM mode" >> $LOG_FILE
    fi
fi
# Additional delay before starting mod.sh search
echo "[$(date)] Waiting 5 seconds before searching for mod.sh..." >> $LOG_FILE
sleep 5
# START MOD.SH BEFORE SERIAL CONSOLE WITH ADDITIONAL DELAY
echo "[$(date)] Looking for mod.sh..." >> $LOG_FILE
# Check multiple possible locations for mod.sh including /mnt/mmc
MOD_PATHS="/opt/usr/bin/mod.sh /usr/bin/mod.sh /bin/mod.sh /mod.sh /mnt/mmc/mod.sh /mnt/mmc/opt/usr/bin/mod.sh /mnt/mmc/usr/bin/mod.sh /mnt/mmc/bin/mod.sh"
MOD_FOUND=0
for MOD_PATH in $MOD_PATHS; do
    if [ -x "$MOD_PATH" ]; then
        echo "[$(date)] Found mod.sh at: $MOD_PATH" >> $LOG_FILE
        echo "[$(date)] Waiting 10 seconds before starting $MOD_PATH..." >> $LOG_FILE
        # Wait 10 seconds before starting mod.sh
        sleep 10
        echo "[$(date)] Starting $MOD_PATH..." >> $LOG_FILE
        "$MOD_PATH" &
        MOD_PID=$!
        echo "[$(date)] mod.sh started with PID: $MOD_PID" >> $LOG_FILE
        MOD_FOUND=1
        break
    fi
done
if [ $MOD_FOUND -eq 0 ]; then
    echo "[$(date)] WARNING: mod.sh not found in any of the searched paths" >> $LOG_FILE
    echo "[$(date)] Searched paths: $MOD_PATHS" >> $LOG_FILE
    # Additional check - search recursively in /mnt/mmc
    if [ -d "/mnt/mmc" ]; then
        echo "[$(date)] Searching recursively in /mnt/mmc..." >> $LOG_FILE
        FOUND_FILES=$(find /mnt/mmc -name "mod.sh" -type f 2>/dev/null | head -5)
        if [ -n "$FOUND_FILES" ]; then
            echo "[$(date)] Found these mod.sh files (not necessarily executable):" >> $LOG_FILE
            for FILE in $FOUND_FILES; do
                PERMS=$(ls -la "$FILE" 2>/dev/null | awk '{print $1}')
                echo "[$(date)]   $FILE ($PERMS)" >> $LOG_FILE
            done
        fi
    fi
fi
# Configure serial port if ttyGS0 exists
if [ -c /dev/ttyGS0 ]; then
    echo "[$(date)] Configuring /dev/ttyGS0" >> $LOG_FILE
    # Set serial parameters
    stty -F /dev/ttyGS0 115200 cs8 -parenb -cstopb -echo -icanon min 1 time 1 2>/dev/null
    # Send welcome message
    echo -e "\n\n===========================================" > /dev/ttyGS0
    echo "   Gear 360 USB Serial Console" > /dev/ttyGS0
    echo "   ACM Mode: ACTIVE" > /dev/ttyGS0
    echo "   Date: $(date)" > /dev/ttyGS0
    echo "===========================================" > /dev/ttyGS0
    echo -e "\nType 'help' for available commands\n" > /dev/ttyGS0
    # Start getty on serial port for login
    # Or simple shell if getty not available
    echo "[$(date)] Starting console on /dev/ttyGS0" >> $LOG_FILE
    # Option 1: Start getty (if available)
    if [ -x /sbin/getty ]; then
        exec /sbin/getty -L ttyGS0 115200 vt100
    # Option 2: Start shell directly
    else
        exec /bin/sh -i </dev/ttyGS0 >/dev/ttyGS0 2>&1
    fi
else
    echo "[$(date)] ERROR: /dev/ttyGS0 not found!" >> $LOG_FILE
    # Try to list available TTY devices
    echo "[$(date)] Available TTY devices:" >> $LOG_FILE
    ls -la /dev/tty* 2>/dev/null | grep -v pts >> $LOG_FILE
    exit 1
fi
EOF</pre><h4>Make Script Executable:</h4>
<pre>chmod +x /usr/bin/serial_console.sh</pre>

<h4>Create Systemd Service:</h4>
<pre>
cat > /etc/systemd/system/usb-debug.service << 'EOF'
[Unit]
Description=USB Debug Console Service
After=deviced.service
Wants=deviced.service

[Service]
Type=simple
ExecStart=/usr/bin/serial_console.sh
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF</pre>

<h4>Enable the Service:</h4>
<pre>
systemctl daemon-reload
systemctl enable usb-debug.service
systemctl start usb-debug.service</pre>

<hr>

<h2>💾 Step 4: Create Snapshot and Finalize</h2>

<h3>Sync and Reboot:</h3>
<pre>
sync;sync;sync
mount -o remount,ro /
/usr/bin/erase_snapshot.sh</pre>

<p>The device will reboot automatically.</p>

<div>
<strong>Wait for reboot to complete.</strong>
</div>

<h3>After Reboot - Create Snapshot:</h3>
<ol>
<li>Reconnect via telnet: <code>telnet 192.168.0.22</code></li>
<li>Login as <code>root</code></li>
<li>Run snapshot command:</li>
</ol>
<pre>/usr/bin/make_snapshot.sh</pre>

<p><h1></h1><h1>Wait for snapshot process to complete! Do not POWER OFF, or Push any button. Wait about 3-5 minuts(its faster,device will power on himself).</h1><h1></p>

<h3>Final Reboot and Shutdown:</h3>
<ol>
<li>After snapshot completes, reconnect via telnet</li>
<li>Login as <code>root</code></li>
<li>Power off the device:</li>
</ol>
<pre>poweroff</pre>

<hr>

<div>
<h3>⚠️ IMPORTANT: SD Card Requirements</h3>

<p><strong>After final shutdown:</strong></p>

<ol>
<li><strong>Remove all previous file from SDCARD. Put only mod.sh and mods folder with mods/wpa_supplicant.conf </strong></li>
<li><strong>The SD card MUST contain:</strong>
<ul>
<li><code>mod.sh</code> file in root directory</li>
  <pre>
    #!/bin/sh
echo 0 > /sys/class/leds/led.0/brightness
echo 0 > /sys/class/leds/led.1/brightness
echo 0 > /sys/class/leds/led.2/brightness
echo 0 > /sys/class/leds/led.3/brightness
echo 0 > /sys/class/leds/led.4/brightness

echo 300 > /sys/class/leds/led.0/delay_on
echo 300 > /sys/class/leds/led.3/delay_on
echo 300 > /sys/class/leds/led.4/delay_on
echo 300 > /sys/class/leds/led.0/delay_off
echo 300 > /sys/class/leds/led.3/delay_off
echo 300 > /sys/class/leds/led.4/delay_off

echo timer > /sys/class/leds/led.0/trigger
echo timer > /sys/class/leds/led.3/trigger
echo timer > /sys/class/leds/led.4/trigger

export DISPLAY=":0"
export HIB="a"
export HISTSIZE="1000"
export HOME="/root"
export HUSHLOGIN="FALSE"
export LD_LIBRARY_PATH=":/usr/lib:/usr/lib/driver"
export LOGNAME="root"
export OLDPWD
export PATH="/usr/share/scripts:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/usr/devel/usr/sbin:/opt/usr/devel/usr/bin:/opt/usr/devel/sbin:/opt/usr/devel/bin"
export PS1="[\\u@\\h \\W]\\\$ "
export PWD="/root"
export SHELL="/bin/sh"
export SHLVL="1"
export TERM="vt102"
export USER="root"
export XDG_CACHE_HOME="/tmp/.cache"

killall telnetd
killall tcpsvd
sleep 1

\# Wifi
wlan.sh start >> /mnt/mmc/log
/sbin/ifconfig wlan0 up >> /mnt/mmc/log
/sbin/ifconfig p2p0 up >> /mnt/mmc/log
sleep 2
/sbin/ifconfig wlan0 >> /mnt/mmc/log
/sbin/ifconfig p2p0 >> /mnt/mmc/log
/usr/sbin/wpa_supplicant -B -dd -i wlan0 -c /mnt/mmc/mods/wpa_supplicant.conf >>/mnt/mmc/log
sleep 10
/sbin/ifconfig wlan0 192.168.0.22 netmask 255.255.255.0 >> /mnt/mmc/log
/usr/sbin/ip route add default via 192.168.0.1 >> /mnt/mmc/log

sleep 1
/mnt/mmc/mods/tcpsvd -vE 0.0.0.0 21 ftpd -w / &
/mnt/mmc/mods/telnetd &
/mnt/mmc/mods/httpd -p 8888 -f -h /mnt/mmc/mods/www/ &

st log sound
echo 0 > /sys/class/leds/led.0/brightness
echo 0 > /sys/class/leds/led.1/brightness
echo 0 > /sys/class/leds/led.2/brightness
echo 0 > /sys/class/leds/led.3/brightness
echo 0 > /sys/class/leds/led.4/brightness
</pre>
<li><code>mods</code> folder with all binaries</li>
<li><code>wpa_supplicant.conf</code> with your WiFi credentials</li>
</ul>
</li>
</ol>
<pre>
[SD Card Root]/
├── mod.sh                 (main script)
└── mods/                  (folder with binaries)
    ├── tcpsvd
    ├── telnetd
    ├── httpd
    └── wpa_supplicant.conf
</pre>
<p><strong>CRITICAL:</strong> The device checks for the SD card on every boot, trying to search file mod.sh . Without it, the custom software will not run.Only Serial Console will be start auto</p>
</div>

<hr>

<h2>✅ What You Get</h2>
<ul>
<li>✓ USB Serial Console access(only if SDCard not installed)</li>
<li>✓ Telnet access at 192.168.0.22</li>
<li>✓ FTP server on port 21</li>
<li>✓ Web server on port 8888</li>
<li>✓ Persistent configuration</li>
<li>✓ Full Linux shell access</li>
</ul>

<hr>

<hr>

<p>
<strong>Enjoy your modded Gear 360! 🎥✨</strong><br>
If you found this helpful, consider starring the project on GitHub.
</p>
