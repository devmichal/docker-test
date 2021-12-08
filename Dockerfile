FROM php:7.4-fpm

# Install nginx
RUN apt-get update && apt-get install --yes \
    gettext \
    nginx \
    && service nginx stop \
    && rm \
    /etc/nginx/nginx.conf \
    /etc/nginx/sites-available/* \
    /etc/nginx/sites-enabled/*

# Install php-fpm
RUN rm \
      /usr/local/etc/php-fpm.d/* \
      /usr/local/etc/php/conf.d/* \
&& apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev\
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd \
    && docker-php-ext-install soap \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install zip

RUN pecl install redis && docker-php-ext-enable redis

RUN apt-get install -y librabbitmq-dev libssh-dev \
    && docker-php-ext-install opcache bcmath sockets \
    && pecl install amqp \
    && docker-php-ext-enable amqp

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Config nginx
COPY ./etc/nginx.template.conf /etc/nginx/nginx.template.conf
ENV NGINX_WORKERS_COUNT="1"
ENV NGINX_CGI_SERVER_HOST="127.0.0.1"
ENV NGINX_CGI_SERVER_PORT="9000"
ENV NGINX_ACCESS_LOG="/dev/stdout"
ENV NGINX_ERROR_LOG="/dev/stderr"
ENV NGINX_LOG_LEVEL="error"

# FPM-FPM configuration
COPY ./etc/php-fpm.conf /usr/local/etc/php-fpm.d/php-fpm.conf/
ENV FPM_WORKERS_COUNT="2"
ENV FPM_ACCESS_LOG="/proc/self/fd/2"
ENV FPM_ERROR_LOG="/proc/self/fd/2"
ENV FPM_LOG_LEVEL="error"

# PHP configuration
COPY ./etc/php.ini /usr/local/etc/php/conf.d/php.ini/
ENV PHP_OPCACHE_ENABLE="true"
ENV PHP_ERROR_LOG="/proc/self/fd/2"
ENV PHP_LOG_LEVEL="E_ERROR"

# Entrypoint
COPY ./etc/entrypoint.bash /usr/local/bin/entrypoint.bash
RUN chmod a+x /usr/local/bin/entrypoint.bash
ENTRYPOINT ["entrypoint.bash"]

CMD ["bash"]
EXPOSE 8014
HEALTHCHECK NONE
WORKDIR /app

RUN composer create-project symfony/skeleton .