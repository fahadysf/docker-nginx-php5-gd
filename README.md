mbentley/nginx-php5
===================

docker image for nginx + php5-fpm
based off of stackbrew/debian:jessie

To pull this image:
`docker pull mbentley/nginx-php5`

Example usage:
`docker run -i -t -p 80 -v /data/logs:/var/log/nginx -v /data/www:/var/www mbentley/nginx-php5`

By default, this just runs a basic nginx server that listens on port 80.  The default webroot is `/var/www`.
