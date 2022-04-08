#!/bin/bash

# Set your: domain.xx
DOMAIN=""

if [ -z "$DOMAIN" ]; then
	echo "[error] Empty domain host"
	exit
fi

# Example http vhost for api.demo.xx in bash
sudo echo "
server {
	listen 80;
	listen [::]:80;
	server_name ${DOMAIN} www.${DOMAIN};
	root /srv/www/${DOMAIN}/public;
	index index.php index.html;

	charset utf-8;
	disable_symlinks off;
	client_max_body_size 100M;

	access_log /srv/log/${DOMAIN}/access.log;
	error_log /srv/log/${DOMAIN}/error.log warn;

	location / {
		try_files \$uri \$uri/ /public/index.php\$is_args\$args;
		# try_files \$uri \$uri/ /index.php\$is_args\$args;
		# try_files \$uri \$uri/ =404;
	}

	location ~ \.php\$ {
		# fastcgi_pass 127.0.0.1:9000;
		fastcgi_pass unix:/run/php/php8.1-fpm.sock;
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
" > /etc/nginx/sites-enabled/${DOMAIN}

sudo service nginx restart