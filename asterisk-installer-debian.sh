#!/bin/bash
# Full automated installation of Asterisk on Debian
# copyright © 2011 Simon DESVERGEZ simon@desvergez.net
clear

# Variables
CURRENTDIR=$(pwd)
ROOTDIR=/tmp/astinstall
ASTVERS=11
DEFPW=att123

# Directories
mkdir -p /usr/src/asterisk
mkdir -p /var/www/default
mkdir -p $ROOTDIR
cd $ROOTDIR

# Download essential dpkg
echo -e "*** Asterisk Installation *** \n" 
echo -e "Install in progress. Please wait...\n" && apt-get update && apt-get -y upgrade
apt-get install -y build-essential libxml2-dev libncurses5-dev linux-headers-$(uname -r) module-init-tools debconf-utils

# VMware tools
lspci | grep -i vmware > /dev/null
if [ $? -eq 0 ]; then
	apt-get -y install open-vm-tools
fi

# debconf pre-seeds
echo "exim4-config exim4/dc_eximconfig_configtype select internet site; mail is sent and received directly using SMTP" | debconf-set-selections
echo "mysql-server mysql-server/root_password password $DEFPW" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DEFPW" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DEFPW" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $DEFPW" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $DEFPW" | debconf-set-selections
echo "phpmyadmin phpmyadmin/password-confirm password $DEFPW" | debconf-set-selections
echo "phpmyadmin phpmyadmin/setup-password password $DEFPW" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections

# Download additional dpkg
apt-get install -y curl python-software-properties mysql-server mysql-client libncurses5-dev libmysqlclient15-dev apache2 php5 libapache2-mod-php5 php5-mysql php5-curl php-xml-serializer  phpmyadmin exim4 libsqlite3-dev libssl-dev perl libwww-perl libsox-fmt-mp3 sox mpg123 tree htop ntp rsync zip unzip tcpdump

# Apps settings
dpkg-reconfigure -f noninteractive exim4-config

# Download Asterisk sources
cd /usr/src/asterisk
wget -r http://adminisk.org/install/asterisk-dahdi-linux-complete-current.tar.gz -O dahdi-linux-complete-current.tar.gz
tar xvzf dahdi-linux-complete-current.tar.gz
cd dahdi-linux-complete*
make all && make install && make config
/etc/init.d/dahdi start
cd /usr/src/asterisk
wget -r http://adminisk.org/install/asterisk-libpri-current.tar.gz -O libpri-current.tar.gz
tar xvzf libpri-current.tar.gz
cd libpri*
make && make install
/etc/init.d/dahdi start
cd /usr/src/asterisk
wget -r http://adminisk.org/install/asterisk-$ASTVERS-current.tar.gz -O asterisk-$ASTVERS-current.tar.gz
tar xvzf asterisk-$ASTVERS-current.tar.gz
cd asterisk-$ASTVERS*
./configure
make menuselect.makeopts
menuselect/menuselect --enable chan_ooh323 --enable res_config_mysql --enable app_mysql --enable cdr_mysql --enable CORE-SOUNDS-FR-ALAW --enable MOH-OPSOUND-ALAW --enable EXTRA-SOUNDS-FR-ALAW menuselect.makeopts
make
make install
make samples
make config

# Asterisk Settings
cd $ROOTDIR
chmod +r /var/log/asterisk -R
sed -i s/password=att123/password=$DEFPW/g /etc/asterisk/cdr_mysql.conf
sed -i s/dbpass = att123/dbpass = $DEFPW/g /etc/asterisk/res_config_mysql.conf
wget -r http://adminisk.org/install/adminisk-sounds-fr.tar.gz -O adminisk-sounds-fr.tar.gz
mv /var/lib/asterisk/sounds/fr /var/lib/asterisk/sounds/fr-ori
tar -zxvf adminisk-sounds-fr.tar.gz -C /var/lib/asterisk/sounds/
wget -r http://adminisk.org/install/asterisk-googletts.agi -O /var/lib/asterisk/agi-bin/googletts.agi
chmod +x /var/lib/asterisk/agi-bin/googletts.agi
/etc/init.d/asterisk start