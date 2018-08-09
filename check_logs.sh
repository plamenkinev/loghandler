#!/usr/bin/env bash

#set -x

APP_LOGS_DIR="/home/plamen/dir1/dir2/dir3/dir4"
THRESHOLD=75
NOTIFY_EMAILS="plamenkinev@gmail.com"
LOG_FILE="/home/plamen/dev/bash/check_logs.log"

log_to_file() {
	MSG=$1
	DATE=$(date "+%Y-%m-%d %H:%M:%S")
	echo $DATE " " $MSG >> $LOG_FILE
}


get_disk_utilization() {
	DIR=$1
	log_to_file "Checking disk utilization of $DIR"
	DISK_UTIL=$(df -h $DIR | tail -1 | awk '{print $5}' | cut -d '%' -f 1)
	DISK_UTIL=80
	log_to_file "Disk utilization of $DIR is $DISK_UTIL%"
}

compress_uncompressed_logs() {
	DIR=$1
	cd $DIR
	log_to_file "Checking for log files in $DIR that could be compressed" 
	# Compress all logs without the one from today
	FILES_TO_COMPRESS=$(find . -maxdepth 1 -type f -mtime +0 -exec echo {} \; | grep -v ".xz")
	FILES_TO_COMPRESS_COUNT=$(echo $FILES_TO_COMPRESS | wc -w)
	if [ $FILES_TO_COMPRESS_COUNT -gt 0 ]; then
		for FILE in $FILES_TO_COMPRESS; do
			log_to_file "Compressing file $FILE"
			xz -9zq $FILE
		done
	else
		log_to_file "No files could be compressed"
	fi
	
}

remove_log() {
	DIR=$1
	cd $DIR
	log_to_file "Checking for compressed log files in $DIR that could be removed"
	COMPRESSED_LOGS=$(find . -maxdepth 1 -mtime +0 -type f -name "*.xz")
	COMPRESSED_LOGS_COUNT=$(echo $COMPRESSED_LOGS | wc -w)
	OLD_COMPRESSED_LOG=$(find . -maxdepth 1 -type f -mtime +0 -printf '%Ts\t%p\n' | sort -n | head -1 | awk '{print $2}')
	if [ $COMPRESSED_LOGS_COUNT -gt 0 ]; then
		log_to_file "Removing $OLD_COMPRESSED_LOG"
		rm $OLD_COMPRESSED_LOG
		COMPRESSED_LOGS_COUNT=$(($COMPRESSED_LOGS_COUNT - 1))
	else
		log_to_file "No files could be removed"
	fi
}

rotate_log() {
        DIR=$1
        cd $DIR
	log_to_file "Rotating the log file from today"
	COMPRESSED_LOGS_TODAY_COUNT=$(find . -maxdepth 1 -type f -mtime 0 | grep ".xz" | wc -l)
	UNCOMPRESSED_LOG_TODAY=$(find . -maxdepth 1 -type f -mtime 0 | grep -v ".xz")
	NEW_PART_ID=$(($COMPRESSED_LOGS_TODAY_COUNT  + 1))
	log_to_file "Compressing the log from today as $UNCOMPRESSED_LOG_TODAY.$NEW_PART_ID.xz"
	xz -9c $UNCOMPRESSED_LOG_TODAY > $UNCOMPRESSED_LOG_TODAY.$NEW_PART_ID.xz && > $UNCOMPRESSED_LOG_TODAY
	LOG_ROTATED=1

}

free_space() {
	DIR=$1
	LOG_ROTATED=0
	COMPRESSED_LOGS_COUNT=1
	get_disk_utilization $APP_LOGS_DIR
	while [ $DISK_UTIL -ge $THRESHOLD ]; do
		compress_uncompressed_logs $DIR
		get_disk_utilization $DIR
		if [ $DISK_UTIL -ge $THRESHOLD ] && [ $COMPRESSED_LOGS_COUNT -gt 0 ]; then
			remove_log $DIR
		elif [ $LOG_ROTATED -eq 0 ]; then
			rotate_log $DIR
		else
			mailx -s "No more coca, baby" $NOTIFY_EMAILS
			exit 100
		fi
	done	
}

free_space

