FROM php:7-apache

ARG BUILD_DATE
ARG VERSION
LABEL build_version="RadPenguin version:- ${VERSION} Build-date:- ${BUILD_DATE}"

ENV APACHE_DOCUMENT_ROOT /var/www/html
ENV COMPOSER_ALLOW_SUPERUSER=1
# https://pecl.php.net/package/imagick
ENV IMAGEMAGICK_VERSION=3.4.3
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL C.UTF-8
ENV TZ="America/Edmonton"

# Install dependencies.
RUN apt-get update -qq && \
  apt-get install -yqq \
    curl \
    git

# Set the timezone                    
RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime

# Configure PHP
RUN apt-get update -qq && \
  apt-get -yqq install \
    libzip-dev && \
 docker-php-ext-install -j$(nproc) \
    mysqli \
    zip && \
  pecl install xdebug && \
  docker-php-ext-enable xdebug

RUN mv /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
ADD ./php.ini /usr/local/etc/php/conf.d/custom.ini

# Install ImageMagick
RUN apt-get update && apt-get install -y --no-install-recommends libmagickwand-dev imagemagick && \
  mkdir -p /usr/src/php/ext/imagick && \
  curl --location https://pecl.php.net/get/imagick-${IMAGEMAGICK_VERSION}.tgz | tar zx --strip-components=1 -C /usr/src/php/ext/imagick && \
  export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" && \
  docker-php-ext-install imagick

# Install composer
RUN curl --silent https://getcomposer.org/composer.phar -o /usr/local/bin/composer && chmod 755 /usr/local/bin/composer

# Modify www-data user to uid:gid 1000:1000
RUN usermod -u 1000 www-data && \
    groupmod -g 1000 www-data
RUN find /run -user 33 -exec chown -h 1000 {} \;
RUN find /var -user 33 -exec chown -h 1000 {} \;
RUN find /run -group 33 -exec chgrp -h 1000 {} \;
RUN find /var -group 33 -exec chgrp -h 1000 {} \;
RUN usermod -g 1000 www-data

# Enable apache modules
RUN a2enmod \
    actions \
    expires\
    headers \
    macro \
    rewrite

# Set the Apache path
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
