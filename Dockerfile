FROM php:7-apache

ARG BUILD_DATE
ARG VERSION
LABEL build_version="RadPenguin version:- ${VERSION} Build-date:- ${BUILD_DATE}"

ENV TZ="America/Edmonton"
ENV LANG en_US.UTF-8
ENV LC_ALL C.UTF-8
ENV LANGUAGE en_US.UTF-8

# Set the timezone                    
RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime

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

# Configure PHP
RUN docker-php-ext-install -j$(nproc) \
    mysqli

# Install composer
RUN curl --silent https://getcomposer.org/composer.phar -o /usr/local/bin/composer && chmod 755 /usr/local/bin/composer

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
