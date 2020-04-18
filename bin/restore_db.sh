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
psql -h /tmp/postgres/ $DB_NAME < "$BACKUP_FILE"
