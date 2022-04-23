# rebased/repackaged base image that only updates existing packages
FROM mbentley/debian:jessie
LABEL maintainer="Matt Bentley <mbentley@mbentley.net>"

ENV NGINX_VER 1.16.1

# php5-curl php5-gd php5-fpm php5-imagick php5-mcrypt php5-memcache php5-memcached php5-mysql

RUN apt-get update &&\
  apt-get install -y build-essential dnsutils imagemagick libpcre3 libpcre3-dev libpcrecpp0 libssl-dev ssmtp supervisor zlib1g-dev wget whois && \
  apt-get install -y wget bzip2 gcc libxml2-dev libz-dev libbz2-dev libcurl4-openssl-dev libmcrypt-dev libpq-dev libxslt-dev memcached libmemcached-tools && \
  wget http://de2.php.net/get/php-5.6.33.tar.bz2/from/this/mirror -O php-5.6.33.tar.bz2 && \
  tar jxf ./php-5.6.33.tar.bz2 && \
  cd php-5.6.33 && ./configure --prefix=/opt/php-5.6 --with-pdo-pgsql --with-zlib-dir --with-freetype-dir --enable-mbstring --with-libxml-dir=/usr \
  --enable-soap --enable-calendar --with-curl --with-mcrypt --with-zlib --with-pgsql --disable-rpath --enable-inline-optimization --with-bz2 \
  --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl --enable-mbregex --enable-exif --enable-bcmath --with-mhash \
  --enable-zip --with-pcre-regex --with-pdo-mysql --with-mysqli --with-mysql-sock=/var/run/mysqld/mysqld.sock --with-jpeg-dir=/usr --with-png-dir=/usr \
  --enable-gd-native-ttf --with-fpm-user=www-data --with-fpm-group=www-data --with-libdir=/lib/x86_64-linux-gnu --enable-ftp --with-kerberos --with-gettext \
  --with-xmlrpc --with-xsl --enable-opcache --enable-fpm && \
  make && \
  make install

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
