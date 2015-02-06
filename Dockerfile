# Piwik-Nginx
#
# Version 1.0
FROM ubuntu-debootstrap:14.04
MAINTAINER Martijn van Maurik <docker@vmaurik.nl>

# Ensure UTF-8
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
RUN echo deb http://nginx.org/packages/mainline/ubuntu trusty nginx > /etc/apt/sources.list.d/nginx-stable-trusty.list
RUN apt-get update
RUN apt-get -y upgrade

# Install
RUN apt-get install -y nginx \
    php5-fpm php5-mysql php-apc php5-imagick php5-imap php5-mcrypt php5-gd libssh2-php git php5-cli curl php5-curl php5-memcached php5-geoip php5-dev

RUN mkdir -p /etc/nginx/sites-enabled

RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php5/fpm/php.ini
ADD nginx.conf /etc/nginx/nginx.conf
ADD nginx-site.conf /etc/nginx/sites-enabled/default
RUN sed -i -e 's/^listen =.*/listen = \/var\/run\/php5-fpm.sock/' /etc/php5/fpm/pool.d/www.conf

WORKDIR /data
RUN git clone https://github.com/piwik/piwik.git . && git submodule init && git submodule update
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin
RUN /usr/bin/composer.phar install
RUN chown -R www-data:www-data /data

# Create the section for persistent files
RUN mkdir /var/lib/piwik

# Move the files that need to be persistent and create symbolic links to them
RUN mv /data/config /var/lib/piwik/ && ln -s /var/lib/piwik/config /data/config
RUN mv /data/plugins /var/lib/piwik/ && ln -s /var/lib/piwik/plugins /data/plugins

VOLUME ["/var/lib/piwik/"]

EXPOSE 80
ADD start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
