FROM php:8.4-fpm

RUN apt-get update && apt-get install -y \
    git unzip curl libpng-dev libonig-dev libxml2-dev zip

RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# ✅ ADD THIS (composer)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www