#!/bin/bash

# Prompt for user input
read -p "Enter your email for SSH key generation: " your_email
read -p "Enter your GitHub username: " your_github_username
read -p "Enter your repository name: " your_repo
read -p "Enter your domain name: " your_domain

# Update and install Nginx
echo "Updating package index..."
sudo apt update

echo "Installing Nginx..."
sudo apt install nginx -y

echo "Allowing HTTP traffic on Nginx..."
sudo ufw allow 'Nginx HTTP'

# Install MySQL
echo "Installing MySQL..."
sudo apt install mysql-server -y

# Install PHP
echo "Installing PHP and necessary extensions..."
sudo apt install php8.1-fpm php-mysql -y

# Configure Nginx to use PHP processor
echo "Setting up directories for $your_domain..."
sudo mkdir -p /var/www/$your_domain
sudo chown -R $USER:$USER /var/www/$your_domain

echo "Configuring Nginx for $your_domain..."
sudo nano /etc/nginx/sites-available/$your_domain
sudo ln -s /etc/nginx/sites-available/$your_domain /etc/nginx/sites-enabled/

# Install Composer
echo "Installing Composer..."
sudo apt install php-cli unzip -y
cd ~
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
HASH=$(curl -sS https://composer.github.io/installer.sig)
php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Install additional PHP packages required by Laravel
echo "Installing additional PHP packages..."
sudo apt install php-mbstring php-xml php-bcmath php-curl -y

# Generate SSH key for GitHub
echo "Generating SSH key..."
ssh-keygen -t ed25519 -C "$your_email"
echo "Please add the following SSH key to your GitHub deploy keys."
cat ~/.ssh/id_rsa.pub

# Install Node.js and npm
echo "Installing Node.js and npm..."
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g npm@8.19.4

# Clone GitHub Repo
echo "Cloning repository $your_repo..."
cd /var/www
git clone git@github.com:$your_github_username/$your_repo.git

# Set ownership for Laravel storage and cache
echo "Setting permissions for storage and cache..."
sudo chown -R www-data.www-data /var/www/$your_repo/storage
sudo chown -R www-data.www-data /var/www/$your_repo/bootstrap/cache

# Create Nginx config for cloned repo
echo "Configuring Nginx for $your_repo..."
sudo nano /etc/nginx/sites-available/$your_repo
sudo ln -s /etc/nginx/sites-available/$your_repo /etc/nginx/sites-enabled/

# Test and reload Nginx
echo "Testing Nginx configuration..."
sudo nginx -t
echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "Deployment completed. Please navigate to http://$your_domain or the server's IP to check your Laravel application."
