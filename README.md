# Bash scripts
Scripts ...

## Php-fpm pools script (http only)
```sh
#!/bin/bash
# Add local host in /etc/hosts for local domain: 127.0.0.1 api.app.xx

APP_HOST=api.app.xx

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

# robots (disallow all)
sudo echo "User-agent: *
Disallow: /
" > /srv/www/$APP_HOST/public/robots.txt

# permissions
sudo chown www-data:www-data /srv
sudo chmod 775 /srv
sudo chown www-data:www-data /srv/www
sudo chmod 775 /srv/www
sudo chown -R www-data:www-data /srv/log
sudo chmod -R 775 /srv/log
sudo chown -R $APP_HOST:$APP_HOST /srv/www/$APP_HOST
sudo chmod -R 2770 /srv/www/$APP_HOST

## domain pool
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
" > /etc/php/$PHP_VER/fpm/pool.d/fpm-$APP_HOST.conf

# virtualhost
echo "
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

	# if (\$scheme != "https") {
	# 	return 301 https://\$host\$request_uri;
	# }

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
" > /etc/nginx/sites-enabled/$APP_HOST

# refresh
sudo service php${PHP_VER}-fpm restart
sudo service nginx restart

# status
sudo service php${PHP_VER}-fpm status | cat
```
