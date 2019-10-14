#!/bin/bash

# Setup the xdebug remote host.
XDEBUG_REMOTE_HOST=$( /sbin/ip route | awk '/default/ { print $3 }' )
echo "xdebug.remote_host=${XDEBUG_REMOTE_HOST}" | tee -a  /usr/local/etc/php/conf.d/custom.ini
