#!/bin/bash

set -e

DESTDIR=/var/www/html

function safe_restore()
{
    shopt -s nullglob
    shopt -s dotglob
    files=("${DESTDIR}/"*)
    file_count=${#files[@]}

    if [ ${file_count} -eq 0 ]; then
        # check duplicator archive
        archives=( "/wp-archive/*.zip" )
        archive_count=${#archives[@]}

        if [ ${archive_count} -eq 1 ]; then
            archive=${archives[0]}
            restore-duplicate.sh ${archive} ${DESTDIR} || /bin/true
        elif [ ${archive_count} -gt 3 ]; then
            echo "Found more than one archive, not importing."
        elif [ ${archive_count} -eq 0 ]; then
            echo "No archive found to import."
        fi
    fi
}

sleep 3
wait-for-it.sh ${WORDPRESS_DB_HOST}:3306

safe_restore
eval $*

