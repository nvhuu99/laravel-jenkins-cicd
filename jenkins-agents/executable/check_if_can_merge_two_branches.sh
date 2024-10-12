#!/bin/bash

# Description: 
# - This script determines if the 'source' and 'target' branches can be merged/rebased.
#
# Arguments: 
# --source - The branch contains new changes (e.g., 'integration').
# --target - The branch to check-in new changes (e.g., 'feature_A').
# --temporary - The merge will not be done on the 'target' branch, instead a temporary branch is created during this script execution to perform a test merge.
# 
# Exit Codes:
# - 0: The source and target branches can be safely merge (or rebase if the target branch is a private branch of a developer). The temporary branch is kept for further actions.
# - 1: They can't be safely merge (may be there are unexpected errors, or conflicts). The temporary branch is removed.

SOURCE=""
TARGET=""
TEMPORARY=""

# Prepare directories
SCRIPT_NAME=check_if_can_merge_two_branches
ERR_LOG_FILE=$WORKSPACE/$BUILD_NUMBER/err.log
CONFLICT_LOG_FILE=$WORKSPACE/$BUILD_NUMBER/conflict.log

# Parse the arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --target=*) TARGET="${1#*=}";;
        --source=*) SOURCE="${1#*=}";;
        --temporary=*) TEMPORARY="${1#*=}";;
        *) echo "Unknown option: $1"; exit 1;;
    esac
    shift
done

# Check if required parameters are provided
if [[ -z $TARGET || -z $SOURCE || -z $TEMPORARY ]]; then
    echo "Error: --target, --source, and --temporary are required"
    exit 1
fi

# Navigate to git repository
cd $APP_SRC || { echo "Error: Directory $APP_SRC does not exist"; exit 1; }

# Pull branches
(git checkout $SOURCE && git pull) > /dev/null 2>&1 || { echo "Error: Failed to checkout/pull source branch"; exit 1; }
(git checkout $TARGET && git pull) > /dev/null 2>&1 || { echo "Error: Failed to checkout/pull target branch"; exit 1; }

# Create temporary branch
(git switch -c $TEMPORARY) > /dev/null 2>&1 || { echo "Error: Failed to create temporary branch"; exit 1; }
echo "A temporary branch has been created from '$TARGET'"
echo "Temporary branch name: $TEMPORARY"

# Merge the source branch to the temporary branch (logs recorded)
echo "'$TEMPORARY' will be merged from '$SOURCE' to check if a merge/rebase is possible"
git merge $SOURCE > $ERR_LOG_FILE 2>&1

MERGE_STATUS=$?
if [ $MERGE_STATUS -eq 0 ]; then
    echo "Merged on temporary branch OK. '$SOURCE' and '$TARGET' can now be safely merged/rebased"
    echo "'$TEMPORARY' branch is kept for further actions, but safe to delete"

    exit 0
else
    echo "Error: Merge failed due to an unexpected error occurred. Check for possible merge conflicts in: $CONFLICT_LOG_FILE"
    echo "Error: '$SOURCE' and '$TARGET' are not safe to be merged/rebased"

    (git diff > $CONFLICT_LOG_FILE)
    (git merge --abort) > /dev/null 2>&1
    (git switch $TARGET) > /dev/null 2>&1
    (git branch -D $TEMPORARY) > /dev/null 2>&1

    exit 1
fi
