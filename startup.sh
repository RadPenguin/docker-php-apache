#!/bin/bash

# Setup xdebug.
tee /usr/local/etc/php/conf.d/99-radpenguin.ini << EOF
xdebug.mode=${XDEBUG_MODE:-off}
EOF

# Ensure the xdebug folder is writable.
if [[ "$XDEBUG_MODE" != "off" ]]; then
  mkdir -p /var/www/html/.xdebug/
  chown -R www-data:www-data /var/www/html/.xdebug/
fi
