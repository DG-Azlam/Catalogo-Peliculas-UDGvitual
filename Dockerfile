# ========== DOCKERFILE - LARAVEL + ANGULAR ==========
FROM php:8.2-apache

# Instalar Node.js 22 para Angular
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs

# Verificar instalación de Node.js
RUN node --version && npm --version

# Instalar dependencias del sistema para PHP/Laravel
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

# Limpiar cache para reducir tamaño de imagen
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar Apache para Laravel
RUN a2enmod rewrite

# Configurar virtual host
RUN echo '<VirtualHost *:80>\n\
    ServerAdmin webmaster@localhost\n\
    DocumentRoot /var/www/html/public\n\
    \n\
    <Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Require all granted\n\
        Options Indexes FollowSymLinks\n\
    </Directory>\n\
    \n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Directorio de trabajo principal
WORKDIR /var/www/html

# ========== COPIAR Y CONFIGURAR LARAVEL ==========
COPY backend/ .

# Instalar dependencias de Laravel y optimizar
RUN composer install --no-dev --optimize-autoloader

# Cache de Laravel para mejor rendimiento
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

# ========== CONSTRUIR ANGULAR CON FALLBACKS ==========
WORKDIR /tmp/frontend

# Copiar todo el frontend de Angular
COPY frontend/ .

# Instalar dependencias de Angular
RUN npm install

# BUILD CON MÚLTIPLES FALLBACKS
RUN echo "=== INICIANDO BUILD DE ANGULAR ===" && \
    # Intento 1: Build normal con prerendering (tu configuración original)
    (echo "Intento 1: Build con prerendering..." && \
     npx ng build --configuration=production || \
     # Intento 2: Sin prerendering
     (echo "Intento 2: Build sin prerendering..." && \
      npx ng build --configuration=production --prerender=false || \
      # Intento 3: Solo build básico de producción
      (echo "Intento 3: Build básico de producción..." && \
       npx ng build --configuration=production --no-prerender || \
       # Intento 4: Último recurso - forzar build
       (echo "Intento 4: Forzar build de producción..." && \
        npx ng build --prod --aot true --build-optimizer true)))) && \
    echo "=== BUILD DE ANGULAR COMPLETADO ==="

# ========== PREPARAR APLICACIÓN FINAL ==========
WORKDIR /var/www/html

# Copiar build de Angular al directorio público de Laravel
RUN cp -r /tmp/frontend/dist/frontend/* public/

# Configurar permisos para Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 storage bootstrap/cache

# Crear archivo health check
RUN echo "<?php echo 'Application is running'; ?>" > public/health.php

# Exponer puerto
EXPOSE 80

# Comando de inicio
CMD ["apache2-foreground"]
