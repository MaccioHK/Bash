#!/bin/bash

LOG_DIR="/usr/app/logs"
ERROR_PATTERNS=("ERROR" "EXCEPTION" "FATAL" "DISCOUNT" "ROLLBACK")
RECIPIENTS="user1@example.com,user2@example.com,user3@example.com"  # Comma-separated list
SUBJECT="Log Analysis Report - $(date +%Y%m%d)"
SENDER="sender@example.com"

# Get current date in YYYYMMDD format
CURRENT_DATE=$(date +%Y%m%d)

# Find the highest existing sequence number for today's date
LOG_BASE="$LOG_DIR/${CURRENT_DATE}_"
EXISTING_LOGS=$(find "$LOG_DIR" -name "${CURRENT_DATE}_*.log" -type f | sort)
if [ -z "$EXISTING_LOGS" ]; then
  SEQ_NUM="0001"
else
  LAST_LOG=$(echo "$EXISTING_LOGS" | tail -n 1)
  LAST_SEQ=$(basename "$LAST_LOG" .log | cut -d'_' -f2)
  SEQ_NUM=$(printf "%04d" $((10#$LAST_SEQ + 1)))
fi

# Set output file name
OUTPUT_FILE="${LOG_BASE}${SEQ_NUM}.log"

# Ensure LOG_DIR exists
mkdir -p "$LOG_DIR"

echo "Analysing the log files" > "$OUTPUT_FILE"
echo "=======================" >> "$OUTPUT_FILE"

echo -e "\nList of log files updated in last 24 hours" >> "$OUTPUT_FILE"
LOG_FILES=$(find "$LOG_DIR" -name "*.log" -mtime -1)
echo "$LOG_FILES" >> "$OUTPUT_FILE"

for LOG_FILE in $LOG_FILES; do
  echo -e "\n=======================================" >> "$OUTPUT_FILE"
  echo "===== $LOG_FILE =====" >> "$OUTPUT_FILE"
  echo "=======================================" >> "$OUTPUT_FILE"
  for EPATTERN in "${ERROR_PATTERNS[@]}"; do
    echo -e "\nSearching $EPATTERN logs in $LOG_FILE file" >> "$OUTPUT_FILE"
    grep "$EPATTERN" "$LOG_FILE" >> "$OUTPUT_FILE" 2>/dev/null || true

    echo -e "\nNumber of $EPATTERN logs found in $LOG_FILE" >> "$OUTPUT_FILE"
    ERROR_COUNT=$(grep -c "$EPATTERN" "$LOG_FILE" 2>/dev/null || echo 0)
    echo "$ERROR_COUNT" >> "$OUTPUT_FILE"
    if [ "$ERROR_COUNT" -gt 10 ]; then
      echo "Action required for $EPATTERN in $LOG_FILE" >> "$OUTPUT_FILE"
    fi
  done
done

# Send the output file as an email attachment
if [ -f "$OUTPUT_FILE" ]; then
  echo "Sending $OUTPUT_FILE to recipients: $RECIPIENTS"
  mutt -s "$SUBJECT" -a "$OUTPUT_FILE" -- $RECIPIENTS < /dev/null
  if [ $? -eq 0 ]; then
    echo "Email sent successfully to $RECIPIENTS"
  else
    echo "Failed to send email to $RECIPIENTS"
  fi
else
  echo "Error: $OUTPUT_FILE was not created"
fi
