#!/bin/bash

# Description: 
# - This script determines if the 'source' branch contains works that are not yet available on the 'target' branch.
# 
# Arguments: 
# --source - The branch contains new changes (e.g., 'integration').
# --target - The branch to check-in new changes (e.g., 'feature_A').
# 
# Exit Codes:
# - Exit code 0: Changes detected (merge is recommended).
# - Exit code 1: Unexpected errors.
# - Exit code 2: No changes to merge (nothing to merge).

SOURCE=""
TARGET=""

# Prepare directories
SCRIPT_NAME=check_for_diffs_from_two_branches
DIFF_LOG_FILE=$WORKSPACE/$BUILD_NUMBER/$SCRIPT_NAME.diff

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
(git checkout $TARGET && git pull) > /dev/null 2>&1 || { echo "Error: Failed to checkout/pull $TARGET branch"; exit 1; }

(git checkout $SOURCE && git pull) > /dev/null 2>&1 || { echo "Error: Failed to checkout/pull $SOURCE branch"; exit 1; }

git diff --exit-code $TARGET..$SOURCE > $DIFF_LOG_FILE

DIFF_STATUS=$?

if [[ $DIFF_STATUS -eq 1 ]]; then
    echo "Changes detected for $TARGET and $SOURCE. Diff logs have been written: $DIFF_LOG_FILE"
    exit 0
elif [[ $DIFF_STATUS -eq 0 ]]; then
    echo "No changes detected for $TARGET and $SOURCE"
    rm $DIFF_LOG_FILE
    exit 2
else
    echo "Error: unexpected error"
    rm $DIFF_LOG_FILE
    exit 1
fi
