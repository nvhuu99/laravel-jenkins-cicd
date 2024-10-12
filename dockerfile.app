FROM ubuntu:20.04

ENV PHP_CONF_DIR=/etc/php/8.1/app/apache2/conf.d
ENV APACHE_CONF_DIR=/etc/apache2

ARG APP_ENV=""
ARG DB_NAME=""
ARG DB_USER=""
ARG DB_PASSWORD=""

USER root

# Set timezone
RUN ln -snf "/usr/share/zoneinfo/Asia/Ho_Chi_Minh" "/etc/localtime" && echo "Asia/Ho_Chi_Minh" > "/etc/timezone"

# Update package and install necessary tools
RUN apt-get update && apt-get install -y vim git wget curl gnupg software-properties-common
RUN add-apt-repository ppa:ondrej/php -y \
    && apt-get update && apt-get install -y \
        apache2 php8.1 php8.1-cli php8.1-fpm php8.1-mysql php8.1-xml php8.1-mbstring php8.1-zip php8.1-curl libapache2-mod-php8.1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Config Apache2 & PHP 
COPY app/apache2/conf.d ${APACHE_CONF_DIR}/conf-available
COPY app/apache2/sites-available/${APP_ENV} ${APACHE_CONF_DIR}/sites-available
COPY app/php/conf.d ${PHP_CONF_DIR}/conf.d
RUN a2enmod ssl proxy rewrite && \
    a2enconf app-custom.conf ${APP_ENV}-custom.conf

# Install Composer
WORKDIR /home/root
RUN wget https://getcomposer.org/download/2.5.7/composer.phar
RUN chmod +x composer.phar && mv composer.phar /usr/local/bin/composer

# Install Nodejs 18.x
WORKDIR /home/root
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Copy app source
COPY app/src/ /var/www/html/laravel-app/

CMD ["apachectl", "-D", "FOREGROUND"]
