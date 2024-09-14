#!/usr/bin/env bash

# If /tmp/varnish already exists, this script has already been run
if [ -d /tmp/varnish ]; then
  # This is awful, but we cannot call exit here because it will kill the dyno
else
  # Function to check if a port is in use
  is_port_in_use() {
    (echo > /dev/tcp/127.0.0.1/$1) &>/dev/null
  }

  PORT=${PORT:-8080}

  # Find an available port for the app
  APP_PORT=8080  # Starting with 8080
  while is_port_in_use $APP_PORT || [ "$APP_PORT" -eq "$PORT" ]; do
      APP_PORT=$((APP_PORT + 1))
  done

  # Run Varnish on the Heroku-assigned port ($PORT) and forward traffic to $APP_PORT
  /app/vendor/varnish/sbin/varnishd -a :$PORT -b 127.0.0.1:$APP_PORT -n /tmp/varnish
  # Output varnish logs to stdout
  /app/vendor/varnish/bin/varnishncsa -n /tmp/varnish &

  # Export the new port for the app to use
  export PORT=$APP_PORT
  # Remove the APP_PORT variable from the environment
  unset APP_PORT
fi
