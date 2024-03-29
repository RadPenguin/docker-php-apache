ARG FROM_IMAGE
FROM $FROM_IMAGE

ARG BUILD_DATE
ARG VERSION
ARG XDEBUG_VERSION=""
LABEL build_version="RadPenguin version:- ${VERSION} Build-date:- ${BUILD_DATE}"

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL C.UTF-8
ENV TZ="America/Edmonton"

ENV APACHE_DOCUMENT_ROOT /var/www/html
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_MEMORY_LIMIT -1
ENV IMAGEMAGICK_VERSION 3.7.0
ENV NODE_VERSION 18.17.1

# Install dependencies.
RUN apt-get update -qq && \
  apt-get install -yqq \
  curl \
  ffmpeg \
  git \
  jq \
  mariadb-client \
  rename \
  rsync \
  unzip \
  webp \
  wget

# Set the timezone
RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime

# Update the default .bashrc.
RUN echo "alias ll='ls -al --color'" >> /etc/bash.bashrc

# Configure PHP
RUN apt-get update -qq && \
  apt-get -yqq install libzip-dev && \
  docker-php-ext-install -j$(nproc) \
  bcmath \
  exif \
  gettext \
  mysqli \
  opcache \
  pdo_mysql \
  zip && \
  pecl install xdebug${XDEBUG_VERSION} && \
  docker-php-ext-enable xdebug

RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
RUN mkdir -p /var/www/.xdebug
ADD ./php.ini /usr/local/etc/php/conf.d/00-custom.ini

# Install GD.
RUN apt-get -qq update && apt-get install -yqq --no-install-recommends \
  libfreetype6-dev \
  libjpeg62-turbo \
  libjpeg62-turbo-dev \
  libpng-dev && \
  docker-php-ext-configure gd --with-freetype --with-jpeg && \
  docker-php-ext-install -j$(nproc) gd

# Compile Imagemagick
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  libfreetype6 \
  libjpeg62-turbo \
  libwebp-dev  \
  libzip4 && \
  git clone https://github.com/ImageMagick/ImageMagick.git /tmp/imagemagick && \
  cd /tmp/imagemagick && \
  ./configure --enable-openmp --with-webp=yes && \
  make -j$(nproc) && \
  make install && \
  ldconfig /usr/local/lib

# Install ImageMagick PHP extension.
RUN mkdir -p /usr/src/php/ext/imagick && \
  curl --silent --location https://pecl.php.net/get/imagick-${IMAGEMAGICK_VERSION}.tgz | tar zx --strip-components=1 -C /usr/src/php/ext/imagick && \
  export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" && \
  docker-php-ext-install imagick

# Install Composer
RUN curl --silent https://getcomposer.org/composer.phar -o /usr/local/bin/composer && \
  chmod 755 /usr/local/bin/composer

# Install wp-cli.
RUN curl --silent https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar --output /usr/local/bin/wp && \
  chmod 775 /usr/local/bin/wp && \
  echo "alias wp='/usr/local/bin/wp --allow-root'" >> /etc/bash.bashrc

# Install Drush.
RUN curl --silent https://github.com/drush-ops/drush-launcher/releases/download/0.4.2/drush.phar  --output /usr/local/bin/drush && \
  chmod 775 /usr/local/bin/drush

# Install Node and NPM.
RUN apt-get autoremove -yqq nodejs
RUN mkdir -p /usr/local/bin/node && \
  cd /usr/local/bin/node && \
  curl --silent https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz | tar Jx --strip-components=1
RUN echo "export PATH=\$PATH:/usr/local/bin/node/bin" >> /etc/bash.bashrc

# Install Symfony CLI.
RUN curl -sS https://get.symfony.com/cli/installer | bash && \
  echo "export PATH=\$PATH:\$HOME/.symfony/bin" >> /etc/bash.bashrc

# Install foreman
RUN apt-get update && \
  apt-get install -yqq ruby && \
  gem install foreman

# Install GitHub CLI.
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |  tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
  apt-get update -qq && \
  apt-get install -yqq gh

# Install the AWS CLI.
RUN curl --silent "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/aws.zip" && \
  unzip "/tmp/aws.zip" -d "/tmp/" && \
  /tmp/aws/install

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
  filter \
  headers \
  macro \
  request \
  rewrite

# Set the Apache path
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Allow Apache to log to actual files by removing the current symlinks.
RUN rm -f /var/log/apache2/* 

# Modify Apache to run our script before startup
RUN apt-get -qq update && \
  apt-get install -yqq iproute2
ADD ./startup.sh /usr/local/bin/startup.sh
RUN cat /usr/local/bin/apache2-foreground | \
  sed -e 's/^\(exec .*\)$/\/usr\/local\/bin\/startup.sh\n\n\1/' > /tmp/apache2-foreground && \
  chmod 755 /tmp/apache2-foreground && \
  mv /tmp/apache2-foreground /usr/local/bin/apache2-foreground

# Clean up packages.
RUN apt-get autoremove -yqq \
  g++ \
  libjpeg62-turbo-dev \
  libpng-dev

# Clean up
RUN apt-get clean && rm -rf \
  /tmp/* \
  /usr/src/* \
  /var/lib/apt/lists/* \
  /var/tmp/*
