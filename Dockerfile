FROM stackbrew/debian:jessie
MAINTAINER Matt Bentley <mbentley@mbentley.net>
RUN (echo "deb http://http.debian.net/debian/ jessie main contrib non-free" > /etc/apt/sources.list && echo "deb http://http.debian.net/debian/ jessie-updates main contrib non-free" >> /etc/apt/sources.list && echo "deb http://security.debian.org/ jessie/updates main contrib non-free" >> /etc/apt/sources.list)
RUN apt-get update

ENV NGINX_VER 1.7.6

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential dnsutils libpcre3 libpcre3-dev libpcrecpp0 libssl-dev php5-curl php5-gd php5-fpm php5-imagick php5-mcrypt php5-memcached php5-mysql supervisor zlib1g-dev wget whois

RUN (wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz -O /tmp/nginx-${NGINX_VER}.tar.gz && \
	cd /tmp && \
	tar xvf /tmp/nginx-${NGINX_VER}.tar.gz && \
	cd /tmp/nginx-${NGINX_VER} \
	&& ./configure --sbin-path=/usr/local/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --http-log-path=/var/log/nginx/access.log --with-http_dav_module --http-client-body-temp-path=/var/lib/nginx/body --with-http_ssl_module --with-http_realip_module --http-proxy-temp-path=/var/lib/nginx/proxy --with-http_stub_status_module --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --with-http_auth_request_module --user=www-data --group=www-data && \
	cd /tmp/nginx-${NGINX_VER} && \
	make && \
	make install && \
	rm /etc/nginx/*.default && \
	rm -rf /tmp/nginx-${NGINX_VER} /tmp/nginx-${NGINX_VER}.tar.gz)
RUN mkdir -p /var/lib/nginx /etc/nginx/sites-enabled /etc/nginx/sites-available /var/www

ADD nginx.conf /etc/nginx/nginx.conf
ADD php.conf /etc/nginx/php.conf
ADD default /etc/nginx/sites-available/default
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
RUN sed -i 's/;daemonize = yes/daemonize = no/g' /etc/php5/fpm/php-fpm.conf

VOLUME ["/var/log/nginx","/var/www"]
EXPOSE 80
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]