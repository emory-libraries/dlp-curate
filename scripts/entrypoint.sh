#!/bin/sh
set -e

mkdir -p /app/tmp/pids
rm -f /app/tmp/pids/*

# Run the command
exec "$@"
