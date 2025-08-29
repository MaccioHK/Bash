#!/bin/bash

LOG_DIR="/usr/app/logs"
ERROR_PATTERNS=("ERROR" "EXCEPTION" "FATAL" "DISCOUNT" "ROLLBACK")
OUTPUT_FILE="/usr/app/logs/log_ana_report.txt"  #adding date as input parameter

echo "analysing the log files" > "$OUTPUT_FILE"
echo "=======================" >> "$OUTPUT_FILE"

echo -e "\nList of log files updated in last 24 hours" >> "$OUTPUT_FILE"
LOG_FILES=$(find $LOG_DIR -name "*.log" -mtime -1)
echo "$LOG_FILES" >> "$OUTPUT_FILE"

for LOG_FILE in $LOG_FILES; do  
  echo -e "\n=======================================" >> "$OUTPUT_FILE"
  echo "===== $LOG_FILE =====" >> "$OUTPUT_FILE"
  echo "=======================================" >> "$OUTPUT_FILE"
  for EPATTERN in ${ERROR_PATTERNS[@]}; do 
    echo -e "\nSearching $EPATTERN logs in $LOG_FILE file" >> "$OUTPUT_FILE"
    grep "$EPATTERN" "$LOG_FILE"

    echo -e "\nNumber of $EPATTERN logs found in $LOG_FILE" >> "$OUTPUT_FILE"
    ERROR_COUNT=$(grep -c "$EPATTERN" "$LOG_FILE")
    echo $EROR_COUNT  >> "$OUTPUT_FILE"
    if ["$ERROR_COUNT" -gt 10 ]; then
      echo "Action required for $EPATTERN in $LOG_FILE"   >> "$OUTPUT_FILE"
    fi  
  done
done

