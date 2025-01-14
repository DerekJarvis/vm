#!/bin/bash

# Tech and Me © - 2017, https://www.techandme.se/

# Prefer IPv4
sed -i "s|#precedence ::ffff:0:0/96  100|precedence ::ffff:0:0/96  100|g" /etc/gai.conf

# Install bzip2 if not existing
if [ "$(dpkg-query -W -f='${Status}' "bzip2" 2>/dev/null | grep -c "ok installed")" == "1" ]
then
    echo "bzip2 OK"
else
    apt update -q4 & spinner_loading
    apt install bzip2 -y
fi

# Install curl if not existing
if [ "$(dpkg-query -W -f='${Status}' "curl" 2>/dev/null | grep -c "ok installed")" == "1" ]
then
    echo "curl OK"
else
    apt update -q4 & spinner_loading
    apt install curl -y
fi

# Install lsb-release if not existing
if [ "$(dpkg-query -W -f='${Status}' "lsb-release" 2>/dev/null | grep -c "ok installed")" == "1" ]
then
    echo "lsb-release OK"
else
    apt update -q4 & spinner_loading
    apt install lsb-release -y
fi

# Install lshw if not existing
if [ "$(dpkg-query -W -f='${Status}' "lshw" 2>/dev/null | grep -c "ok installed")" == "1" ]
then
    echo "lshw OK"
else
    apt update -q4 & spinner_loading
    apt install lshw -y
fi

# Install sudo if not existing
if [ "$(dpkg-query -W -f='${Status}' "sudo" 2>/dev/null | grep -c "ok installed")" == "1" ]
then
    echo "sudo OK"
else
    apt update -q4 & spinner_loading
    apt install sudo -y
fi

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
FIRST_IFACE=1 && CHECK_CURRENT_REPO=1 . <(curl -sL https://raw.githubusercontent.com/nextcloud/vm/master/lib.sh)
unset FIRST_IFACE
unset CHECK_CURRENT_REPO

# Check for errors + debug code and abort if something isn't right
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Check if root
root_check

# Test RAM size (2GB min) + CPUs (min 1)
ram_check 2 Nextcloud
cpu_check 1 Nextcloud


# Create new current user
run_static_script adduser nextcloud_install_production.sh

# Check Ubuntu version
echo "Checking server OS and version..."
if [ "$OS" != 1 ]
then
msg_box "Ubuntu Server is required to run this script.
Please install that distro and try again.

You can find the download link here: https://www.ubuntu.com/download/server"
    exit 1
fi

# Assuming it's the correct version. need to put a better check in place.
#if ! version 16.04 "$DISTRO" 16.04.4; then
#msg_box "Ubuntu version $DISTRO must be between 16.04 - 16.04.4"
#    exit 1
#fi

# Check if key is available
if ! wget -q -T 10 -t 2 "$NCREPO" > /dev/null
then
msg_box "Nextcloud repo is not available, exiting..."
    exit 1
fi

# Check if it's a clean server
is_this_installed postgresql
is_this_installed apache2
is_this_installed php
is_this_installed mysql-common
is_this_installed mariadb-server
is_this_installed mysql-server

# Create $SCRIPTS dir
if [ ! -d "$SCRIPTS" ]
then
    mkdir -p "$SCRIPTS"
fi

##- Not changing DNS
# Change DNS
##if ! [ -x "$(command -v resolvconf)" ]
##then
##    apt install resolvconf -y -q
##    dpkg-reconfigure resolvconf
##fi
##echo "nameserver 9.9.9.9" > /etc/resolvconf/resolv.conf.d/base
##echo "nameserver 149.112.112.112" >> /etc/resolvconf/resolv.conf.d/base

#- Networking is fine, I'm SSHed in
# Check network
##if ! [ -x "$(command -v nslookup)" ]
##then
##    apt install dnsutils -y -q
##fi
##if ! [ -x "$(command -v ifup)" ]
##then
##    apt install ifupdown -y -q
##fi
##sudo ifdown "$IFACE" && sudo ifup "$IFACE"
### microsoft is allowed in more countries than google is :)
##if ! nslookup microsoft.com
##then
##msg_box "Network NOT OK. You must have a working network connection to run this script."
##    exit 1
##fi

##- Skipping locales because my server is already as I need it
# Set locales
## apt install language-pack-en-base -y
## sudo locale-gen "sv_SE.UTF-8" && sudo dpkg-reconfigure --frontend=noninteractive locales

##- Skipping repo selection because my provider already sets defaults
# Check where the best mirrors are and update
##echo
##printf "Your current server repository is:  ${Cyan}%s${Color_Off}\n" "$REPO"
##if [[ "no" == $(ask_yes_or_no "Do you want to try to find a better mirror?") ]]
##then
##    echo "Keeping $REPO as mirror..."
##    sleep 1
##else
##   echo "Locating the best mirrors..."
##   apt update -q4 & spinner_loading
##   apt install python-pip -y
##   pip install \
##       --upgrade pip \
##       apt-select
##    apt-select -m up-to-date -t 5 -c
##    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup && \
##    if [ -f sources.list ]
##    then
##        sudo mv sources.list /etc/apt/
##    fi
##fi
##clear

##- Skipping setting up keyboard layout because we already have it
# Set keyboard layout
##echo "Current keyboard layout is $(localectl status | grep "Layout" | awk '{print $3}')"
##if [[ "no" == $(ask_yes_or_no "Do you want to change keyboard layout?") ]]
##then
##    echo "Not changing keyboard layout..."
##    sleep 1
##    clear
##else
##    dpkg-reconfigure keyboard-configuration
##    clear
##fi

# Update system
apt update -q4 & spinner_loading

# Write MariaDB pass to file and keep it safe
{
echo "[client]"
echo "password='$MARIADB_PASS'"
} > "$MYCNF"
chmod 0600 $MYCNF
chown root:root $MYCNF

# Install -MARIADB- MySQL for ARM
##- Issues with the available 10.0.0.2, need to comment out last two innodb options in config file
##- can check if raspbian allows us to install 10.2 and just use it for this package
##- No need for debconf. will set pass after install
## Issue caused with config with log_slow_verbosity = query_plan
## Need to find a way around this. continuing to test manually
apt install software-properties-common -y
#sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
#sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.ddg.lth.se/mariadb/repo/10.2/ubuntu xenial main'
#sudo debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password password $MARIADB_PASS"
#sudo debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password_again password $MARIADB_PASS"
apt update -q4 & spinner_loading
check_command apt install mariadb-server -y

##+ Make sure mysql is running
/etc/init.d/mysql start

# Prepare for Nextcloud installation
# https://blog.v-gar.de/2017/02/en-solved-error-1698-28000-in-mysqlmariadb/
mysql -u root mysql -p"$MARIADB_PASS" -e "UPDATE user SET plugin='' WHERE user='root';"
mysql -u root mysql -p"$MARIADB_PASS" -e "UPDATE user SET password=PASSWORD('$MARIADB_PASS') WHERE user='root';"
mysql -u root -p"$MARIADB_PASS" -e "flush privileges;"
mysql -u root -p"$MARIADB_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$MARIADB_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$MARIADB_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$MARIADB_PASS" -e "FLUSH PRIVILEGES"

## mysql_secure_installation
## apt -y install expect
## SECURE_MYSQL=$(expect -c "
## set timeout 10
## spawn mysql_secure_installation
## expect \"Enter current password for root (enter for none):\"
## send \"$MARIADB_PASS\r\"
## expect \"Change the root password?\"
## send \"n\r\"
## expect \"Remove anonymous users?\"
## send \"y\r\"
## expect \"Disallow root login remotely?\"
## send \"y\r\"
## expect \"Remove test database and access to it?\"
## send \"y\r\"
## expect \"Reload privilege tables now?\"
## send \"y\r\"
## expect eof
## ")
## echo "$SECURE_MYSQL"
## apt -y purge expect

# Write a new MariaDB config
run_static_script new_etc_mycnf

##+ Manually changing config file to remove the InnoDB settings that cause issues:
sed -i "s|innodb_use_atomic_writes = 1|#innodb_use_atomic_writes = 1|g" $ETCMYCNF
sed -i "s|innodb_use_trim = 1|#innodb_use_trim = 1|g" $ETCMYCNF

##+ Changing Log level to ROW due to unsupported features, this one doesn't work though
sed -i "s|# * Basic Settings|binlog_format = ROW|g" $ETCMYCNF

## At this point the DB isn't running, nothing works to start it manually, have to restart

# Install Apache
check_command apt install apache2 -y
a2enmod rewrite \
        headers \
        env \
        dir \
        mime \
        ssl \
        setenvif

# Install PHP 7.0
apt update -q4 & spinner_loading
check_command apt install -y \
    libapache2-mod-php7.0 \
    php7.0-common \
    php7.0-mysql \
    php7.0-intl \
    php7.0-mcrypt \
    php7.0-ldap \
    php7.0-imap \
    php7.0-cli \
    php7.0-gd \
    php7.0-pgsql \
    php7.0-json \
    php7.0-sqlite3 \
    php7.0-curl \
    php7.0-xml \
    php7.0-zip \
    php7.0-mbstring \
    php-smbclient

# Enable SMB client
# echo '# This enables php-smbclient' >> /etc/php/7.0/apache2/php.ini
# echo 'extension="smbclient.so"' >> /etc/php/7.0/apache2/php.ini

# Install VM-tools
# Don't need open-vm-tools if we're not running on VMware. Not compiled for ARM anyway
# apt install open-vm-tools -y

# Download and validate Nextcloud package
check_command download_verify_nextcloud_stable

if [ ! -f "$HTML/$STABLEVERSION.tar.bz2" ]
then
msg_box "Aborting,something went wrong with the download of $STABLEVERSION.tar.bz2"
    exit 1
fi

# Extract package
tar -xjf "$HTML/$STABLEVERSION.tar.bz2" -C "$HTML" & spinner_loading
rm "$HTML/$STABLEVERSION.tar.bz2"

# Secure permissions
download_static_script setup_secure_permissions_nextcloud
bash $SECURE & spinner_loading

# Create database nextcloud_db
mysql -u root -p"$MARIADB_PASS" -e "CREATE DATABASE IF NOT EXISTS nextcloud_db;"

# Install Nextcloud
cd "$NCPATH"
check_command sudo -u www-data php occ maintenance:install \
    --data-dir "$NCDATA" \
    --database "mysql" \
    --database-name "nextcloud_db" \
    --database-user "root" \
    --database-pass "$MARIADB_PASS" \
    --admin-user "$NCUSER" \
    --admin-pass "$NCPASS"
echo
echo "Nextcloud version:"
sudo -u www-data php "$NCPATH"/occ status
sleep 3
echo

# Enable UTF8mb4 (4-byte support)
databases=$(mysql -u root -p"$MARIADB_PASS" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)
for db in $databases; do
    if [[ "$db" != "performance_schema" ]] && [[ "$db" != _* ]] && [[ "$db" != "information_schema" ]];
    then
        echo "Changing to UTF8mb4 on: $db"
        mysql -u root -p"$MARIADB_PASS" -e "ALTER DATABASE $db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    fi
done
#if [ $? -ne 0 ]
#then
#    echo "UTF8mb4 was not set. Something is wrong."
#    echo "Please report this bug to $ISSUES. Thank you!"
#    exit 1
#fi

# Repair and set Nextcloud config values
mysqlcheck -u root -p"$MARIADB_PASS" --auto-repair --optimize --all-databases
check_command sudo -u www-data $NCPATH/occ config:system:set mysql.utf8mb4 --type boolean --value="true"
check_command sudo -u www-data $NCPATH/occ maintenance:repair

# Prepare cron.php to be run every 15 minutes
crontab -u www-data -l | { cat; echo "*/15  *  *  *  * php -f $NCPATH/cron.php > /dev/null 2>&1"; } | crontab -u www-data -

# Change values in php.ini (increase max file size)
# max_execution_time
sed -i "s|max_execution_time =.*|max_execution_time = 3500|g" /etc/php/7.0/apache2/php.ini
# max_input_time
sed -i "s|max_input_time =.*|max_input_time = 3600|g" /etc/php/7.0/apache2/php.ini
# memory_limit
sed -i "s|memory_limit =.*|memory_limit = 512M|g" /etc/php/7.0/apache2/php.ini
# post_max
sed -i "s|post_max_size =.*|post_max_size = 1100M|g" /etc/php/7.0/apache2/php.ini
# upload_max
sed -i "s|upload_max_filesize =.*|upload_max_filesize = 1000M|g" /etc/php/7.0/apache2/php.ini

# Set max upload in Nextcloud .htaccess
configure_max_upload

# Set SMTP mail
sudo -u www-data php "$NCPATH"/occ config:system:set mail_smtpmode --value="smtp"

# Set logrotate
sudo -u www-data php "$NCPATH"/occ config:system:set log_rotate_size --value="10485760"

# Enable OPCache for PHP 
# https://docs.nextcloud.com/server/12/admin_manual/configuration_server/server_tuning.html#enable-php-opcache
phpenmod opcache
{
echo "# OPcache settings for Nextcloud"
echo "opcache.enable=1"
echo "opcache.enable_cli=1"
echo "opcache.interned_strings_buffer=8"
echo "opcache.max_accelerated_files=10000"
echo "opcache.memory_consumption=256"
echo "opcache.save_comments=1"
echo "opcache.revalidate_freq=1"
echo "opcache.validate_timestamps=1"
} >> /etc/php/7.0/apache2/php.ini

# Install preview generator
run_app_script previewgenerator

# Install Figlet
apt install figlet -y

# Generate $HTTP_CONF
if [ ! -f $HTTP_CONF ]
then
    touch "$HTTP_CONF"
    cat << HTTP_CREATE > "$HTTP_CONF"
<VirtualHost *:80>

### YOUR SERVER ADDRESS ###
#    ServerAdmin admin@example.com
#    ServerName example.com
#    ServerAlias subdomain.example.com

### SETTINGS ###
    DocumentRoot $NCPATH

    <Directory $NCPATH>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    Satisfy Any
    </Directory>

    <IfModule mod_dav.c>
    Dav off
    </IfModule>

    <Directory "$NCDATA">
    # just in case if .htaccess gets disabled
    Require all denied
    </Directory>

    SetEnv HOME $NCPATH
    SetEnv HTTP_HOME $NCPATH

</VirtualHost>
HTTP_CREATE
    echo "$HTTP_CONF was successfully created"
fi

# Generate $SSL_CONF
if [ ! -f $SSL_CONF ]
then
    touch "$SSL_CONF"
    cat << SSL_CREATE > "$SSL_CONF"
<VirtualHost *:443>
    Header add Strict-Transport-Security: "max-age=15768000;includeSubdomains"
    SSLEngine on

### YOUR SERVER ADDRESS ###
#    ServerAdmin admin@example.com
#    ServerName example.com
#    ServerAlias subdomain.example.com

### SETTINGS ###
    DocumentRoot $NCPATH

    <Directory $NCPATH>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    Satisfy Any
    </Directory>

    <IfModule mod_dav.c>
    Dav off
    </IfModule>

    <Directory "$NCDATA">
    # just in case if .htaccess gets disabled
    Require all denied
    </Directory>

    SetEnv HOME $NCPATH
    SetEnv HTTP_HOME $NCPATH

### LOCATION OF CERT FILES ###
    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
</VirtualHost>
SSL_CREATE
    echo "$SSL_CONF was successfully created"
fi

# Enable new config
a2ensite nextcloud_ssl_domain_self_signed.conf
a2ensite nextcloud_http_domain_self_signed.conf
a2dissite default-ssl

# Enable HTTP/2 server wide, if user decides to
msg_box "Your official package repository does not provide an Apache2 package with HTTP/2 module included.
If you like to enable HTTP/2 nevertheless, we can upgrade your Apache2 from Ondrejs PPA:
https://launchpad.net/~ondrej/+archive/ubuntu/apache2

Enabling HTTP/2 can bring a performance advantage, but may also have some compatibility issues.
E.g. the Nextcloud Spreed video calls app does not yet work with HTTP/2 enabled."

if [[ "yes" == $(ask_yes_or_no "Do you want to enable HTTP/2 system wide?") ]]
then
    # Adding PPA
    add-apt-repository ppa:ondrej/apache2 -y
    apt update -q4 & spinner_loading
    apt upgrade apache2 -y
    
    # Enable HTTP/2 module & protocol
    cat << HTTP2_ENABLE > "$HTTP2_CONF"
<IfModule http2_module>
    Protocols h2 h2c http/1.1
    H2Direct on
</IfModule>
HTTP2_ENABLE
    echo "$HTTP2_CONF was successfully created"
    a2enmod http2
fi

# Restart Apache2 to enable new config
service apache2 restart

whiptail --title "Which apps/programs do you want to install?" --checklist --separate-output "" 10 40 3 \
"Calendar" "              " on \
"Contacts" "              " on \
"Webmin" "              " on 2>results

while read -r -u 9 choice
do
    case "$choice" in
        Calendar)
            run_app_script calendar
        ;;
        Contacts)
            run_app_script contacts
        ;;
        Webmin)
            run_app_script webmin
        ;;
        *)
        ;;
    esac
done 9< results
rm -f results

# Get needed scripts for first bootup
if [ ! -f "$SCRIPTS"/nextcloud-startup-script.sh ]
then
check_command wget -q "$GITHUB_REPO"/nextcloud-startup-script.sh -P "$SCRIPTS"
fi
download_static_script instruction
download_static_script history

# Make $SCRIPTS excutable
chmod +x -R "$SCRIPTS"
chown root:root -R "$SCRIPTS"

# Prepare first bootup
check_command run_static_script change-ncadmin-profile
check_command run_static_script change-root-profile

# Install Redis
run_static_script redis-server-ubuntu16
##+ This requires user input, it appears because it needs to be compiled in ARM, it asks about a module.
# Upgrade
apt update -q4 & spinner_loading
apt dist-upgrade -y

# Remove LXD (always shows up as failed during boot)
apt purge lxd -y

# Cleanup
CLEARBOOT=$(dpkg -l linux-* | awk '/^ii/{ print $2}' | grep -v -e ''"$(uname -r | cut -f1,2 -d"-")"'' | grep -e '[0-9]' | xargs sudo apt -y purge)
echo "$CLEARBOOT"
apt autoremove -y
apt autoclean
find /root "/home/$UNIXUSER" -type f \( -name '*.sh*' -o -name '*.html*' -o -name '*.tar*' -o -name '*.zip*' \) -delete

##- These aren't available on ARM
# Install virtual kernels for Hyper-V, and extra for UTF8 kernel module + Collabora and OnlyOffice
# Kernel 4.4
## apt install --install-recommends -y \
## linux-virtual-lts-xenial \
## linux-tools-virtual-lts-xenial \
## linux-cloud-tools-virtual-lts-xenial \
## linux-image-virtual-lts-xenial \
## linux-image-extra-"$(uname -r)"

# Set secure permissions final (./data/.htaccess has wrong permissions otherwise)
bash $SECURE & spinner_loading

# Force MOTD to show correct number of updates
##+ Command not found
sudo /usr/lib/update-notifier/update-motd-updates-available --force

# Reboot
echo "Installation done, system will now reboot..."
reboot
