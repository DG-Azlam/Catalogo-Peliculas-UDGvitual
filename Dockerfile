# Stage 1: Build Angular con versiones específicas
FROM node:22.19-alpine as angular-build

# Instalar versiones específicas
RUN npm install -g @angular/cli@20.3.5 npm@11.6.2

WORKDIR /app/frontend
COPY frontend/ .
RUN npm ci --legacy-peer-deps

# Build Angular con configuración de producción
RUN npx ng build --configuration=production --base-href="/"

# Verificar estructura de build
RUN echo "=== VERIFICANDO ESTRUCTURA ===" && \
    ls -la dist/ && \
    # Asegurar que index.html esté en la ruta correcta
    if [ -f "dist/catalogo_frontend/browser/index.html" ]; then \
        echo "✅ Estructura correcta"; \
    else \
        echo "📁 Buscando index.html..."; \
        FIND_RESULT=$(find dist/ -name "index.html" | head -1) && \
        echo "Encontrado en: $FIND_RESULT" && \
        mkdir -p dist/catalogo_frontend/browser && \
        cp "$FIND_RESULT" dist/catalogo_frontend/browser/ && \
        # Copiar también los demás archivos
        cp -r dist/*/* dist/catalogo_frontend/browser/ 2>/dev/null || true; \
    fi

# Stage 2: Build Laravel
FROM php:8.2-fpm-alpine as laravel-build

WORKDIR /var/www

# Instalar dependencias del sistema
RUN apk add --no-cache \
    nginx \
    git \
    unzip \
    libpng-dev \
    libzip-dev \
    oniguruma-dev \
    postgresql-dev \
    && docker-php-ext-install pdo pdo_pgsql mbstring zip gd

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copiar código de Laravel
COPY backend/ .

# Instalar dependencias de Laravel (evitar symfony/error-handler v7.3.2 si causa problemas)
RUN composer install --no-dev --optimize-autoloader --prefer-dist

# Configurar permisos
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Stage 3: Production
FROM nginx:alpine

# Instalar PHP-FPM
RUN apk add --no-cache php82-fpm php82-pdo php82-pdo_pgsql php82-mbstring php82-zip php82-gd

WORKDIR /var/www

# Copiar Laravel
COPY --from=laravel-build /var/www/ .

# Copiar Angular
COPY --from=angular-build /app/frontend/dist/catalogo_frontend/browser/ /var/www/public/

# Configurar PHP-FPM
RUN echo 'listen = 9000' >> /etc/php82/php-fpm.d/www.conf && \
    echo 'clear_env = no' >> /etc/php82/php-fpm.d/www.conf

# Configurar Nginx
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Script de inicio
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'php-fpm82 -D' >> /start.sh && \
    echo 'nginx -g "daemon off;"' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 10000

CMD ["/start.sh"]
