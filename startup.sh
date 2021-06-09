#!/bin/bash

# Setup xdebug.
XDEBUG_MODE=${XDEBUG_MODE:-off}
if [[ "$XDEBUG_MODE" != "off" ]]; then
  XDEDBUG_ENABLED=1
else
  XDEBUG_ENABLED=0
fi

tee /usr/local/etc/php/conf.d/99-radpenguin.ini << EOF
extension_xdebug=$XDEDBUG_ENABLED
xdebug.mode=$XDEBUG_MODE
EOF

# Ensure the xdebug folder is writable.
if [[ "$XDEDBUG_ENABLED" -eq 1 ]]; then
  mkdir -p /var/www/html/.xdebug/
  chown -R www-data:www-data /var/www/html/.xdebug/
fi
