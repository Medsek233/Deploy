#!/bin/bash

# Prompt for user input
read -p "Enter your laravel app folder: " your_laravel_app_folder
read -p "Enter your database name: " your_db_name
read -p "Enter your database username: " user_name
read -p "Enter your database user password: " password

# Run Composer Install
echo "Running composer install..."
composer install --optimize-autoloader --no-dev

# Copy .env.example to .env
echo "Copying .env.example to .env..."
cp .env.example .env

# Open .env file for editing - user needs to manually update the environment variables
echo "Please update the .env file with your environment settings."
nano .env

# Install npm dependencies and build
echo "Installing npm dependencies and building..."
npm install
npm run build

# Cache configurations
echo "Caching configurations..."
php artisan key:generate
php artisan config:cache
php artisan event:cache
php artisan view:cache

# Set up MySQL Database
echo "Setting up MySQL Database..."
sudo mysql -e "CREATE DATABASE $your_db_name;"
sudo mysql -e "CREATE USER '$user_name'@'%' IDENTIFIED WITH mysql_native_password BY '$password';"
sudo mysql -e "GRANT ALL ON $your_db_name.* TO '$user_name'@'%';"

# Migrate the database
echo "Running migrations..."
php artisan migrate

# Set ownership for Laravel storage and cache
echo "Setting permissions for storage and cache..."
sudo chown -R www-data:www-data /var/www/$your_laravel_app_folder/storage /var/www/$your_laravel_app_folder/bootstrap/cache
sudo chmod -R 775 /var/www/$your_laravel_app_folder/storage /var/www/$your_laravel_app_folder/bootstrap/cache

echo "Laravel project setup completed. Remember to switch the debug_mode and environment in your .env file if needed."
