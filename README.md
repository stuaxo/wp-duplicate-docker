# docker-compose-wp-duplicate
Run a Wordpress-Duplicator backup using Docker Compose.

# Use case

I use this to run a copy of my old wordpress blog in case I want to make tweaks and re-import the data into my new non-wordpress site.


## Features

 - Sets up Wordpress, Apache and Mysql on build
 - Modifies site urls to localhost or custom URL so links work locally.

## Usage

On wordpress install the duplicator plugin from https://wordpress.org/plugins/duplicator/

There is a video at the link above with more information on using duplicator itself.

[Install Docker Compose](https://docs.docker.com/compose/install/)

Clone this repository

```sh
$ git clone https://github.com/stuaxo/wp-duplicate-docker.git
```

Copy the duplicator archive and `installer.php` to the `wp-archive` folder.

Set the correct database version:
- In the ```db``` section, change the database to the version your wordpress instance needs.
- The default site url is http://localhost if you need to change this edit ```WORDPRESS_URL```.

Run your blog in docker:

```sh
docker-compose up --build
```

Subsequent runs don't need previous `--build` step:
```sh
$docker-compose up
```

Your wordpress site will now be available at ```http://localhost``` or the URL you chose.


## Issues
By design: changes to the duplicate site are currently not saved, this is fine for my purposes but my not be for you.

## TODO
Provide a getting-started script that can check the database version.

# Thanks

Wordpress - for Wordpress and the wordpress docker file, that this uses.

Various Docker file authors, I looked at quite a few in putting this together.
