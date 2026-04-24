FROM php:8.4-fpm

# system deps
RUN apt-get update && apt-get install -y \
    git unzip curl libpng-dev libonig-dev libxml2-dev zip \
    nodejs npm

# php extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# copy app
COPY app/ /var/www

# install backend deps
RUN composer install --no-interaction --optimize-autoloader

# install frontend deps + build
RUN npm install && npm run build

# permissions
RUN mkdir -p storage/framework/{cache,sessions,views} storage/logs \
    && chmod -R 777 storage bootstrap/cache