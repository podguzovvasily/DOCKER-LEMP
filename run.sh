#!/bin/bash
sudo apt-get update
sudo apt-get upgrade -y
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
\tcurl \\
\twget \\
\tgit \\
\tlibfreetype6-dev \\
\tlibjpeg62-turbo-dev \\
\tlibmcrypt-dev \\
\tlibpng12-dev \\
&& docker-php-ext-install -j$""(nproc)"" iconv mcrypt mbstring mysqli pdo_mysql zip \\
&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \\
&& docker-php-ext-install -j$""(nproc)"" gd
\n
# Куда же без composer'а.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
/n
# Добавим свой php.ini, можем в нем определять свои значения конфига
ADD php.ini /usr/local/etc/php/conf.d/40-custom.ini
/n
# Указываем рабочую директорию для PHP
WORKDIR /var/www
/n
# Запускаем контейнер
# Из документации: The main purpose of a CMD is to provide defaults for an executing container. These defaults can include an executable,
# or they can omit the executable, in which case you must specify an ENTRYPOINT instruction as well.
CMD ["'"'"php-fpm"'"'"]" > images/php/Dockerfile

echo -e "# Версия docker-compose
version: '2'
# Список наших сервисов (контейнеров)
services:
\tnginx:
# используем последний стабильный образ nginx
\timage: nginx:latest
# маршрутизируем порты
\tports:
\t- "'"'"8000:80"'"'"
\t# монтируем директории, слева директории на основной машине, справа - куда они монтируются в контейнере
\tvolumes:
\t- ./hosts:/etc/nginx/conf.d
            \t- ./www:/var/www
            \t- ./logs:/var/log/nginx
\t# nginx должен общаться с php контейнером
        \t# nginx должен общаться с php контейнером
        \tlinks:
            \t- php
    \tphp:
        \t# у нас свой образ для PHP, указываем путь к нему и говорим что его надо собрать
        \tbuild: ./images/php
        \t# этот образ будет общаться с mysql
        \tlinks:
            \t- mysql
        \t# монтируем директорию с проектами
        \tvolumes:
            \t- ./www:/var/www
    \tmysql:
        \timage: mariadb
        \tports:
            \t- "'"'"3306:3306"'"'"
        \tvolumes:
            \t- ./mysql:/var/lib/mysql
        \t# задаем пароль для root пользователя
        \tenvironment:
            \tMYSQL_ROOT_PASSWORD: secret
    \tpma:
      \t# используем последний стабильный образ phpmyadmin
        \timage: phpmyadmin/phpmyadmin
        \trestart: always
        \tlinks:
            \t- mysql:mysql
        \tports:
            \t- 8183:80
        \tenvironment:
            \t# прописываем название нашего MySQL хоста
           \tPMA_HOST: mysql
            \tMYSQL_USERNAME: root
            \tMYSQL_ROOT_PASSWORD: secret" >docker-compose.yml
