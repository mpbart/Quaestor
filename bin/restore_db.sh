#!/bin/bash

if [ -z "$1" ]
  then
    echo "You must call this script with an argument specifying the name of the database to restore"
    exit
elif [ -z "$2" ]
  then
    echo "You must call this script with an argument specifying the name of the file to restore from"
    exit
fi

DB_NAME=$1
BACKUP_FILE=$2
psql postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME < db_backups/"$BACKUP_FILE" && echo "Successfully restored $DB_NAME from $BACKUP_FILE"
