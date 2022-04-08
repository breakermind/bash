#!/bin/bash
#######################################################################################
# Set DNS domain A record first for your hosts [www.api.example.com, api.example.com] #
# Install php8.1-fpm or change script PHP_VER variable                                #
# Script create certificates for domain (certbot)                                     #
# Virtualhost redirects www page to secured non-www (https)                           #
#######################################################################################

############################################################
# Help                                                     #
############################################################
Help()
{
	# Display Help
	echo "Bash script params."
	echo
	echo "Syntax: scriptTemplate [-h|m|d]"
	echo "options:"
	echo "-h 	Print this Help."
	echo "-m 	Change email address."
	echo "-d 	Change domain hostname."
	echo
}

############################################################
# Main program                                             #
############################################################
# Set variables
APP_HOST=""
APP_EMAIL=""
PHP_VER=8.1

############################################################
# Process the input options                                #
############################################################
# Get the options
while getopts ":m:d:h" option
do
	case $option in
		h) 	Help
			exit;;
		d)
			APP_HOST=${OPTARG};;
		m)
			APP_EMAIL=${OPTARG};;
		\?)
			echo "Error: Invalid option"
			exit;;
	esac
done

############################################################
# Required packages                                        #
############################################################
# add dig package
sudo apt install dnsutils certbot nginx &>/dev/null

############################################################
# Script params                                            #
############################################################
echo $APP_HOST
echo $APP_MAIL

# validate
if [ -z "$APP_HOST" ]; then
	echo "!!! Empty param1: _vps-pool.sh -d [host] -m [email]"
	exit
fi

if [ -z "$APP_EMAIL" ]; then
	echo "!!! Empty param2: _vps-pool.sh -d [host] -m [email]"
	exit
fi

[ -z "$(dig +short "www.$APP_HOST")" ]  &&  echo "Create www.$APP_HOST host A record in domain DNS zone first."
[ -z "$(dig +short "$APP_HOST")" ]  &&  echo "Create $APP_HOST host A record in domain DNS zone first."

############################################################
# Functionality                                            #
############################################################
echo "Your email ${APP_EMAIL} domain host ${APP_HOST}"

############################################################
# Certbot certificates                                     #
############################################################
# Domains to install cert on (comma separated)
FQDNS="${APP_HOST}, www.${APP_HOST}"

sudo service nginx stop

sudo certbot certonly --standalone --agree-tos --non-interactive --email ${APP_EMAIL} --domains ${FQDNS}

sudo service nginx start

############################################################
# Php-fpm pools                                            #
############################################################
# user
sudo useradd $APP_HOST -Mrs /bin/false
sudo usermod -a -G $APP_HOST www-data

# logs
sudo mkdir -p /srv/log/$APP_HOST
sudo echo "" > /srv/log/$APP_HOST/access.log
sudo echo "" > /srv/log/$APP_HOST/error.log
sudo echo "" > /srv/log/$APP_HOST/php-fpm.log

# htdocs
sudo mkdir -p /srv/www/$APP_HOST/public

# index
sudo echo "Php-fpm pool works ..." > /srv/www/$APP_HOST/public/index.php

# robots
sudo echo "User-agent: *
Disallow: /
" > /srv/www/$APP_HOST/public/robots.txt

# permissions (important)
sudo chown www-data:www-data /srv
sudo chmod 775 /srv
sudo chown www-data:www-data /srv/www
sudo chmod 775 /srv/www
sudo chown -R www-data:www-data /srv/log
sudo chmod -R 775 /srv/log
sudo chown -R $APP_HOST:$APP_HOST /srv/www/$APP_HOST
sudo chmod -R 2770 /srv/www/$APP_HOST

# clear old sock
sudo rm /run/php/php${PHP_VER}-fpm-${APP_HOST}.sock

# pool
sudo echo "
[${APP_HOST}]

user = ${APP_HOST}
group = ${APP_HOST}
listen = /run/php/php${PHP_VER}-fpm-${APP_HOST}.sock

listen.owner = www-data
listen.group = www-data
;listen.mode = 0660
;listen.acl_users =
;listen.acl_groups =
;listen.allowed_clients = 127.0.0.1

pm = dynamic
pm.max_children = 5
pm.start_servers = 1
pm.min_spare_servers = 1
pm.max_spare_servers = 3
;pm.max_spawn_rate = 32
;pm.process_idle_timeout = 10s;
;pm.max_requests = 500

; Limits
php_admin_value[memory_limit] = 256M
; Upload
php_admin_value[post_max_size] = 64M
php_admin_value[max_input_vars] = 100
php_admin_value[max_file_uploads] = 20
; Remote files
php_admin_value[allow_url_fopen] = 0
php_admin_value[allow_url_include] = 0
php_admin_flag[cgi.fix_pathinfo] = off
; Errors
php_admin_flag[display_errors] = on
php_admin_flag[display_startup_errors] = on
php_admin_flag[log_errors] = on
php_admin_value[error_log] = /srv/log/${APP_HOST}/php-fpm.log
; Php secure
php_admin_value[open_basedir] = /srv/www/${APP_HOST}:/tmp
php_admin_value[disable_functions] = cat,echo,ls,dl,exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source,setenv
; Cache
php_admin_flag[opcache.enable] = on
php_admin_flag[opcache.save_comments] = off
php_admin_value[opcache.memory_consumption] = 128
; Limits
php_admin_value[max_execution_time] = 600
php_admin_value[max_input_time] = 300
; Compresion
php_admin_value[zlib.output_compression] = 1
php_admin_value[zlib.output_compression_level] = 6
; Paths
; php_admin_value[sys_temp_dir] = /tmp/${APP_HOST}/www
; php_admin_value[upload_tmp_dir] = /tmp/${APP_HOST}/upload

" > /etc/php/$PHP_VER/fpm/pool.d/fpm-$APP_HOST.conf

############################################################
# Virtualhost                                              #
############################################################
# create
echo "
server {
	server_name www.${APP_HOST};
	return 301 https://${APP_HOST}\$request_uri;
}

server {
	listen 80;
	listen [::]:80;
	server_name ${APP_HOST};
	root /srv/www/${APP_HOST}/public;
	index index.php;

	charset utf-8;
	disable_symlinks off;
	client_max_body_size 64M;

	access_log /srv/log/${APP_HOST}/access.log;
	error_log /srv/log/${APP_HOST}/error.log warn;

	if (\$scheme != "https") {
		return 301 https://\$host\$request_uri;
	}

	location / {
		try_files \$uri \$uri/ /index.php\$is_args\$args;
		# try_files \$uri \$uri/ /index.php\$is_args\$args;
		# try_files \$uri \$uri/ =404;
	}

	location ~ \.php\$ {
		# fastcgi_pass 127.0.0.1:9000;
		fastcgi_pass unix:/run/php/php${PHP_VER}-fpm-${APP_HOST}.sock;
		include snippets/fastcgi-php.conf;
	}

	location ~* \.(jpg|jpeg|gif|png|ico|gz|svg|mp3|mp4|mov|ogg|ogv|webm|webp)\$ {
		expires 1M;
		access_log off;
		add_header Cache-Control public;
	}

	location = /favicon.ico {
		rewrite . /favicon/favicon.ico;
	}
}

server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;
	server_name ${APP_HOST};
	root /srv/www/${APP_HOST}/public;
	index index.php index.html;

	charset utf-8;
	disable_symlinks off;
	client_max_body_size 64M;

	access_log /srv/log/${APP_HOST}/access.log;
	error_log /srv/log/${APP_HOST}/error.log warn;

	ssl_certificate /etc/letsencrypt/live/${APP_HOST}/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/${APP_HOST}/privkey.pem;

	ssl_protocols TLSv1.2 TLSv1.3;
	ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:!aNULL:!MD5;
	ssl_prefer_server_ciphers on;
	ssl_stapling on;
	ssl_stapling_verify on;
	ssl_ecdh_curve secp384r1;

	location / {
		try_files \$uri \$uri/ /public/index.php\$is_args\$args;
		# try_files \$uri \$uri/ /index.php\$is_args\$args;
		# try_files \$uri \$uri/ =404;
	}

	location ~ \.php\$ {
		# fastcgi_pass 127.0.0.1:9000;
		fastcgi_pass unix:/run/php/php${PHP_VER}-fpm-${APP_HOST}.sock;
		include snippets/fastcgi-php.conf;
	}

	location ~* \.(jpg|jpeg|gif|png|ico|gz|svg|mp3|mp4|mov|ogg|ogv|webm|webp)\$ {
		expires 1M;
		access_log off;
		add_header Cache-Control public;
	}

	location = /favicon.ico {
		rewrite . /favicon/favicon.ico;
	}

	add_header Strict-Transport-Security 'max-age=15768000; includeSubdomains; preload;';
	add_header Content-Security-Policy \"default-src 'none'; frame-ancestors 'none'; script-src 'self'; img-src 'self'; style-src 'self'; base-uri 'self'; form-action 'self';\";
	add_header Referrer-Policy 'no-referrer, strict-origin-when-cross-origin';
	add_header X-Frame-Options SAMEORIGIN;
	add_header X-Content-Type-Options nosniff;
	add_header X-XSS-Protection '1; mode=block';
}
" > /etc/nginx/sites-enabled/$APP_HOST

# refresh
sudo service php${PHP_VER}-fpm restart
sudo service nginx restart

# status
sudo service php${PHP_VER}-fpm status | cat
