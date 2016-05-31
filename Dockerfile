##
# Base image
# Forked from https://github.com/laraedit/laraedit-docker
##

FROM ubuntu:16.04
MAINTAINER "appkr" <juwonkim@me.com>

##
# Set environment variables
##

ENV APP_NAME myapp
ENV APP_EMAIL yours@example.com
ENV APP_DOMAIN myapp.local
ENV DEBIAN_FRONTEND noninteractive
ENV USERNAME appuser

##
# Update the container
##

RUN apt-get update
RUN apt-get upgrade -y

##
# Intall prerequisites
##

RUN apt-get install -y \
    software-properties-common \
    curl \
    build-essential \
    debconf-utils \
    dos2unix \
    gcc \
    git \
    libmcrypt4 \
    libpcre3-dev \
    make \
    # memcached \
    python2.7-dev \
    python-pip \
    re2c \
    unattended-upgrades \
    nano \
    wget;

##
# Add repositories
# We will install databases as a separate container
##

RUN apt-add-repository ppa:nginx/stable -y
RUN apt-get update

##
# Set locale
##

RUN echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
RUN locale-gen en_US.UTF-8
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime

##
# Setup bash
##

COPY ./config/.bashrc /root/.bashrc

##
# Install Nginx
##

RUN apt-get install -y --force-yes nginx

COPY ./config/sites-available /etc/nginx/sites-available
RUN ln -fs "/etc/nginx/sites-available/default" "/etc/nginx/sites-enabled/default"

COPY ./config/nginx.conf /etc/nginx/nginx.conf

VOLUME ["/var/cache/nginx"]
VOLUME ["/var/log/nginx"]

##
# Create a user
##

RUN useradd $USERNAME -g www-data -m
RUN chown -h -Rf $USERNAME:www-data /var/www
RUN usermod -G www-data root

##
# Install PHP & FPM
##

RUN apt-get install -y --force-yes \
    php7.0-cli \
    php7.0-dev \
    php-curl \
    php-gd \
    php-mysql \
    php-mbstring \
    php-memcached \
    php-sqlite3 \
    php-xdebug \
    php-xml \
    php7.0-bcmath \
    php7.0-fpm \
    php7.0-intl \
    php7.0-mcrypt \
    php7.0-readline \
    php7.0-zip;

RUN sed -i "s/expose_php = .*/expose_php = Off/" /etc/php/7.0/cli/php.ini
RUN sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/cli/php.ini
RUN sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/cli/php.ini
RUN sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/cli/php.ini
RUN sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini
RUN sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini
RUN sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.0/fpm/php.ini
RUN sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.0/fpm/php.ini
RUN sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN find /etc/php/7.0/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;
COPY config/fastcgi_params /etc/nginx/fastcgi_params
RUN mkdir -p /run/php/ && chown -Rf $USERNAME:www-data /run/php

##
# Install Composer & PHPUnit
##

RUN curl -sS https://getcomposer.org/installer | php
RUN chmod 755 composer.phar
RUN mv composer.phar /usr/local/bin/composer
RUN printf "\nPATH=\"~/.composer/vendor/bin:\$PATH\"\n" | tee -a ~/.bashrc

RUN wget https://phar.phpunit.de/phpunit.phar
RUN chmod 755 phpunit.phar
RUN mv phpunit.phar /usr/local/bin/phpunit

RUN composer global require hirak/prestissimo

##
# Install SQLite
##

RUN apt-get install -y sqlite3 libsqlite3-dev

##
# Install Supervisor
##

RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor
COPY ./config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
VOLUME ["/var/log/supervisor"]

##
# Clean up cached & Unnecessary
##

RUN apt-get remove --purge -y software-properties-common
RUN apt-get autoremove -y
RUN apt-get clean
RUN apt-get autoclean
RUN echo -n > /var/lib/apt/extended_states
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /usr/share/man/??
RUN rm -rf /usr/share/man/??_*

##
# Boot & Set entrypoint
##

EXPOSE 80 443
ENTRYPOINT ["/bin/bash","-c"]
CMD ["/usr/bin/supervisord"]