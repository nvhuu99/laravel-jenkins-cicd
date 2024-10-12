#!/bin/bash

# Initialize variables
APP_IMAGE=""
APP_NAMESPACE=""
DB_NAME=""
DB_USER=""
DB_PASSWORD=""

# Parse the arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --app-image=*) APP_IMAGE="${1#*=}";;
        --app-namespace=*) APP_NAMESPACE="${1#*=}";;
        --db-name=*) DB_NAME="${1#*=}";;
        --db-user=*) DB_USER="${1#*=}";;
        --db-password=*) DB_PASSWORD="${1#*=}";;
        *) echo "Unknown option: $1"; exit 1;;
    esac
    shift
done

# Ensure required parameters are provided
if [[ -z $APP_IMAGE || -z $APP_NAMESPACE || -z $DB_NAME || -z $DB_USER || -z $DB_PASSWORD ]]; then
    echo "Error: All parameters (--app-image, --app-namespace, --db-name, --db-user, --db-password) are required."
    exit 1
fi

# Create directories locally and remotely
SSH_DEST=/home/jenkins-builds/${JOB_NAME}/${BUILD_NUMBER}
ssh default "sudo mkdir -p $SSH_DEST && sudo chown -R \$(whoami):\$(whoami) $SSH_DEST" > /dev/null 2>&1

# List of deployment files
DEPLOYMENT_FILES=(
    mysql-pvc.yaml 
    mysql-secret.yaml 
    mysql-deployment.yaml
    laravel-deployment.yaml
)
# Loop through deployment files
for file in "${DEPLOYMENT_FILES[@]}"; do
    SRC_FILE="$JENKINS_SCRIPTS/$file"
    DEST_FILE="$WORKSPACE/$BUILD_NUMBER/$file"

    if [[ -f "$SRC_FILE" ]]; then
        # Copy and replace placeholders
        cp $SRC_FILE $DEST_FILE
        sed -i "s|\[\[APP_IMAGE\]\]|$APP_IMAGE|g" $DEST_FILE
        sed -i "s|\[\[APP_NAMESPACE\]\]|$APP_NAMESPACE|g" $DEST_FILE
        sed -i "s|\[\[DB_NAME\]\]|$DB_NAME|g" $DEST_FILE
        sed -i "s|\[\[DB_USER\]\]|$(echo -n $DB_USER | base64)|g" $DEST_FILE
        sed -i "s|\[\[DB_PASSWORD\]\]|$(echo -n $DB_PASSWORD | base64)|g" $DEST_FILE
        # Transfer files to remote server
        scp $DEST_FILE default:$SSH_DEST/ > /dev/null 2>&1 || { exit 1; }
    else
        exit 1
    fi
done

# Deploy to the cluster
if ! ssh default "kubectl get namespace $APP_NAMESPACE" > /dev/null 2>&1; then
    ssh default "kubectl create namespace $APP_NAMESPACE" > /dev/null 2>&1 || { echo "Error: failed to create cluster namespace $APP_NAMESPACE"; exit 1; }
fi
ssh default "kubectl apply -f $SSH_DEST/mysql-pvc.yaml -n $APP_NAMESPACE" > /dev/null 2>&1 || { echo "Error: Failed to apply mysql-pvc.yaml"; exit 1; }
ssh default "kubectl apply -f $SSH_DEST/mysql-secret.yaml -n $APP_NAMESPACE" > /dev/null 2>&1 || { echo "Error: Failed to apply mysql-secret.yaml"; exit 1; }
ssh default "kubectl apply -f $SSH_DEST/mysql-deployment.yaml -n $APP_NAMESPACE" > /dev/null 2>&1 || { echo "Error: Failed to apply mysql-deployment.yaml"; exit 1; }
ssh default "kubectl apply -f $SSH_DEST/laravel-deployment.yaml -n $APP_NAMESPACE" > /dev/null 2>&1 || { echo "Error: Failed to apply laravel-deployment.yaml"; exit 1; }

# Wait for app pod ready and exit
APP_POD=$(ssh default "kubectl get pods -n $APP_NAMESPACE -l app=laravel -o jsonpath='{.items[0].metadata.name}'" 2>/dev/null) || { exit 1; }
ATTEMPTS=10
DELAY=5
for (( i=1; i<=$ATTEMPTS; i++ )); do
    echo "Attempt $i: Checking pod status..."

    STATUS=$(ssh default "kubectl get pod $APP_POD -n $APP_NAMESPACE -o jsonpath='{.status.phase}'" 2>/dev/null)

    if [[ "$STATUS" == "Running" ]]; then
        echo "Pod $POD_NAME is running."
        exit 0
    fi

    echo "Pod $POD_NAME is not running. Status: $STATUS"
    sleep $DELAY
done

echo "Pod $APP_POD did not reach 'Running' status within $ATTEMPTS attempts."
exit 1
