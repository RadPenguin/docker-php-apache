#!/bin/bash

# Setup xdebug.
XDEBUG_REMOTE_HOST=$( /sbin/ip route | awk '/default/ { print $3 }' )

tee /usr/local/etc/php/conf.d/99-radpenguin.ini << EOF
xdebug.client_host=${XDEBUG_REMOTE_HOST}
xdebug.mode=${XDEBUG_MODE:-off}
EOF

