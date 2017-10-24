# docker-compose-wp-duplicate
Run a Wordpress-Duplicator backup using Docker Compose

## Usage

Install the duplicator plugin from https://wordpress.org/plugins/duplicator/

Use duplicator to create an archive and installer and download these for later.
There is a video on the Duplicator link above with more information.

Install docker-compose

Clone this repo

Copy the archive and installer to the wp-archive foldr.

Run your blog in docker  

```sh
docker-compose up --build
```

Your wordpress site will now be available at ```http://localhost```


Note - changes are currently not saved.
