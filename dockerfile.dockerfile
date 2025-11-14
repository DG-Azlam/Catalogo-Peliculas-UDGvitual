# Usar imagen base de PHP con Apache
FROM php:8.2-apache

# Instalar Node.js 22.x (para Angular)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs

# Verificar versión de Node.js 
RUN node --version
RUN npm --version

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libpq-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Habilitar mod_rewrite de Apache
RUN a2enmod rewrite

# Configurar virtual host de Apache
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/www/html/public\n\
    <Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Directorio de trabajo
WORKDIR /var/www/html

# Copiar backend de Laravel
COPY backend/ .

# Instalar dependencias de Laravel
RUN composer install --no-dev --optimize-autoloader

# Cache de Laravel
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

# Construir Angular con Node.js 22
WORKDIR /tmp/frontend
COPY frontend/ .
RUN npm install
RUN npm run build -- --configuration=production

# Mover Angular build al public de Laravel
WORKDIR /var/www/html
RUN cp -r /tmp/frontend/dist/frontend/* public/

# Configurar permisos
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 storage bootstrap/cache

# Puerto expuesto
EXPOSE 80

# Comando de inicio
CMD ["apache2-foreground"]