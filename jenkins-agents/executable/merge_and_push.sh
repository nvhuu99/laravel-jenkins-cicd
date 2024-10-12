#!/bin/bash

SOURCE=""
TARGET=""

# Prepare directories
SCRIPT_NAME=merge_and_push
ERR_LOG_FILE=$WORKSPACE/$BUILD_NUMBER/err.log
CONFLICT_LOG_FILE=$WORKSPACE/$BUILD_NUMBER/conflict.log

# Parse the arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --target=*) TARGET="${1#*=}";;
        --source=*) SOURCE="${1#*=}";;
        *) echo "Unknown option: $1"; exit 1;;
    esac
    shift
done

# Check if required parameters are provided
if [[ -z $TARGET || -z $SOURCE ]]; then
    echo "Error: --target, and --source are required"
    exit 1
fi

# Navigate to git repository
cd $APP_SRC || { echo "Error: Directory $APP_SRC does not exist"; exit 1; }

# Check for new changes
(git checkout $TARGET && git pull) > /dev/null 2>&1 || { echo "Error: Failed to checkout/pull target branch"; exit 1; }
(git checkout $SOURCE && git pull) > /dev/null 2>&1 || { echo "Error: Failed to checkout/pull source branch"; exit 1; }

# Store the SHA1 for backup, and merge
TARGET_HASH=$(git rev-parse $TARGET)
SOURCE_HASH=$(git rev-parse $SOURCE)

(git switch $TARGET && git merge --no-ff $SOURCE) > $ERR_LOG_FILE 2>&1
MERGE_STATUS=$?

# Merged successfully
if [[ $MERGE_STATUS -eq 0 ]]; then 
    (git push) > $ERR_LOG_FILE 2>&1 || { 
        # Reset to the previous state if we cannot push it to remote
        (git switch $TARGET && git reset --hard "$TARGET_HASH") > /dev/null 2>&1
        (git switch $SOURCE && git reset --hard "$SOURCE_HASH") > /dev/null 2>&1

        echo "Error: Failed to push to remote"; 
        exit 1; 
    }

    # Push successfully
    echo "Merged $SOURCE to $TARGET successfully"
    exit 0
# Merge failed
else
    # Log possible conflicts by extracting source diff on the target branch
    git diff > $CONFLICT_LOG_FILE
    # Abort rebase to bring the branch to the original state
    (git merge --abort) > /dev/null 2>&1

    echo "Error: Failed to merge $SOURCE and $TARGET. Check logs in: $ERR_LOG_FILE"
    echo "Error: Check conflicts in: $CONFLICT_LOG_FILE"
    exit 1
fi
