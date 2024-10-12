#!/bin/bash

BUILD_NUMBER="${BUILD_NUMBER:-null}"
BACKUP_SHELL="$JENKINS_SCRIPTS/jenkins_backup.sh"

# Check if BACKUP_DIR exists
if [ ! -e $BACKUP_SHELL ]; then
    echo "Jenkins backup execution is not found. Update canceled. ($BACKUP_SHELL)";
    exit 1;
fi

# Create backup before update
sh "$BACKUP_SHELL" || { echo "Failed to create Jenkins backup. Update canceled"; exit 1; } 

# Stop jenkins
echo "Shutdown Jenkins."
kill $( ps -U jenkins | grep java | awk '{print $1}' )

# Update & install
apt-get update && apt-get --only-upgrade install jenkins
echo "Jenkins updated."

# Restart Jenkins
service jenkins start

exit 0
