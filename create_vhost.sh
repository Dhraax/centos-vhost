#!/bin/bash
# This script is used for create virtual hosts on CentOs.
# Created by alexnogard from http://alexnogard.com
# Improved by mattmezza from http://you.canmakethat.com
# Readapted by Dhraax from https://github.com/dhraax
# Feel free to modify it

##Initial definition
errorlog='ErrorLog "|/usr/sbin/rotatelogs'
errorlog2='/logs/error-%Y%m%d.log 86400"'
customlog='CustomLog "|/usr/sbin/rotatelogs'
customlog2='/logs/access-%Y%m%d.log 86400" combined'

##### vhost creation #####
if [ "$(whoami)" != 'root' ]; then
echo "You have to execute this script as root user"
exit 1;
fi
read -p "Enter the server name your want (without www) : " servn
read -p "Enter the server admin email : " servad
read -p "Enter a CNAME (e.g. :www or dev for dev.website.com) : " cname
read -p "Enter the path of directory you wanna use (e.g. : /var/www/, dont forget the /): " dir
read -p "Enter the user you wanna use (e.g. : apache) : " usr
read -p "Enter the listened IP for the server (e.g. : *): " listen
if [ ! -d "$dir$servn" ]; then
mkdir -p $dir$servn/{httpdocs,logs,tmp}
echo "<?php echo '<h1>$cname $servn</h1>'; ?>" > $dir$servn/httpdocs/index.php
chown -R $usr:$usr $dir$servn
chmod -R '755' $dir$servn
echo "Web directory created with success !"
else
echo "Web directory already Exist !"
fi

alias=$cname.$servn
if [[ "${cname}" == "" ]]; then
alias=$servn
fi
if [ ! -f "/etc/httpd/conf.d/$servn.conf" ]; then
echo "#### $cname $servn
<VirtualHost $listen:80>
ServerAdmin $servad
ServerName $servn
ServerAlias $alias
DocumentRoot $dir$servn/httpdocs/
$errorlog $dir$servn$errorlog2
$customlog $dir$servn$customlog2
</VirtualHost>" > /etc/httpd/conf.d/$servn.conf
echo "Virtual host created !"
else
echo "Virtual host exist wasn't created !"
fi
echo "Would you like me to create ssl virtual host (self-signed)[y/n]? "
read q
if [[ "${q}" == "yes" ]] || [[ "${q}" == "y" ]]; then
if [ ! -f /etc/httpcerts/$servn.key -a ! -f /etc/httpcerts/$servn.crt ]; then
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/httpcerts/$servn.key -out /etc/httpcerts/$servn.crt
echo "Certificate created !"
else
echo "Certificate already Exist !"
fi

if [ ! -f "/etc/httpd/conf.d/ssl.$servn.conf" ]; then
echo "#### ssl $servn
<VirtualHost $listen:443>
SSLEngine on
SSLCertificateFile /etc/httpcerts/$servn.crt
SSLCertificateKeyFile /etc/httpcerts/$servn.key
DocumentRoot $dir$servn/httpdocs/
$errorlog $dir$servn$errorlog2
$customlog $dir$servn$customlog2
</VirtualHost>" > /etc/httpd/conf.d/ssl.$servn.conf
echo "Virtual host created !"
else
echo "Virtual host exist wasn't created !"
fi
fi

##echo "127.0.0.1 $servn" >> /etc/hosts
#if [ "$alias" != "$servn" ]; then
#echo "127.0.0.1 $alias" >> /etc/hosts
#fi
echo "Testing configuration"
service httpd configtest
echo "Would you like me to restart the server [y/n]? "
read q
if [[ "${q}" == "yes" ]] || [[ "${q}" == "y" ]]; then
service httpd restart
fi
echo "======================================"
echo "All works done! You should be able to see your website at http://$servn"
echo ""
