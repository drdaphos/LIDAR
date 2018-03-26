#!/bin/bash
#
# This script is for the routine post flight processing of ARIES data only.
#
# Version 1.0 DAT 18-09-09 This calls the ncmace routine checking whether it
# exists ( or is already running some processing ) first - then uses nohup 
# to run in the background. 
# Version 1.1 AKV 24-11-09  Now provides user with some info on whether processing
# run started successfully or not.
#
# Usage
#     aries.sh -first flight1 -last flightn -raw path -prefix letter
#     eg.
#     aries.sh -first 350 -last 400 -raw /media/usbdisk/ -prefix b
#     to process flights b350 to b400 inclusive
#     or
#     aries.sh -flight flight -raw path -prefix letter
######################################################################################


if test -f ncmace.sh 
then
  cal_data_dir=/data/local/frvn/aries/caldata/		# path for calibrated data
  echo "-----------------------------------------------------------------"
  echo "Warning: proceeding will delete the following caldata directories"
  ls $cal_data_dir
  echo "-----------------------------------------------------------------"
  read -p " Do you wish to proceed (y/n)?  " proceed
  echo " "
  if [ "${proceed:0:1}" == "y" ] || [ "${proceed:0:1}" == "Y" ] 
  then
    log="aries_$(date +%Y%m%d_%H%M%S).log"  ##this needs looked at - may be including blanks for single digit hours
    nohup ncmace.sh $@ >> "$log" 2>&1 &
    echo "--- ARIES processing is being logged to file $log"
    export ARIES_LOG_FILE=$log
    sleep 1
    gawk 'NR=2&&$2=="ERROR:" {fail=1};fail==1{print};fail!=1&&FNR==2{print "--- ncmace started\n"}' $log
  fi
else
  echo "ncmace unavailable - other ARIES processing may already be running"
  ls PROCESSING_IN_PROGRESS*
fi
