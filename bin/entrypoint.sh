#!/bin/bash
set -e

case "$1" in
  run_app)
    exec bundle exec puma -C config/puma.rb
  ;;
  *)
  exec bundle exec "$@"
  ;;
esac
