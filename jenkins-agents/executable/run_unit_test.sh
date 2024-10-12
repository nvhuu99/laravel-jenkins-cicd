#!/bin/bash

# Initialize variables
APP_NAMESPACE=""
TEST_LOG_FILE_DEST=""
JUNIT_FILE_DEST=""

# Parse the arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --app-namespace=*) APP_NAMESPACE="${1#*=}";;
        --log-file=*) TEST_LOG_FILE_DEST="${1#*=}";;
        --junit-file=*) JUNIT_FILE_DEST="${1#*=}";;
        *) echo "Unknown option: $1"; exit 1;;
    esac
    shift
done

# Ensure required parameters are provided
if [[ -z "$APP_NAMESPACE" || -z "$TEST_LOG_FILE_DEST" || -z "$JUNIT_FILE_DEST" ]]; then
    echo "Error: All parameters (--app-namespace, --log-file, --junit-file) are required."
    exit 1
fi

# Prepare directory
REMOTE_DEST=/home/jenkins-builds/${JOB_NAME}/${BUILD_NUMBER}
TEST_LOG_FILE_REMOTE=$REMOTE_DEST/unit-test.log
JUNIT_FILE_REMOTE=$REMOTE_DEST/junit.xml
ssh default "sudo mkdir -p $REMOTE_DEST && sudo chown -R \$(whoami):\$(whoami) $REMOTE_DEST" || { echo "Failed to prepare directory for unit test"; exit 1; }

# Get application pod name
APP_POD=$(ssh default "kubectl get pods -n $APP_NAMESPACE -l app=laravel -o jsonpath='{.items[0].metadata.name}'" 2>/dev/null) || { echo "Error: Failed to get app pod name"; exit 1; }
# Run database migration
ssh default "kubectl exec $APP_POD -n $APP_NAMESPACE -- /bin/sh -c \"cd /var/www/html/laravel-app && php artisan migrate\"" || { echo "Error: Failed to migrate database"; exit 1; }
# Run unit test and save the logs
ssh default "(kubectl exec $APP_POD -n $APP_NAMESPACE -- /bin/sh -c \"cd /var/www/html/laravel-app && vendor/bin/phpunit\") > $TEST_LOG_FILE_REMOTE 2>&1"
TEST_RESULT=$? # Capture the exit code of the phpunit command
ssh default "(kubectl exec $APP_POD -n $APP_NAMESPACE -- /bin/sh -c \"cat /var/www/html/laravel-app/build/logs/junit.xml\") > $JUNIT_FILE_REMOTE"
# Secure copy the logs from remote
scp default:$TEST_LOG_FILE_REMOTE $TEST_LOG_FILE_DEST
scp default:$JUNIT_FILE_REMOTE $JUNIT_FILE_DEST

if [[ $TEST_RESULT -eq 0  ]]; then
    exit 0
fi

exit 1
