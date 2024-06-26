#!/bin/bash
set -e

case "$1" in
  run_app)
    exec bundle exec puma -C config/puma.rb
  ;;

  sidekiq)
    exec bundle exec sidekiq -c 3
  ;;

  backup_db)
    ./bin/backup_db.sh "$2"
  ;;

  restore_db)
    ./bin/restore_db.sh "$2" "$3"
  ;;

  *)
  exec bundle exec "$@"
  ;;
esac
