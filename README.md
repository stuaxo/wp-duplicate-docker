# docker-compose-wp-duplicate
Run a Wordpress-Duplicator backup using Docker Compose.

Restore a zip file and installer.php created by wordpress duplicator
to an immutabke docker container running locally.

```
ls wp-archive
20171025_devstu_ed680e55e011c2356456171025215736_archive.zip  installer.php
```

```
docker-compose up
```

This was used to help migrate my own wordpress, use at
your own risk, patches welcome.


## Prerequisites

### Locally

- Install docker-compose

- Clone this repo.


### On your wordpress site:

Install the duplicator plugin from https://wordpress.org/plugins/duplicator/
The link has a useful video about using duplicator.


# Usage

Copy the duplicator archive into the folder wp-app.

Note, you can only have *ONE* archive in this directory at a time,
the script will not continue if there are more.

Run your blog in docker  

```sh
docker-compose up --build
```

Subsequent runs don't need the --build
```
docker-compose up
```

Your wordpress site will now be available at ```http://localhost```


## Persistance

wp-app and wp-mysql hold the wordpress site and mysql database respectively.


## Overwriting with a new archive

If you make changes on your original site you move the old archive
out of the wp-archive folder, then backup with duplicator again.

Once the zip file and installer.php are in wp-archive, you can update
the database in the container, with the --overwrite commandline.

```
docker-compose run duplicate --overwrite
```


# Issues

Currently the volumes wp-app etc are all owned by root which isn't ideal.


# Thanks

Wordpress - for Wordpress and the wordpress docker file, that this uses.

Various Docker file authors, I looked at quite a few in putting this together.
