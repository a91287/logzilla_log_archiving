# logzilla_log_archiving
The provided script is a log rotation and compression tool designed to manage log files in specified directories efficiently. It defines a set of directories and file patterns to process, ensuring that the most recent log files are excluded from compression while older files are compressed to save disk space. The script also maintains a limit on the number of compressed files to retain, deleting the oldest ones beyond this limit to prevent excessive disk usage. Additionally, it logs all actions taken, providing a detailed record of file operations. By scheduling this script to run at regular intervals using crontab, users can automate the management of log files, ensuring that storage space is optimized and log files are systematically compressed and cleaned up.


# Instructions for Using and Scheduling the Log Rotation Script

## Step 1: Save the Script

1. Open a text editor and paste the provided script into it.
2. Save the file with an appropriate name, for example, `log_rotate.sh`.

## Step 2: Make the Script Executable

1. Open a terminal.
2. Navigate to the directory where you saved the script.
3. Run the following command to make the script executable:

   ```bash
   chmod +x log_rotate.sh
   ```

## Step 3: Modify the Variables

Edit the script to modify the variables as per your needs:

- `log_directories`: An array of directories to process, formatted as `'/path/to/logs/;pattern1;pattern2'`.
- `dont_touch_the_latest_x_files`: Number of latest files to exclude from compression.
- `log_rotate_files_to_keep`: Number of compressed files to keep before deletion.
- `ignore_file_pattern`: Patterns to exclude from processing.
- `file_matching_pattern`: Pattern to match the files for processing.

## Step 4: Schedule the Script Using Crontab

1. Open the crontab editor by running the following command in the terminal:

   ```bash
   crontab -e
   ```

2. Add the following line to schedule the script to run every 10 minutes:

   ```bash
   */10 * * * * /path/to/log_rotate.sh
   ```

   Replace `/path/to/log_rotate.sh` with the actual path to your script.

## Script Explanation

Here's a detailed explanation of the script:

### Variables Declaration:

```bash
declare -a log_directories=(
  '/home/applogs/logs/;urs*;http*' 
)

dont_touch_the_latest_x_files=3
log_rotate_files_to_keep=600
ignore_file_pattern='.snapshot.|.tar|.gz'
file_matching_pattern='.log'
```

- `log_directories`: Array of log directories with patterns.
- `dont_touch_the_latest_x_files`: Number of recent files to keep uncompressed.
- `log_rotate_files_to_keep`: Number of compressed files to retain.
- `ignore_file_pattern`: Patterns of files to ignore.
- `file_matching_pattern`: Pattern to match log files.

### Functions:

- `log_message`: Logs messages with timestamps.

  ```bash
  log_message(){
    message=$(echo $(date +"%Y-%m-%d %H:%M:%S.%3N") ":" $1 $2 $3 $4 $5 $6)
    echo $message
    logger $message
  }
  ```

### Check for Existing Process:

```bash
status=`ps -efww | grep 'logzilla' | grep -v grep | grep -v $$ | grep -v vim`
if [ ! -z "$status" ]; then
  log_message "logzilla : Process is already running. $status"
  exit 1;
fi
```

- Checks if another instance of the script is running and exits if found.

### Main Logic:

```bash
for directory_list in "${log_directories[@]}"
do
  IFS=';' read -r -a array_disrectory <<< "$directory_list"

  item_counter=0
  directory=''
  for array_item in "${array_disrectory[@]}"
  do
    if [[ $item_counter -eq 0 ]]
    then
      directory=`echo $array_item'/' | tr -s /`
    else
      log_message "<----------------------------------->"
      log_message "Current directory is: "  $directory
      log_message "Current term is: "  $array_item

      log_message "Files to leave alone: "
      ls -1t $directory$array_item*$file_matching_pattern | egrep -v "$ignore_file_pattern" | head -$dont_touch_the_latest_x_files | xargs -d '\n' -I % echo %

      log_message "Files to compress: "
      files=`ls -1rt $directory$array_item*$file_matching_pattern | egrep -v "$ignore_file_pattern" | head -n -$dont_touch_the_latest_x_files`

      for file in $files
      do
           log_message $file
           gzip $file
      done

      files2=`ls -1rt $directory$array_item*$file_matching_pattern.gz | head -n -$log_rotate_files_to_keep`
      log_message "Files to remove: "
      for file2 in $files2
      do
           log_message $file2
           rm -f $file2
      done
    fi
    item_counter=$item_counter+1
  done
done
```

- Iterates over the directories and patterns, compresses old log files, and removes excess compressed files while logging the process.

## Summary

By following these steps, you can set up the provided script to run every 10 minutes using `crontab`. Make sure to adjust the variables within the script to suit your specific needs.
