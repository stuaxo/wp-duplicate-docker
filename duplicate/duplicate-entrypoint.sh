#!/bin/bash

set -e

DESTDIR=/var/www/html

function safe_restore()
{
    shopt -s nullglob
    shopt -s dotglob
    files=("${DESTDIR}/"*)
    if [ "$1" = "--overwrite" ] || [ ${#files[@]} -eq 0 ]; then
        # check duplicator archive
        archives=( "/wp-archive/*.zip" )
        archive_count=${#archives[@]}

        if [ ${archive_count} -eq 1 ]; then
            archive=${archives[0]}
            restore-duplicate.sh ${archive} ${DESTDIR} $1 || /bin/true
        elif [ ${archive_count} -gt 3 ]; then
            echo "Found more than one archive, not importing."
        elif [ ${archive_count} -eq 0 ]; then
            echo "No archive found to import."
        fi
    fi
}

wait-for-it.sh ${WORDPRESS_DB_HOST}:3306

if [ -z "$1" ] || [ "$1" = "--overwrite" ]; then
    safe_restore $@
    apache2-foreground
else
    exec "$@"
fi

