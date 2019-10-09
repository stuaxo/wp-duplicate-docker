#!/bin/bash
#
# Bring up wordpress on apache and mysql from a backup made with wordpress-duplicator.
#
# This is to enable a local copy of your wordpress blog on docker, as a backup.
#
# MIT License - Stuart Axon 2017-2019.
#
# return codes
# 1 - issue with archive
# 2 - issue with database
# 3 - issue with destination directory
#
set -e

shopt -s nullglob
shopt -s dotglob

WORDPRESS_DB_HOST=${WORDPRESS_DB_HOST:-localhost}
WORDPRESS_DB_USER=${WORDPRESS_DB_USER:-wordpress}
WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD:-password}

export MYSQL_PWD=${WORDPRESS_DB_PASSWORD}
export MYSQL="mysql -h${WORDPRESS_DB_HOST} -u${WORDPRESS_DB_USER}"


function is_directory_empty()
{
    # set errorlevel to 1 if directory specified in $1 is not empty.
    destdir=$1
    files=("${destdir}/"*)
    file_count=${#files[@]}
    if [ ${file_count} -gt 2 ]; then
        return 1
    else
        return 0
    fi
}

function is_wordpress_db_populated() {
    # set errorlevel to 1 if database contains a wordpress db
    table_count=$(${MYSQL} --batch --raw -N -e "select count(*) from information_schema.tables where table_schema='wordpress';")
    if [ ${table_count} -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

function restore_wordpress_db()
{
    SQL=$1
    eval "${MYSQL} --batch --raw -N -D${WORDPRESS_DB_NAME} < $1"
}

function update_site_urls()
{
    # Update site URL to the one passed in $1 so the site
    # can be served from a whichever URL is needed from the local docker container.
SQL="
SET @url:='$1';
SET @oldurl:= (SELECT option_value FROM wp_options WHERE option_name = 'siteurl');

UPDATE wp_options
SET    option_value = @url WHERE option_name = 'siteurl' OR option_name = 'home';

UPDATE wp_posts
SET    post_content = Replace(post_content, @oldurl, @url);

UPDATE wp_posts
SET    guid = Replace(guid, @oldurl, @url);

UPDATE wp_posts
SET    post_content = Replace(post_content, @oldurl, @url);

UPDATE wp_postmeta
SET    meta_value = Replace(meta_value, @oldurl, @url);
"
    ${MYSQL} -D${WORDPRESS_DB_NAME} -e "${SQL}"
}


function file_is_wordpress_duplicator_archive()
{
    # Set errorlevel if $1 is not a zipfile containing database.sql and wp-config.php
    archive=$1
    unzip -l ${archive} database.sql wp-config.php | grep -o '2 files' > /dev/null
    if [ "$?" -ne 0 ]; then
        return 1
    else
        return 0
    fi
}

function create_wordpress_database()
{
    # Create the wordpress database, this does not check for errors,
    # as there is another check that verifies the database is empty.
    ${MYSQL} -e "CREATE DATABASE ${WORDPRESS_DB_NAME};" 2> /dev/null || /bin/true
}

function drop_wordpress_db()
{
    # Drop the wordpress database, this does not check for errors,
    # as there is another check that verifies the database is empty.
    ${MYSQL} -e "DROP DATABASE ${WORDPRESS_DB_NAME};" 2> /dev/null || /bin/true
}

function restore_files()
{
    # Restore the database backup from the duplicator archive.
    archive=$1
    destdir=$2
    unzip ${archive} -x database.sql -d ${destdir}
}

function configure_wordpress()
{
    # Create a wp-config.php file from the file passed in to $1
    # Database settings are modified to use the environment
    # variables:
    #   WORDPRESS_DB_HOST, WORDPRESS_DB_NAME, WORDPRESS_DB_USER, WORDPRESS_DB_PASSWORD
    wp_conf=$1
    cp wp-config.php wp-config.php.bak
    sed -i "/DB_HOST/s/'[^']*'/'${WORDPRESS_DB_HOST}'/2" ${wp_conf}
    sed -i "/DB_NAME/s/'[^']*'/'${WORDPRESS_DB_NAME}'/2" ${wp_conf}
    sed -i "/DB_USER/s/'[^']*'/'${WORDPRESS_DB_USER}'/2" ${wp_conf}
    sed -i "/DB_PASSWORD/s/'[^']*'/'${WORDPRESS_DB_PASSWORD}'/2" ${wp_conf}
}

function configure_apache()
{
    # Setup apache to respond to the URL specified in the
    # WORDPRESS_URL environment variable and add the rewrite module.
    apache_conf=$1
    if [ -n ${WORDPRESS_URL} ]; then
        echo ServerName ${WORDPRESS_URL} >> ${apache_conf}
    fi
    a2enmod rewrite
}

function restore_duplicate()
{
    archive=$1
    echo "Restore database"
    tmpdir=$(mktemp -d /tmp/duperestore.XXXXXXXXX)
    mkdir -p ${tmpdir}
    unzip -q ${archive} database.sql -d ${tmpdir}

    restore_wordpress_db ${tmpdir}/database.sql
    if [ -n ${WORDPRESS_URL} ]; then
        echo "Update urls to ${WORDPRESS_URL}" 1>&2
        update_site_urls ${WORDPRESS_URL}
    else
        echo Not updating urls
    fi

    rm ${tmpdir}/database.sql
    rmdir ${tmpdir}

    is_directory_empty ${destdir}
    if [ "$3" = "--overwrite" ] || [ $? -eq 0 ]; then
        echo "Restore files..." 1>&2
        restore_files ${archive} ${destdir}
        echo "configure_wordpress ..." 1>&2
        configure_wordpress ${destdir}/wp-config.php
        echo "configure_apache ..." 1>&2
        configure_apache '/etc/apache2/apache2.conf'
    else
        echo "Destination directory already populated, not restoring" 1>&2
        return 3
    fi
}

function usage () {
# Using a here doc with standard out.
cat <<-END
Usage:
------
   restore-duplicate <duplicate-archive.zip> <dest_dir>

   duplicate-archive - archive generated by the Wordpress Duplicator plugin.
   destdir           - empty directory setup as an apache docroot.

   Environment variable, default:

    WORDPRESS_DB_HOST       localhost
    WORDPRESS_DB_USER       wordpress
    WORDPRESS_DB_PASSWORD   password

    WORDPRESS_URL

    If set then the script will attempt to update the database and apache to
    use this url.
END
}

function main()
{
    if [ $# -lt 2 ]; then
        echo $#
        echo $*
        usage
        exit
    fi

    archive=$1
    destdir=$2

    file_is_wordpress_duplicator_archive ${archive}
    if [ $? -eq 1 ]; then
        echo "${archive} was not created by wordpress-duplicator" 1>&2
        exit 1
    fi

    if [ "$3" = "--overwrite" ]; then
        rm -rf ${destdir}/* ${destdir}/.??*
    fi
    create_wordpress_database

    is_wordpress_db_populated
    if [ "$3" = "--overwrite" ] && [ $? -eq 0 ]; then
        restore_duplicate ${archive} ${destdir} $3
        exit $?

    else
        echo "Database already has tables, not restoring" 1>&2
        exit 2
    fi
}

main $*
