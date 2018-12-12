# docker-compose-wp-duplicate
Run a Wordpress-Duplicator backup using Docker Compose.

# Use case

I use this to run a copy of my old wordpress blog in case I want to make tweaks and re-import the data into my new non-wordpress site.


## Features

 - Automatically sets up database on build
 - Modifies site urls to localhost or user setting

## Usage

Install the duplicator plugin from https://wordpress.org/plugins/duplicator/

Use duplicator to create an archive and installer, download them for the subsequent steps.
There is a video on the Duplicator link above with more information.

[Install Docker Compose](https://docs.docker.com/compose/install/)

Clone this repository

```sh
$ git clone https://github.com/stuaxo/wp-duplicate-docker.git
```

Copy the archive and installer to the wp-archive foldr.

Edit settings.
- In the ```db``` section, change the database to the version your wordpress instance needs
- The default site url is http://localhost if you need to change this EDIT ```WORDPRESS_URL```

Run your blog in docker  

```sh
docker-compose up --build
```

Your wordpress site will now be available at ```http://localhost``` or the URL you chose.


## Issues
Changes to the duplicate site are currently not saved.
