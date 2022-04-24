# rebased/repackaged base image that only updates existing packages
FROM mbentley/debian:jessie
LABEL maintainer="Matt Bentley <mbentley@mbentley.net>"

ENV NGINX_VER 1.16.1

# php5-curl php5-gd php5-fpm php5-imagick php5-mcrypt php5-memcache php5-memcached php5-mysql

COPY sources.list /etc/apt/sources.list
RUN apt-get update && apt-get -y install dpkg-dev devscripts

# Modify the configure flags for php-gd and start the build process.
RUN cd /tmp && apt-get -y source php5 && DEBIAN_FRONTEND=noninteractive apt-get -y build-dep php5 && \
  cd php5-5.6.33+dfsg && \
  sed -i 's/--with-gd=shared,\/usr/--with-gd=shared/g' debian/rules && \
  debuild -b -uc -us 

# Build php-json
RUN cd /tmp && apt-get -y source php-json && \apt-get -y build-dep php-json && \
  cd php-json-1.3.6  && \
  debuild -b -uc -us 

# Install the packages
RUN cd /tmp && DEBIAN_FRONTEND=noninteractive \
  dpkg -i php5-common*.deb \
  php5-json*.deb

RUN cd /tmp && DEBIAN_FRONTEND=noninteractive dpkg -i php5-cli*.deb \
  php5-fpm*.deb \
  php5-mcrypt*.deb 

RUN cd /tmp && DEBIAN_FRONTEND=noninteractive dpkg -i php5-mysql_*.deb php5-gd*.deb

RUN apt-get -y install php5-imagick php5-memcache php5-memcached

# Compiling NGINX
RUN  wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz -O /tmp/nginx-${NGINX_VER}.tar.gz &&\
  cd /tmp &&\
  tar xvf /tmp/nginx-${NGINX_VER}.tar.gz &&\
  cd /tmp/nginx-${NGINX_VER} &&\
  ./configure --sbin-path=/usr/local/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --http-log-path=/var/log/nginx/access.log --with-http_dav_module --http-client-body-temp-path=/var/lib/nginx/body --with-http_ssl_module --with-http_realip_module --http-proxy-temp-path=/var/lib/nginx/proxy --with-http_stub_status_module --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --with-http_auth_request_module --user=www-data --group=www-data &&\
  cd /tmp/nginx-${NGINX_VER} &&\
  make &&\
  make install &&\
  rm /etc/nginx/*.default &&\
  rm -rf /tmp/nginx-${NGINX_VER} /tmp/nginx-${NGINX_VER}.tar.gz &&\
  apt-get purge -y build-essential &&\
  apt-get autoremove -y &&\
  rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/nginx /etc/nginx/sites-enabled /etc/nginx/sites-available /var/www

COPY nginx.conf /etc/nginx/nginx.conf
COPY php.conf /etc/nginx/php.conf
COPY default /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default &&\
  sed -i 's/;daemonize = yes/daemonize = no/g' /etc/php5/fpm/php-fpm.conf &&\
  sed -i 's/post_max_size = 8M/post_max_size = 16M/g' /etc/php5/fpm/php.ini &&\
  sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 16M/g' /etc/php5/fpm/php.ini

EXPOSE 80
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]
