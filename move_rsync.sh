#!/bin/bash
# Purpose: Perform rsync move safely, pause, and clean up source according to parameter
#          This is a common script to move application log from live server to backup server, thus to release space
# Usage: ./move_rsync_controlled.sh 1|2|3
# chmod +x 

SRC="/volume1/home/admin/R32S/Live"
DEST="/volume1/home/admin/R32S/Backup"
LOCK="/tmp/move_rsync_controlled.lock"

# --- Single-instance lock ---
if ! mkdir "$LOCK" 2>/dev/null; then
    echo "Another instance is already running. Exiting."
    exit 1
fi
trap 'rmdir "$LOCK"' EXIT

# --- Parameter validation ---
MODE="$1"
if [[ -z "$MODE" ]]; then
    echo "Usage: $0 [1|2|3]”
    exit 1
fi

# --- Perform rsync operation ---
echo "Starting rsync move from $SRC to $DEST..."
rsync -avh --remove-source-files --progress "$SRC"/ "$DEST"/
STATUS=$?

if [[ $STATUS -ne 0 ]]; then
    echo "Rsync failed with exit code $STATUS — aborting cleanup."
    exit $STATUS
fi
echo "Rsync completed successfully."

# --- Pause for 60 seconds ---
echo "Pausing for 60 seconds before cleanup..."
sleep 60
echo "Resuming."

# --- Cleanup depending on mode ---
case "$MODE" in
    1)
        echo "Mode 1: Clearing all files but keeping directory structure..."
        find "$SRC" -type f -delete
        ;;
    2)
        echo "Mode 2: Removing empty subfolders..."
        find "$SRC" -type d -empty -delete
        ;;
    3)
        echo "Mode 3: Clearing files and removing empty subfolders..."
        find "$SRC" -type f -delete
        find "$SRC" -type d -empty -delete
        ;;
    *)
        echo "Invalid parameter. Use 1, 2, or 3.”
        exit 1
        ;;
esac

echo "Cleanup task completed successfully."
