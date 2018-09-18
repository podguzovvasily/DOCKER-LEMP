#!/bin/bash
sudo apt install docker.io -y
sudo systemctl start docker
sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo -n "Enter your domain name: "
read domain
mkdir LEMP
cd LEMP
mkdir www www/$domain mysql logs hosts images images/php && echo "<?php phpinfo();" > www/$domain/index.php && touch images/php/php.ini && touch docker-compose.yml

echo -e "# Версия docker-compose
version: '2'
# Список наших сервисов (контейнеров)
services:
    nginx:
      # используем последний стабильный образ nginx
        image: nginx:latest
        # маршрутизируем порты
        ports:
            - "'"'"80:80"'"'"
        # монтируем директории, слева директории на основной машине, справа - куда они монтируются в контейнере
        volumes:
            - ./hosts:/etc/nginx/conf.d
            - ./www:/var/www/html
            - ./logs:/var/log/nginx\n
            - ./etc/letsencrypt_docker/live/$domain:/etc/ssl
        # nginx должен общаться с php контейнером
        links:\n
            - php
    php:
        # у нас свой образ для PHP
        image: php:7.2-fpm
        # этот образ будет общаться с mysql
        links:\n
            - mysql
        # монтируем директорию с проектами
        volumes:
            - ./www:/var/www/html
    mysql:
        image: mariadb
        ports:
            - "'"'"3306:3306"'"'"
        volumes:
            - ./mysql:/var/lib/mysql
        # задаем пароль для root пользователя
        environment:
            MYSQL_ROOT_PASSWORD: secret
            
    certbot:
        image: certbot/certbot
        links:\n
            - nginx
        volumes:
            - ./etc/letsencrypt_docker:/etc/letsencrypt
            - ./www:/var/www/html
        command: ["renew"]
        # Request to certificate docker-compose run certbot certonly --webroot -w /var/www/html/$domain -d $domain -d www.$domain
        
    pma:
      # используем последний стабильный образ phpmyadmin
        image: phpmyadmin/phpmyadmin
        restart: always
        links:
            - mysql:mysql
        ports:
            - 8183:80
        environment:
            # прописываем название нашего MySQL хоста
            PMA_HOST: mysql
            MYSQL_USERNAME: root
            MYSQL_ROOT_PASSWORD: secret" >docker-compose.yml

echo -e "server {
    index index.php;
    server_name $domain;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/html/$domain;
    location ~ \.php$ {
        try_files "'$uri'" =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME "'$document_root$fastcgi_script_name;'"
        fastcgi_param PATH_INFO "'$fastcgi_path_info'";
    "'}'"
}" >hosts/$domain.conf

sudo docker-compose up -d

docker-compose run certbot certonly --webroot -w /var/www/html/$domain -d $domain -d www.$domain

echo -e "server {
    index index.php;
    server_name $domain;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/html/$domain;
    location ~ \.php$ {
        try_files "'$uri'" =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME "'$document_root$fastcgi_script_name;'"
        fastcgi_param PATH_INFO "'$fastcgi_path_info'";
    "'}'"
}

server {
	listen [::]:443 ssl http2 default_server;
	listen 443 ssl http2 default_server;

        server_name $domain
	listen 443 ssl http2;
	#ssl on;
	ssl_certificate /etc/ssl/fullchain1.pem;
    	ssl_certificate_key /etc/ssl/privkey1.pem;
	ssl_dhparam /etc/ssl/dh4096.pem;
	ssl_trusted_certificate /etc/ssl/chain1.pem
	ssl_session_cache shared:SSL:50m;
	ssl_session_timeout 5m;
	ssl_stapling on;
	ssl_stapling_verify on;
	ssl_protocols TLSv1.1 TLSv1.2;
  	ssl_ciphers 'EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA512:EECDH+ECDSA+SHA256:ECDH+AESGCM:ECDH+AES256:DH+AESGCM:DH+AES256:!aNULL:!eNULL:!LOW:!RC4:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS';
	ssl_prefer_server_ciphers on;
    	"'add_header Strict-Transport-Security "max-age=31536000;";'"
    	"'add_header Content-Security-Policy-Report-Only "default-src https:; script-src https: 'unsafe-eval' 'unsafe-inline'; style-src https: 'unsafe-inline'; img-src https: data:; font-src https: data:; report-uri /csp-report";'"
	
index index.php;
    server_name basil-student.ru;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/html/basil-student.ru;
    location ~ \.php$ {
        try_files "'$uri'" =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME "'$document_root$fastcgi_script_name;'"
        fastcgi_param PATH_INFO "'$fastcgi_path_info'";
    }

}" >basil-student.ru.conf
