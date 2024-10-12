#!/bin/bash

BACKUP_SHELL="$JENKINS_SCRIPTS/jenkins_backup.sh"

# Get the backup filepath
if [ ! -z "$1" ]; then
    BACKUP_FILENAME=$(ls -t --time=creation $JENKINS_BACKUP | head -n 1)
    BACKUP_FILENAME="$JENKINS_BACKUP/$BACKUP_FILENAME"
else
    BACKUP_FILENAME=$1
fi

# Check backup exist 
if [ ! -e $BACKUP_FILENAME ]; then
    echo "Backup file not found: $BACKUP_FILENAME"
    exit 1
fi

# Create backup for current state
sh $BACKUP_SHELL || { echo "Failed to create backup for before restoration."; exit 1; }

# Stop jenkins
kill $( ps -U jenkins | grep java | awk '{print $1}' )

# Restoring backup
rm -r $JENKINS_DIR && tar -xf "$BACKUP_FILENAME" -C "/"
if [ $? -eq 0 ]; then
    echo "A Jenkins backup has been restored: $BACKUP_FILENAME"
else
    echo "Failed to restore backup: $BACKUP_FILENAME. Rolling back last state."

    RESTORE_FILENAME=$(ls -t --time=creation $JENKINS_BACKUP | head -n 1)
    RESTORE_FILENAME="$JENKINS_BACKUP/$RESTORE_FILENAME"
    rm -r $JENKINS_DIR && tar -xf "$RESTORE_FILENAME" -C "/"

    exit 1
fi

# Reset permission
chown -R jenkins:jenkins $JENKINS_DIR

# Restart Jenkins
service jenkins start
