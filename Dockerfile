FROM composer:latest

LABEL maintainer "Michael Molchanov <mmolchanov@adyax.com>"

USER root

# SSH config.
RUN mkdir -p /root/.ssh
ADD config/ssh /root/.ssh/config
RUN chown root:root /root/.ssh/config && chmod 600 /root/.ssh/config

# Install base.
RUN apk add --update --no-cache \
  bash \
  build-base \
  bzip2 \
  curl \
  freetype \
  git \
  gzip \
  libbz2 \
  libffi \
  libffi-dev \
  libjpeg-turbo \
  libmcrypt \
  libpq \
  libpng \
  libxml2 \
  libxslt \
  mysql-client \
  openssh \
  libressl \
  libressl-dev \
  patch \
  procps \
  postgresql-client \
  rsync \
  sqlite \
  tar \
  unzip \
  wget \
  zlib \
  && rm -rf /var/lib/apt/lists/*

# PHP modules.
RUN set -xe \
  && apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    curl-dev \
    libedit-dev \
    libxml2-dev \
    sqlite-dev \
    autoconf \
    subversion \
    freetype-dev \
    libjpeg-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    bzip2-dev \
    libstdc++ \
    libxslt-dev \
    openldap-dev \
    make \
    patch \
    postgresql-dev \
  && export CFLAGS="$PHP_CFLAGS" \
    CPPFLAGS="$PHP_CPPFLAGS" \
    LDFLAGS="$PHP_LDFLAGS" \
  && docker-php-source extract \
  && cd /usr/src/php \
  && docker-php-ext-install bcmath zip bz2 mbstring pcntl xsl mysqli pgsql pdo_mysql pdo_pgsql \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install gd \
  && docker-php-ext-configure ldap --with-libdir=lib/ \
  && docker-php-ext-install ldap \
  && git clone --branch="develop" https://github.com/phpredis/phpredis.git /usr/src/php/ext/redis \
  && docker-php-ext-install redis \
  && php -m && php -r "new Redis();" \
  && pecl install channel://pecl.php.net/mcrypt-1.0.1 \
  && docker-php-source delete \
  && apk del .build-deps

# Set the Drush version.
ENV DRUSH_VERSION 8.1.15

# Install Drush 8 with the phar file.
RUN curl -fsSL -o /usr/local/bin/drush "https://github.com/drush-ops/drush/releases/download/$DRUSH_VERSION/drush.phar" \
  && chmod +x /usr/local/bin/drush

# Install docman.
RUN apk add --update --no-cache ruby ruby-dev \
  && rm -rf /var/cache/apk/* \
  && gem install --no-ri --no-rdoc -v 0.0.85 docman

# Install nodejs and grunt.
RUN apk add --update --no-cache nodejs nodejs-dev nodejs-npm \
  && rm -rf /var/cache/apk/* \
  && npm install -g grunt-cli \
  && grunt --version

# Install compass.
RUN gem install --no-ri --no-rdoc compass
