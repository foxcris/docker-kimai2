FROM debian:stretch

MAINTAINER foxcris

#repositories richtig einrichten
RUN echo 'deb http://deb.debian.org/debian stretch main' > /etc/apt/sources.list
RUN echo 'deb http://deb.debian.org/debian stretch-updates main' >> /etc/apt/sources.list
RUN echo 'deb http://security.debian.org stretch/updates main' >> /etc/apt/sources.list
#backports fuer certbot
RUN echo 'deb http://ftp.debian.org/debian stretch-backports main' >> /etc/apt/sources.list

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales && apt-get clean
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF8
#automatische aktualiserung installieren + basic tools
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get install -y nano less wget anacron unattended-upgrades apt-transport-https htop curl unzip&& apt-get clean

#apache
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 libapache2-mod-php7.0 php-mysql php-intl php-zip sudo composer && apt-get clean

#certbot
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get install -y python-certbot-apache -t stretch-backports && apt-get clean

ARG KIMAI_VERSION=0.7
ARG KIMAI_SHA256=bae9a370c1760923b80f95c1679d13849c415e3f464416fb04a68164b769eb22

RUN curl -L -o kimai2.zip https://github.com/kevinpapst/kimai2/archive/${KIMAI_VERSION}.zip \
  && echo "${KIMAI_SHA256} kimai2.zip" | sha256sum -c \
  && mkdir -p /var/www/html \
  && unzip kimai2.zip -d /var/www/html/ \
  && chown -R www-data:www-data /var/www/html/ \
  && mv /var/www/html/kimai2-${KIMAI_VERSION}/* /var/www/html/\
  && rm -r /var/www/html/kimai2-${KIMAI_VERSION}\
  && rm *.zip

RUN mv /etc/apache2/sites-available/ /etc/apache2/sites-available_default
RUN mkdir /etc/apache2/sites-available/ 
RUN mv /etc/letsencrypt/ /etc/letsencrypt_default
RUN mkdir /etc/letsencrypt/

RUN rm /var/www/html/index.html
RUN sed -i 's#/var/www/html#/var/www/html/public#' /etc/apache2/sites-enabled/000-default.conf
RUN cd /var/www/html && sudo -u www-data composer install --no-dev --optimize-autoloader

VOLUME /var/log/apache2
VOLUME /etc/letsencrypt

EXPOSE 80 443
COPY docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
