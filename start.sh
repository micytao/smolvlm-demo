#!/bin/bash

# Exit on any error
set -e

echo "Starting SmolVLM Real-time Camera Demo..."

# Create log directory
mkdir -p /var/log

# Start supervisor which will manage both nginx and llama-server
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
