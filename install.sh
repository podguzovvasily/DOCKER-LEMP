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

cd LEMP
