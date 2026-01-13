#!/bin/bash
# Usage: /usr/bin/save_log_info.sh <logtype> <timestr>
#
LANG=C

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

is_sdcard_available()
{
	read sdcard_state < /sys/devices/platform/dw_mmc_sdcard.0/sdcard_state
	if [ $sdcard_state -eq 1 ]; then
		if grep -qs '/opt/storage/sdcard' /etc/mtab; then
			return 1
		fi
	fi
	
	return 0	
}

if [ "$1" = "key" ]; then
	A7LOG_NAME="a7_log.info"
else
	A7LOG_NAME="a7_crash.info"
fi

if [ $# -eq 1 ]; then
	TIME=$(date +"%Y%m%d"_"%H%M%S")
else
	TIME="$2"
fi

UNIQUENO=`vconftool get memory/private/pmode_uniqueno | awk '{ print $4 }' `
is_sdcard_available
sdcard_available=$?

if [ $sdcard_available -eq 1 ]; then
	DMESG_FILE="/sdcard/$UNIQUENO""_""$TIME""_a9_dmesg.info"
	DLOG_FILE="/sdcard/$UNIQUENO""_""$TIME""_a9_dlog.info"
	A7LOG_FILE="/sdcard/$UNIQUENO""_""$TIME""_$A7LOG_NAME"
	ALLLOG_FILE="/sdcard/$UNIQUENO""_""$TIME""_log.info"
	#AFLOG_FILE="/sdcard/$UNIQUENO""_""$TIME""_af_log.info"
else
	if [ ! -e "/opt/usr/media/info" ]; then
		mkdir "/opt/usr/media/info"
	fi
	DMESG_FILE="/opt/usr/media/info/$UNIQUENO""_""$TIME""_a9_dmesg.info2"
	DLOG_FILE="/opt/usr/media/info/$UNIQUENO""_""$TIME""_a9_dlog.info2"
	A7LOG_FILE="/opt/usr/media/info/$UNIQUENO""_""$TIME""_$A7LOG_NAME""2"
	ALLLOG_FILE="/opt/usr/media/info/$UNIQUENO""_""$TIME""_log.info2"
	#AFLOG_FILE="/opt/usr/media/info/$UNIQUENO""_""$TIME""_af_log.info2"
fi

# save A7/A9 log info
dmesg -r > $DMESG_FILE
dlogutil -v threadtime -df /tmp/dlog.info 2>/dev/null
sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" /tmp/dlog.info > $DLOG_FILE
#xinfo -topvwins /tmp
#cat "/tmp/`ls /tmp | grep topvwins`" >> $DLOG_FILE
sync

st cap log > $A7LOG_FILE
# save af log file
#st log afinfo /tmp/af.info
#if [ -e /tmp/af.info ]; then
#	mv /tmp/af.info $AFLOG_FILE
#fi

# create single log file.
/usr/bin/log -f $ALLLOG_FILE
sync

# Currently, cannot save A7 detail info if crash occurs on A7.
if [ "$1" != "a7_fault" ]; then
	echo -e "\nA7 Sequence Log: "        >> $A7LOG_FILE
	st cap seq log    >> $A7LOG_FILE
	echo -e "\nA7 Sequence Status: "     >> $A7LOG_FILE
	st cap seq log 1  >> $A7LOG_FILE
	echo -e "\nA7 Sequence 1 status: "   >> $A7LOG_FILE
	st cap seq status >> $A7LOG_FILE
	echo -e "\nA7 User Data: "           >> $A7LOG_FILE
	st cap capdtm usrlist >> $A7LOG_FILE
	echo -e "\nA7 IQ DataRepeater: "     >> $A7LOG_FILE
	st cap iqr >> $A7LOG_FILE
	echo -e "\nA7 T-Kernel Task Info: "  >> $A7LOG_FILE
	st cap ref tsk    >> $A7LOG_FILE
	echo -e "\nA7 T-Kernel Stack Info: " >> $A7LOG_FILE
	st cap ref stack  >> $A7LOG_FILE
	echo -e "\nA7 T-Kernel Mem Info: "   >> $A7LOG_FILE
	st cap ref mem    >> $A7LOG_FILE
	echo -e "\nA7 Capture Memory Status:">> $A7LOG_FILE
	st cap capmm show >> $A7LOG_FILE
	echo -e "\nA7 DVFS Status:">> $A7LOG_FILE
	st cap capt dvfs status >> $A7LOG_FILE


fi

if [ $sdcard_available -eq 1 ]; then
	if [ -f /sdcard/info.tg ] || [ -f /sdcard/info.tgw ] || [ -e /sdcard/dfms.tg ]; then
		if [ -f /opt/share/dfms/dfms.log ]; then
			cp -rf /opt/share/dfms/dfms.log /sdcard/
		fi
		if [ -f /opt/share/dfms/dfms.log.old ]; then
			cp -rf /opt/share/dfms/dfms.log.old /sdcard/
		fi
	fi
fi

if [ $sdcard_available -eq 1 ]; then
	for f in /opt/usr/media/info/*.info2; do
		test -f "$f" || continue
		mv "$f" /sdcard/
		echo "Previous log file moved ($f)"
	done
fi

sync

st log sound
echo 0 > /sys/class/leds/led.0/brightness
echo 0 > /sys/class/leds/led.1/brightness
echo 0 > /sys/class/leds/led.2/brightness
echo 0 > /sys/class/leds/led.3/brightness
echo 0 > /sys/class/leds/led.4/brightness
