#!/bin/bash

# Prompt for user input
read -p "Enter your email for SSH key generation: " your_email
read -p "Enter your Git SSH remote URL: " your_ssh_remote_url
read -p "Enter your GitHub repository name: " your_repo_name
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
echo "Cloning repository $your_ssh_remote_url..."
cd /var/www
git clone $your_ssh_remote_url $your_repo_name

echo "Configuring Nginx for $your_repo_name..."
nginx_config="/etc/nginx/sites-available/$your_repo_name"
sudo bash -c "cat > $nginx_config <<EOF
server {
    listen 80;
    server_name $your_domain;
    root /var/www/$your_repo_name/public;

    add_header X-Frame-Options 'SAMEORIGIN';
    add_header X-XSS-Protection '1; mode=block';
    add_header X-Content-Type-Options 'nosniff';

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php\$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF"
sudo ln -s /etc/nginx/sites-available/$your_repo_name /etc/nginx/sites-enabled/

# Set ownership for Laravel storage and cache
echo "Setting permissions for storage and cache..."
sudo chown -R www-data:www-data /var/www/$your_repo_name/storage /var/www/$your_repo_name/bootstrap/cache
sudo chmod -R 775 /var/www/$your_repo_name/storage /var/www/$your_repo_name/bootstrap/cache

# Test and reload Nginx
echo "Testing Nginx configuration..."
sudo nginx -t
echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "Deployment completed. Please navigate to http://$your_domain or the server's IP to check your Laravel application."
