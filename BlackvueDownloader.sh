#!/bin/bash

# IP addresses to check
DASHCAM_IP1=10.1.10.110

# Location of dashcam files and PID file
FILE_LOCATION=/data/dashcam/blackvue
PIDFILE=/data/dashcam/blackvue.pid
MAX_SIZE=1073741824000
#  1073741824000 = 1Tb of storage

#---------------------------------------------------------
# Monkey patch to provide timestamped output for logs/console

echo() {
    command echo $(date) "$@"
}

#---------------------------------------------------------
# Function to remove files if folder is too big

cleanup() {
  OPENING_SIZE=$(du -b ${FILE_LOCATION} | cut -f 1)

  RUNING_TOTAL=${OPENING_SIZE}
  for FILENAME in $(ls -1rt ${FILE_LOCATION})
  do
    URI=${FILE_LOCATION}/${FILENAME}
    BYTES=$(du -b ${URI} | cut -f 1)

    IF_DELETED_SIZE=$(($RUNING_TOTAL - $BYTES))
    if [[ ${IF_DELETED_SIZE} -gt ${MAX_SIZE} ]]
    then
      echo "Deleting ${URI}"
      rm -f ${URI}
      RUNING_TOTAL=${IF_DELETED_SIZE}
    else
      echo "Finished. Opening size ${OPENING_SIZE}. New size is ${RUNING_TOTAL}"
      return
    fi
  done
}

#---------------------------------------------------------
# Function to check if file exists before downloading

download_file() {
  # Filename eg. "20210403_134118_PF.mp4"
  FILENAME=$@
  FILEGROUP=${FILENAME:8}
  SUFFIXES="F.mp4 R.mp4 F.thm R.thm .gps .3gf"

  for SUFFIX in $SUFFIXES; do
    # Check if files exist before attempting to download
    if [ ! -f ${FILE_LOCATION}/${FILEGROUP}${SUFFIX} ]; then
      echo ".. downloading ${FILENAME}${SUFFIX}"
      wget -T 10 -t 2 -nv -c "http://${DASHCAM_IP}${FILENAME}${SUFFIX}"
    else
      echo "... already downloaded ${FILENAME}${SUFFIX}"
    fi
  done
}

#-----------------------------------------------------------------------------
# Program control - check for other running instances, to avoid duplicate runs

if [ -f $PIDFILE ]
then
  PID=$(cat $PIDFILE)
  ps -p $PID > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "Process already running"
    exit 1
  else
    ## Process not found assume not running
    # echo $$ > $PIDFILE
    > $PIDFILE cat <<< "$$"
    if [ $? -ne 0 ]
    then
      echo "Could not create PID file"
      exit 1
    else
      echo "Old PID $PID stale, creating new process $$"
    fi
  fi
else
  # echo $$ > $PIDFILE
  > $PIDFILE cat <<< "$$"
  if [ $? -ne 0 ]
  then
    echo "Could not create PID file"
    exit 1
  else
      echo "No PID, creating new process $$"
  fi
fi

#-----------------------------------------------------------------------------
# Check if the dashcam can be found on one of the two ip addresses

ping -c 3 $DASHCAM_IP1 > /dev/null 2>&1
if [ $? -ne 0 ]
then
  echo "Dashcam not found on $DASHCAM_IP1"
  exit 1
else
  DASHCAM_IP=$DASHCAM_IP1
fi

echo "Dashcam found on $DASHCAM_IP"

#-----------------------------------------------------------------------------
# Download all files

cd $FILE_LOCATION

# Use curl to extract a list of available files from the camera, then iterate for each file
for file in $(curl --connect-timeout 10 http://$DASHCAM_IP/blackvue_vod.cgi | sed 's/^n://' | sed 's/F.mp4//' | sed 's/R.mp4//' | sed 's/,s:1000000//' | sed $'s/\r//' | grep 'Record' | sort -u)
do
  download_file "$file"
done

# Manage folder size, remove old data to keep within MAX_SIZE
cleanup

# remove PID
rm $PIDFILE