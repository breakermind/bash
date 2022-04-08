#!/bin/bash

echo "
server {
	listen 80 default_server;
	listen [::]:80 default_server;
	server_name _;
	root /var/www/html;
	index index.php index.html;
	return 444;
}

server {
	listen 443 default_server ssl;
	listen [::]:443 default_server ssl;
	server_name _;
	root /var/www/html;
	index index.php index.html;
	ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
	ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
	return 444;
}
" > /etc/nginx/sites-available/default
