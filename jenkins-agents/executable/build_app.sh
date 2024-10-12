#!/bin/bash

APP_ENV=""
APP_IMAGE=""
BUILD_BRANCH=""
DB_NAME=""
DB_USER=""
DB_PASSWORD=""

# Parse the arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --app-env=*) APP_ENV="${1#*=}";;
        --app-image=*) APP_IMAGE="${1#*=}";;
        --build-branch=*) BUILD_BRANCH="${1#*=}";;
        --db-name=*) DB_NAME="${1#*=}";;
        --db-user=*) DB_USER="${1#*=}";;
        --db-password=*) DB_PASSWORD="${1#*=}";;
        *) echo "Unknown option: $1"; exit 1;;
    esac
    shift
done

# Check if required parameters are provided
if [[ -z $APP_ENV ]]; then
    echo "Error: --app-env, --app-image, --build-branch,--db-name, --db-user, --db-password are required"
    exit 1
fi

# Setup application before build
cd $APP_SRC || { echo "Error: Directory $APP_SRC does not exist"; exit 1; }
(git checkout $BUILD_BRANCH && git pull) > /dev/null 2>&1 || { echo "Error: Failed to checkout/pull $BUILD_BRANCH branch"; exit 1; }
$JENKINS_SCRIPTS/setup_laravel_app.sh \
    --app-env="$APP_ENV" \
    --db-name="$DB_NAME" \
    --db-user="$DB_USER" \
    --db-password="$DB_PASSWORD" || { echo "Error: failed to setup laravel app before build"; exit 1; }

# Combine and run docker build
docker build \
    --build-arg APP_ENV="$APP_ENV" \
    --build-arg DB_NAME="$DB_NAME" \
    --build-arg DB_USER="$DB_USER" \
    --build-arg DB_PASSWORD="$DB_PASSWORD" \
    -t $APP_IMAGE \
    -f $JENKINS_SCRIPTS/dockerfile.app \
    $JENKINS_SCRIPTS || { echo "Error: failed to build app image: $APP_IMAGE"; exit 1; }

exit 0
