#!/bin/bash

SOURCE=""
TARGET=""
FAIL_REASON=""
EMAIL_FILE_NAME=""

# Parse the arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --target=*) TARGET="${1#*=}";;
        --source=*) SOURCE="${1#*=}";;
        --fail-reason=*) FAIL_REASON="${1#*=}";;
        --email-file-name=*) EMAIL_FILE_NAME="${1#*=}";;
        *) echo "Unknown option: $1"; exit 1;;
    esac
    shift
done

# Check if required parameters are provided
if [[ -z "$TARGET" || -z "$SOURCE" || -z "$EMAIL_FILE_NAME" || -z "$FAIL_REASON" ]]; then
    echo "Error: --target, --source, --email-file-name, --fail-reason are required"
    exit 1
fi

# Prepare directories
DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
TEMPLATE_DIR=$JENKINS_SCRIPTS/template
EMAIL_FILE=$WORKSPACE/$BUILD_NUMBER/$EMAIL_FILE_NAME

# Change work directory
cd $WORKSPACE/$BUILD_NUMBER

# Get the template name according to the script that failed
if [[ $FAIL_REASON -eq 'MERGE_FAILED' ]]; then
    EMAIL_TEMPLATE=$TEMPLATE_DIR/merge_failure_email.template
elif [[ $FAIL_REASON -eq 'FAILED_TEST' ]]; then
    EMAIL_TEMPLATE=$TEMPLATE_DIR/unit_test_failure_email.template
else
    EMAIL_TEMPLATE=$TEMPLATE_DIR/unexpected_error_email.template
fi

# Copy the template
cp $EMAIL_TEMPLATE $EMAIL_FILE

# Fill the template placeholders with values
sed -i "s/\[\[SOURCE\]\]/$SOURCE/" "$EMAIL_FILE"
sed -i "s/\[\[TARGET\]\]/$TARGET/" "$EMAIL_FILE"
sed -i "s/\[\[JOB_NAME\]\]/$JOB_NAME/" "$EMAIL_FILE"
sed -i "s/\[\[BUILD_NUMBER\]\]/$BUILD_NUMBER/" "$EMAIL_FILE"
sed -i "s/\[\[DATETIME\]\]/$DATETIME/" "$EMAIL_FILE"

exit 0
