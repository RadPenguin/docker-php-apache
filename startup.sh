#!/bin/bash

# Setup xdebug.
XDEBUG_MODE=${XDEBUG_MODE:-off}
if [[ "$XDEBUG_MODE" != "off" ]]; then
  # Enable the development mode php ini.
  mv /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
  tee /usr/local/etc/php/conf.d/99-radpenguin.ini << EOF
extension_xdebug = 1
opcache.revalidate_freq = 0
opcache.validate_timestamps = 1
xdebug.mode = $XDEBUG_MODE
EOF

  # Ensure the xdebug folder is writable.
  mkdir -p /var/www/html/.xdebug/
  chown -R www-data:www-data /var/www/html/.xdebug/
fi
