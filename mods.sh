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

# Wifi
wlan.sh start >> /mnt/mmc/log
/sbin/ifconfig wlan0 up >> /mnt/mmc/log
/sbin/ifconfig p2p0 up >> /mnt/mmc/log
sleep 2
/sbin/ifconfig wlan0 >> /mnt/mmc/log
/sbin/ifconfig p2p0 >> /mnt/mmc/log
/usr/sbin/wpa_supplicant -B -dd -i wlan0 -c /mnt/mmc/wpa_supplicant.conf >>/mnt/mmc/log
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
