#!/usr/bin/env bash

# Function to check if a port is in use
is_port_in_use() {
    local port=$1
    if lsof -i :$port >/dev/null; then
        return 0  # Port is in use
    else
        return 1  # Port is available
    fi
}

PORT=${PORT:-8080}

# Find an available port for the app
APP_PORT=8080  # Starting with 8080
while is_port_in_use $APP_PORT || [ "$APP_PORT" -eq "$PORT" ]; do
    APP_PORT=$((APP_PORT + 1))
done

# Run Varnish on the Heroku-assigned port ($PORT) and forward traffic to $APP_PORT
/app/vendor/varnish/sbin/varnishd -a :$PORT -b 127.0.0.1:$APP_PORT

# Export the new port for the app to use
export PORT=$APP_PORT
# Remove the APP_PORT variable from the environment
unset APP_PORT
