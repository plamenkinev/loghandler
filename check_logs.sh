#!/usr/bin/env bash

set -x

APP_LOGS_DIR="/home/plamen/dir1/dir2/dir3/dir4"
THRESHOLD=75
NOTIFY_EMAILS="plamenkinev@gmail.com"
LOG_FILE="check_logs.log"

get_disk_utilization() {
	DIR=$1
	DISK_UTIL=$(df -h $DIR | tail -1 | awk '{print $5}' | cut -d '%' -f 1)
	DISK_UTIL=80
}

compress_uncompressed_logs() {
	DIR=$1
	cd $DIR
	# Compress all logs without the one from today
	find . -maxdepth 1 -type f -mtime +0 -exec xz -9 {} \;
}

remove_log() {
	DIR=$1
	cd $DIR
	COMPRESSED_LOGS=$(find . -maxdepth 1 -type f -name "*.xz")
	COMPRESSED_LOGS_COUNT=$(echo $LOGS | wc -w)
	OLD_COMPRESSED_LOG=$(find . -maxdepth 1 -type f -mtime +0 -printf '%Ts\t%p\n' | sort -n | head -1 | awk '{print $2}')
	if [ $COMPRESSED_LOGS_COUNT -gt 0 ]; then
		rm $OLD_COMPRESSED_LOG
		$COMPRESSED_LOGS_COUNT=$(($COMPRESSED_LOGS_COUNT - 1))
	fi
}

free_space() {
	DIR=$1
	get_disk_utilization $APP_LOGS_DIR
	while [ $DISK_UTIL -ge $THRESHOLD ]; do
		compress_uncompressed_logs $DIR
		get_disk_utilization $DIR
		if [ $DISK_UTIL -ge $THRESHOLD ] && [ $COMPRESSED_LOGS_COUNT -gt 0 ]; then
			remove_log $DIR
		else
			mail -s "[CRITICAL] App logs file system need you intervention!" 
		fi
	done	
}

free_space
