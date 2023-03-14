#!/bin/bash

# Setup xdebug.
XDEBUG_MODE=${XDEBUG_MODE:-off}
if [[ "$XDEBUG_MODE" != "off" ]]; then
  # Enable the development mode php ini.
  cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
  tee /usr/local/etc/php/conf.d/99-radpenguin.ini << EOF
extension_xdebug = 1
opcache.revalidate_freq = 0
opcache.validate_timestamps = 1
xdebug.mode = $XDEBUG_MODE
EOF
fi

# Ensure the xdebug folder exists and is writable.
XDEBUG_OUTPUT_DIR=$( php -i | grep xdebug.output_dir | awk '{print $3}' )
if [[ -n $XDEBUG_OUTPUT_DIR ]] && [[ ! -e "$XDEBUG_OUTPUT_DIR" ]]; then
  mkdir -p "$XDEBUG_OUTPUT_DIR"
  chown -R www-data:www-data "$XDEBUG_OUTPUT_DIR"
fi
