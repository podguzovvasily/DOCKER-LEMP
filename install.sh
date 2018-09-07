#!/bin/bash
sudo apt install docker.io -y
sudo systemctl start docker
sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
mkdir LEMP
cd LEMP
mkdir www www/hello.dev mysql logs hosts images images/php && echo "<?php phpinfo();" > www/hello.dev/index.php && touch images/php/php.ini && touch docker-compose.yml && echo -e "# Для начала указываем исходный образ, он будет использован как основа 
FROM php:7.0-fpm
# RUN выполняет идущую за ней команду в контексте нашего образа.
# В данном случае мы установим некоторые зависимости и модули PHP.
# Для установки модулей используем команду docker-php-ext-install.
# На каждый RUN создается новый слой в образе, поэтому рекомендуется объединять команды.
RUN apt-get update && apt-get install -y \\
        curl \\
        wget \\
        git \\
        libfreetype6-dev \\
        libjpeg62-turbo-dev \\
        libmcrypt-dev \\
        libpng-dev \\
    && docker-php-ext-install -j$""(nproc)"" iconv mcrypt mbstring mysqli pdo_mysql zip \\
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \\
    && docker-php-ext-install -j$""(nproc)"" gd
\n
# Куда же без composer'а.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
\n
# Добавим свой php.ini, можем в нем определять свои значения конфига
ADD php.ini /usr/local/etc/php/conf.d/40-custom.ini
\n
# Указываем рабочую директорию для PHP
WORKDIR /var/www/html
\n
# Запускаем контейнер
# Из документации: The main purpose of a CMD is to provide defaults for an executing container. These defaults can include an executable,
# or they can omit the executable, in which case you must specify an ENTRYPOINT instruction as well.
CMD ["'"'"php-fpm"'"'"]" > images/php/Dockerfile

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
        # nginx должен общаться с php контейнером
        links:\n
            - php
    php:
        # у нас свой образ для PHP, указываем путь к нему и говорим что его надо собрать
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
    server_name hello.dev;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/html/hello.dev;
    location ~ \.php$ {
        try_files "'$uri'" =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME "'$document_root$fastcgi_script_name;'"
        fastcgi_param PATH_INFO "'$fastcgi_path_info'";
    "'}'"
}" >hosts/hello-dev.conf

sudo docker-compose up -d
