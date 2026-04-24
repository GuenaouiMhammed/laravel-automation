FROM php:8.4-fpm

RUN apt-get update && apt-get install -y \
    git unzip curl libpng-dev libonig-dev libxml2-dev zip \
    nodejs npm

RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

COPY app/ /var/www

# backend deps
RUN composer install --no-interaction --optimize-autoloader

# 🔥 THIS IS THE IMPORTANT PART
RUN npm install && npm run build

# create storage structure + fix perms
RUN mkdir -p storage/framework/{cache,sessions,views} storage/logs \
    && chown -R www-data:www-data /var/www \
    && chmod -R 775 storage bootstrap/cache

USER www-data