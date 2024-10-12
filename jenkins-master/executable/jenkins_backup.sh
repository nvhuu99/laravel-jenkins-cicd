#!/bin/bash

# Set the variables
USR=$(whoami)
BUILD_NUMBER=${BUILD_NUMBER:-null}  # If BUILD_NUMBER is not set, use "null"
DATE=$(date +"%Y%m%d%H%M%S")        # Get current date in YmdHMS format
BACKUP_FILENAME="backup-$USR-$BUILD_NUMBER-$DATE.tar"
BACKUP_FILEPATH="$JENKINS_BACKUP/$BACKUP_FILENAME"

# Create the backup directory if it doesn't exist
if [ ! -d $JENKINS_BACKUP ]; then
    mkdir -p "$JENKINS_BACKUP"
    chown -R jenkins:jenkins $JENKINS_BACKUP
fi

# Archive the Jenkins directory
echo "Archiving $JENKINS_HOME into $BACKUP_FILEPATH..."
tar -cf "$BACKUP_FILEPATH" -C "$JENKINS_HOME" . || { echo "Failed to created backup."; exit 1; }

# Set the owner/group of the .tar file to jenkins
chown jenkins:jenkins "$BACKUP_FILEPATH"

# Confirm the backup process is complete
echo "Backup complete: $BACKUP_FILEPATH"

# Exit successfully
exit 0
