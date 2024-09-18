# Base Image
FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    locales \
    zip \
    vim \
    unzip \
    git \
    curl \
    libzip-dev \
    libonig-dev \
    supervisor \
    libpq-dev \
    && docker-php-ext-configure zip \
    && docker-php-ext-install pdo mbstring zip exif pcntl pdo_pgsql pgsql \
    && docker-php-ext-enable pdo_pgsql pgsql

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy existing application directory contents
COPY . /var/www

# Change permissions for Laravel storage and cache
RUN chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/storage \
    && chmod -R 775 /var/www/bootstrap/cache

# Install Laravel dependencies
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Copy Nginx configuration
COPY ./docker/nginx/nginx.conf /etc/nginx/nginx.conf

# Supervisor configuration (for running Nginx and PHP-FPM simultaneously)
COPY ./docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port 80 for Nginx
EXPOSE 80

# Start Supervisor to run Nginx and PHP-FPM together
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
