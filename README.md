If you are reading this, you are definetly a web developper looking for an easy way to deploy your Laravel app manually, avoiding extra charges that comes with subscribing to application deployment service such as [Laravel Forge](https://forge.laravel.com/).

I will share with you a deployment script that you can run on your server terminal, and you will see how fast and easy is Laravel App Deployment. On the next lines, I will walk you through each line on the script so you can understand what is going under the hood.

## Prerequisites
All what you need is an **Ubuntu server**, a **GitHub repo** and a **SSH key** to access your server terminal. Log into your server as root user (you can create a different user name and give him privileges that you need, but for the sake of the tutorial we will stick to root user). We will be using Nginx to serve our application.

## 1. Install Nginx:
Nginx is a high-performance web server software. It is used to serve web pages to users and can also handle other tasks like load balancing and reverse proxying for improved website performance and reliability.
Think of Nginx as a highly efficient post office. In this analogy, the web requests are like letters and packages (emails, website content requests, etc.). Just as a post office receives, sorts, and dispatches mail to various destinations, Nginx receives web requests, processes them, and directs them to the appropriate web pages or servers.

So let’s install Nginx on our ubuntu server.

1-For first use, maybe you need to think updating your server’s package index:

```
$ sudo apt update
```
2- Now let’s install Nginx:

```
$ sudo apt install nginx
```
3- For this tutorial we will allow regular HTTP traffic:

```
$ sudo ufw allow 'Nginx HTTP'
```

## 2.Install MySQL:
You will need to install a database system to store and manage data for your site once you have a web server up and running.

You will need to install a database system to store and manage data for your site once you have a web server up and running.

To acquire and install this software, use apt:

```
$ sudo apt install mysql-server
```

## 3.Install PHP:
Your setup includes Nginx for content delivery and MySQL for data storage and management. To enable dynamic content generation via PHP processing, you can add PHP to your system.

Unlike Apache, which integrates PHP processing within each request, Nginx operates differently. It relies on an external tool to process PHP, serving as a link between the PHP interpreter and the web server. This approach typically enhances the performance for PHP-driven websites, but it does require some extra setup. You should install php8.1-fpm (PHP FastCGI Process Manager), which corresponds to the latest PHP version at this time. This software will manage PHP processing requests for Nginx. In addition, install ‘php-mysql’, a necessary PHP extension for interacting with MySQL databases. Rest assured, the main PHP components will be installed automatically as part of these dependencies.

To get php8.1-fpm and php-mysql up and running, execute the following command:

```
$ sudo apt install php8.1-fpm php-mysql
```

## 4.Install Composer:
Run the following command to install required packages:

```
$ sudo apt install php-cli unzip
```
To install Composer, a dependency management tool in PHP, you’ll first download its installer script, ensure its integrity, and then use it for installation. Follow these steps:

**1-Navigate to your Home directory:**

```
cd ~
```
**2-Download Installer:**
Use curl to download the Composer installer script into a temporary directory:

```
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
```
**3.Verify Installer:**
It’s crucial to verify that the downloaded script is authentic and hasn’t been tampered with. You can do this by comparing the SHA-384 hash of the downloaded file with the official hash provided on the Composer Public Keys/Signatures page. To streamline this process, use the following command. It automatically fetches the latest hash from Composer’s page and stores it in a shell variable:

```
HASH=`curl -sS https://composer.github.io/installer.sig`
```
This command will retrieve the current hash for the Composer installer and store it in a variable named HASH. You can then use this variable to validate the integrity of the downloaded installer script.

Now execute the following PHP code, as provided in the Composer download page, to verify that the installation script is safe to run:

```
php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
```
To install composer globally, use the following command which will download and install Composer as a system-wide command named composer, under /usr/local/bin:

```
$ sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
```

## 5.Install Laravel required packages:

```
$ sudo apt install php-mbstring php-xml php-bcmath php-curl
```

## 6.Create SSH key:
Now you need to generate a SSH key and save it in your GitHub deploy keys. In your server terminal run the following command:

```
ssh-keygen -t ed25519 -C "your_email@example.com"
```
You will be prompted with some settings, you can skip it by pressing `ENTER`

Now run the following command to copy your SSH key:

```
cat ~/.ssh/id_rsa.pub
```
Next you will need to copy the SSH key and paste on your repo settings, on the deploy key section.
 
Add a title and paste you ssh key then press Add key.

Now you are all set and ready to clone your repo into your server. But before that we will install nodejs and npm since you will need to serve your laravel app.

**Install nodejs and npm:**

```
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g npm@8.19.4
```

**Clone Github Repo:**
Now let’s create a folder for our Laravel app, we will use the github repository name as a folder name in this tutorial:

```
cd /var/www

```

```
git clone your_github_ssh_remote_url your_repo_name
```
Now we need to give the web server user write access to the storage and cache folders, where Laravel stores application-generated files:

```
$ sudo chown -R www-data:www-data /var/www/your_repo_name/storage /var/www/your_repo_name/bootstrap/cache
$ sudo chmod -R 775 /var/www/your_repo_name/storage /var/www/your_repo_name/bootstrap/cache
```
The application files are now in order, but we still need to configure Nginx to serve the content. To do this, we’ll create a new virtual host configuration file at /etc/nginx/sites-available:

```
sudo nano /etc/nginx/sites-available/your_repo_name
```
Then paste the following into the configuration file:

```
server {
    listen 80;
    server_name server_domain_or_IP;
    root /var/www/your_repo_name/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

To activate the new virtual host configuration file, create a symbolic link to your_repo in sites-enabled:

```
sudo ln -s /etc/nginx/sites-available/your_repo_name /etc/nginx/sites-enabled/
```
To confirm that the configuration doesn’t contain any syntax errors, you can use:

```
$ sudo nginx -t
```
To apply the changes, reload Nginx with:

```
$ sudo systemctl reload nginx
```
**The deploy script:**
Go to [https://github.com/Medsek233/Deploy.git](https://github.com/Medsek233/Deploy.git) and copy the content of the file setup_server.sh:

On your terminal, run the following commands:
**1.Create a file with the script:**You can use a text editor such as nano to create and edit a new file. Type the following command to create a file named deploy_laravel.sh:

```
nano deploy_laravel.sh
```
This command will open the nano text editor. Copy and paste the deployment script into this editor.

```
#!/bin/bash

# Prompt for user input
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

# Test and reload Nginx
echo "Testing Nginx configuration..."
sudo nginx -t
echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "Deployment completed. Please navigate to http://$your_domain or the server's IP to check your Laravel application."
```

**2.Save the file:** In nano, after pasting the script, you can save the file by pressing `Ctrl + O`, then `Enter`, and exit nano by pressing `Ctrl + X`.
**3.Make the script executable:** To make the script file executable, use the chmod command:

```
chmod +x deploy_laravel.sh

```
This command changes the file’s mode so that it’s executable.
**4.Run the script:** Finally, execute the script with the following command:

```
./deploy_laravel.sh
```

## Run composer install:
cd into your laravel app folder:

```
cd /var/www/your_repo_name
```
Run :

```
composer install --optimize-autoloader --no-dev
```
Now you will need to create your .env file:

```
cp .env.example .env
```
Then modify your .env file:

```
nano .env
```
You will need to setup your app and mysql table, so I will provide you with all commands that you will need to run on your terminal:

```
php artisan key:generate
npm install
npm build
php artisan config:cache
php artisan event:cache
php artisan view:cache
```
For mysql DB setup, run the following commands:

```
cd ~
```

```
sudo mysql
```

```
CREATE DATABASE your_db_name;
```

```
CREATE USER 'user_name'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
```

```
GRANT ALL ON your_db_name.* TO 'user_name'@'%';

```

```
exit
```
Then go back to your app folder and update your .env file with DB_name and DB_username and password. And then run:

```
php artisan migrate
```
Don’t forget to switch the debug_mode and environment.
You will find also the [Project setup script](https://github.com/Medsek233/Deploy/blob/main/project_setup.sh) on the [GitHub repo](https://github.com/Medsek233/Deploy).


