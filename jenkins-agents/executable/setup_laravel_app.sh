#!/bin/bash

APP_ENV=""
DB_NAME=""
DB_USER=""
DB_PASSWORD=""

# Parse the arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --app-env=*) APP_ENV="${1#*=}";;
        --db-name=*) DB_NAME="${1#*=}";;
        --db-user=*) DB_USER="${1#*=}";;
        --db-password=*) DB_PASSWORD="${1#*=}";;
        *) echo "Unknown option: $1"; exit 1;;
    esac
    shift
done

# Check if required parameters are provided
if [[ -z $APP_ENV ]]; then
    echo "Error: --app-env, --app-image, --db-name, --db-user, --db-password are required"
    exit 1
fi

# Change work dir
cd $APP_SRC || { exit 1; }

# Install vendors
composer install --no-interaction || { exit 1; }

# Set environment
cp -f .env.example .env
sed -i "s/DB_HOST=127.0.0.1/DB_HOST=mysql/" .env
sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$DB_NAME/" .env
sed -i "s/DB_USERNAME=root/DB_USERNAME=$DB_USER/" .env
sed -i "s/DB_PASSWORD=/DB_PASSWORD=\"$DB_PASSWORD\"/" .env

# Generate key
php artisan key:generate

# Install & build Npm
npm install -y || { exit 1; }
npm run build || { exit 1; }

exit 0