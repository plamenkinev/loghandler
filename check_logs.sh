#!/usr/bin/env bash

CONF_FILE="check_logs.conf"

get_disk_utilization() {
	DIR=$1
	DISK_UTIL=$(df -h $DIR | tail -1 | awk '{print $5}' | cut -d '%' -f 1)
}

if [ -f $CONF_FILE ]; then 
	. check_logs.conf
	echo "$($LOG_DATE_FMT) Using config file $CONF_FILE ..." >> $LOG_FILE
else
	THRESHOLD_WARN=60
	THRESHOLD_CRIT=75
	APP_LOGS_DIR="/var/log/app/"
	NOTIFY_EMAILS="admin@company.com"
	LOG_FILE=$(dirname $0)/check_logs.log
	LOG_DATE_FMT="date \"+%Y-%m-%d %H:%M:%s\""
	echo "$($LOG_DATE_FMT) Using default config values ..." >> $LOG_FILE
fi

get_disk_utilization $APP_LOGS_DIR
echo $DISK_UTIL
