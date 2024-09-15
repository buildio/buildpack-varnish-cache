#!/usr/bin/env bash

# Function to check if a port is in use
is_port_in_use() {
  (echo > /dev/tcp/127.0.0.1/$1) &>/dev/null
}


# If /tmp/varnish already exists, this script has already been run
if [ -d /tmp/varnish ]; then
  # This is awful, but we cannot call exit here because it will kill the dyno
  echo "/tmp/varnish already exists. Exiting script."
  return 0  # Use exit 0 if it's a standalone script
else
  PORT=${PORT:-8080}

  # Find an available port for the app
  APP_PORT=8080  # Starting with 8080
  MAX_PORT=65535  # Maximum available port
  while is_port_in_use $APP_PORT || [ "$APP_PORT" -eq "$PORT" ]; do
    if [ "$APP_PORT" -ge "$MAX_PORT" ]; then
      echo "No available ports found."
      exit 1
    fi
    APP_PORT=$((APP_PORT + 1))
  done

  # Run Varnish on the Heroku-assigned port ($PORT) and forward traffic to $APP_PORT
  /app/vendor/varnish/sbin/varnishd -a :$PORT -b 127.0.0.1:$APP_PORT -n /tmp/varnish
  
  # Output varnish logs to stdout
  LOG_FORMAT='at=info method=%m path="%U" host=%{Host}i request_id=%{X-Request-Id}i fwd="%h" service=%Dms status=%s bytes=%b protocol=%H cache=%{Varnish:hitmiss}x'
  /app/vendor/varnish/bin/varnishncsa -F "$LOG_FORMAT" -n /tmp/varnish &

  # Export the new port for the app to use
  export PORT=$APP_PORT
  # Remove the APP_PORT variable from the environment
  unset APP_PORT
fi
