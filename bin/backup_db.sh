#!/bin/bash
 
if [ -z "$1" ]
  then
    echo "You must call this script with an argument specifying the name of the database to backup"
    exit
fi

DB_NAME=$1
DATETIME=$(date +"%Y-%m-%d:%T")
FILENAME="$DB_NAME-backup-$DATETIME.db"

pg_dump "postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME" > db_backups/$FILENAME && echo "Successfully backed up database $DB_NAME to $FILENAME"
