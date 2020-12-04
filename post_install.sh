#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf nginx_enable="YES"
sysrc -f /etc/rc.conf php_fpm_enable="YES"
sysrc -f /etc/rc.conf mysql_enable="YES"

# Create php.ini
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
sed -i '' 's/.*max_execution_time =.*/max_execution_time = 200/' /usr/local/etc/php.ini
sed -i '' 's/.*post_max_size =.*/post_max_size = 100M/' /usr/local/etc/php.ini
sed -i '' 's/.*upload_max_filesize =.*/upload_max_filesize = 100M/' /usr/local/etc/php.ini
sed -i '' 's/.*memory_limit =.*/memory_limit = 256M/' /usr/local/etc/php.ini
sed -i '' 's/.*max_file_uploads =.*/max_file_uploads = 100/' /usr/local/etc/php.ini

# Create www.conf
cp /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf
sed -i '' 's/;listen.owner/listen.owner/' /usr/local/etc/php-fpm.d/www.conf
sed -i '' 's/;listen.group/listen.group/' /usr/local/etc/php-fpm.d/www.conf
sed -i '' 's/;listen.mode/listen.mode/' /usr/local/etc/php-fpm.d/www.conf
sed -i '' 's/.*listen = 127.0.0.1:9000.*/listen = \/tmp\/php7.4-fpm.sock/' /usr/local/etc/php-fpm.d/www.conf

# Generate sql credential
USER="lychee"
DB="lychee"
export LC_ALL=C
PASS=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`

# Write credential into plugin_config file
echo "Database Name: $DB" > /root/PLUGIN_INFO
echo "Database User: $USER" >> /root/PLUGIN_INFO
echo "Database Password: $PASS" >> /root/PLUGIN_INFO
echo "Database Admin Password: $PASS" >> /root/PLUGIN_INFO

# Fetch lychee
mkdir /usr/local/www/lychee
cd /usr/local/www/lychee
git clone --recurse-submodules https://github.com/LycheeOrg/Lychee.git .

# Start services
service php-fpm start
sleep 5
service mysql-server start
sleep 5

# Init sql
mysql -u root --connect-expired-password <<-EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${PASS}';
ALTER USER 'mysql'@'localhost' IDENTIFIED BY '${PASS}';
CREATE DATABASE \`${DB}\` DEFAULT CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_unicode_ci';
CREATE USER '${USER}'@'${DB}' IDENTIFIED BY '${PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'${DB}';
FLUSH PRIVILEGES;
EOF

# Prepare lychee
cd /usr/local/www/lychee/
composer install --no-dev
chown -R www:www /usr/local/www/lychee
chmod -R 755 /usr/local/www/lychee

cp /usr/local/www/lychee/.env.example /usr/local/www/lychee/.env
sed -i '' 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' /usr/local/www/lychee/.env
sed -i '' 's/DB_HOST=.*/DB_HOST=127.0.0.1/' /usr/local/www/lychee/.env
sed -i '' 's/DB_PORT=.*/DB_PORT=3306/'  /usr/local/www/lychee/.env
sed -i '' "s/#DB_DATABASE=.*/DB_DATABASE=${DB}/"  /usr/local/www/lychee/.env
sed -i '' "s/DB_USERNAME=.*/DB_USERNAME=${USER}/" /usr/local/www/lychee/.env
sed -i '' "s/DB_PASSWORD=.*/DB_PASSWORD=${PASS}/" /usr/local/www/lychee/.env

cd /usr/local/www/lychee/
echo "yes" | php artisan key:generate
php artisan config:cache
echo "yes" | php artisan migrate

# Start nginx
service nginx start
