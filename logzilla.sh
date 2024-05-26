#!/bin/bash

### Variables
declare -a log_directories=(
  '/home/applogs/logs/;urs*;http*' 
  )

dont_touch_the_latest_x_files=3
log_rotate_files_to_keep=600
ignore_file_pattern='.snapshot.|.tar|.gz'
file_matching_pattern='.log'

### Functions

#This function writes a log message
log_message(){
  message=$(echo $(date +"%Y-%m-%d %H:%M:%S.%3N") ":" $1 $2 $3 $4 $5 $6)
  echo $message
  logger $message
}

echo "This process PID is: " $$

status=`ps -efww | grep 'logzilla' | grep -v grep | grep -v $$ | grep -v vim`
if [ ! -z "$status" ]; then
  log_message "logzilla : Process is already running. $status"
  exit 1;
fi
for directory_list in "${log_directories[@]}"

do

  IFS=';' read -r -a array_disrectory <<< "$directory_list"

  item_counter=0
  directory=''
  for array_item in "${array_disrectory[@]}"
  do
    if [[ $item_counter -eq 0 ]]
    then
      # hand;e the case where people leave the trailing slahs of the directory
      directory=`echo $array_item'/' | tr -s /`
    else
      log_message "<----------------------------------->"
      log_message "Current directory is: "  $directory;
      log_message "Current term is: "  $array_item;

      log_message "Files to leave alone: ";
      ls -1t $directory$array_item*$file_matching_pattern | egrep -v "$ignore_file_pattern" | head -$dont_touch_the_latest_x_files | xargs -d '\n' -I % echo %

      log_message "Files to compress: ";
      files=`ls -1rt $directory$array_item*$file_matching_pattern | egrep -v "$ignore_file_pattern" | head -n -$dont_touch_the_latest_x_files`

      for file in $files
      do
           log_message $file
           gzip $file
      done

      files2=`ls -1rt $directory$array_item*$file_matching_pattern.gz | head -n -$log_rotate_files_to_keep`
      log_message "Files to remove: ";
      for file2 in $files2
      do
           log_message $file2
           rm -f $file2
      done

    fi
      item_counter=$item_counter+1
  done


done