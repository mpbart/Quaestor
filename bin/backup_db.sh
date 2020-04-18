#!/bin/bash
 
if [ -z "$1" ]
  then
    echo "You must call this script with an argument specifying the name of the database to backup"
    exit
fi

DB_NAME=$1
DATETIME=$(date +"%Y-%m-%d:%T")

pg_dump -h /tmp/postgres/ -d $DB_NAME > db_backups/"$DB_NAME-backup-$DATETIME.db"
