#!/bin/sh
# Usage: /usr/bin/save_crash_info.sh <filepath> <timestr>
#

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
	CRASH_INFO_FILE="/sdcard/$UNIQUENO""_""$TIME""_a9_crash.info"
	A7LOG_FILE="/sdcard/$UNIQUENO""_""$TIME""_a7_log.info"
	ALLLOG_FILE="/sdcard/$UNIQUENO""_""$TIME""_log.info"
else
	if [ ! -e "/opt/usr/media/info" ]; then
		mkdir "/opt/usr/media/info"
	fi
	DMESG_FILE="/opt/usr/media/info/$UNIQUENO""_""$TIME""_a9_dmesg.info2"
	DLOG_FILE="/opt/usr/media/info/$UNIQUENO""_""$TIME""_a9_dlog.info2"
	CRASH_INFO_FILE="/opt/usr/media/info/$UNIQUENO""_""$TIME""_a9_crash.info2"
	A7LOG_FILE="/opt/usr/media/info/$UNIQUENO""_""$TIME""_a7_log.info2"
	ALLLOG_FILE="/opt/usr/media/info/$UNIQUENO""_""$TIME""_log.info2"
fi

# save A9 crash info
if [ -e $1 ]; then
	mv $1 $CRASH_INFO_FILE
fi

# save A7/A9 log info
if [ ! -f $DMESG_FILE ]; then
	dmesg -r > $DMESG_FILE
fi

if [ ! -f $DLOG_FILE ]; then
	dlogutil -v threadtime -df /tmp/dlog.info
	sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" /tmp/dlog.info > $DLOG_FILE
	rm /tmp/dlog.info
fi

# create single log file.
if [ ! -f $ALLLOG_FILE ]; then
	/usr/bin/log -f $ALLLOG_FILE
fi

if [ ! -f $A7LOG_FILE ]; then
	st cap log   > $A7LOG_FILE
	echo -e "\nA7 Sequence Log: "        >> $A7LOG_FILE
	st cap seq log    >> $A7LOG_FILE
	echo -e "\nA7 Sequence Status: "     >> $A7LOG_FILE
	st cap seq status >> $A7LOG_FILE
	echo -e "\nA7 User Data: "     >> $A7LOG_FILE
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

sync

