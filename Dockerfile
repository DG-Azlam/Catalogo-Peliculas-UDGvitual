# ========== DOCKERFILE  ==========
FROM php:8.2-apache

# Instalar Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs

# Dependencias PHP y PostgreSQL
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev \
    zip unzip libpq-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar Apache
RUN a2enmod rewrite
RUN echo '<VirtualHost *:80>\
    DocumentRoot /var/www/html/public\
    <Directory /var/www/html/public>\
        AllowOverride All\
        Require all granted\
    </Directory>\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Configurar Laravel
WORKDIR /var/www/html
COPY backend/ .
RUN composer install --no-dev --optimize-autoloader
RUN php artisan config:cache && php artisan route:cache && php artisan view:cache

# Angular - SOLUCIÓN DEFINITIVA PARA PRERENDERING
COPY frontend/ /tmp/frontend/
WORKDIR /tmp/frontend
RUN npm install

# SOLUCIÓN: Encontrar y configurar las rutas problemáticas
RUN echo "Buscando componentes de rutas con parámetros..."

# Buscar el componente que maneja movies/edit/:id
RUN find . -name "*.ts" -type f -exec grep -l "movies/edit" {} \; | head -1 | while read file; do \
    echo "Archivo de ruta encontrado: \$file"; \
    COMPONENT_DIR=$(dirname "$file"); \
    COMPONENT_FILE=$(find "$COMPONENT_DIR" -name "*.ts" -exec grep -l "@Component" {} \; | head -1); \
    if [ -n "\$COMPONENT_FILE" ]; then \
        echo "Agregando getPrerenderParams a: \$COMPONENT_FILE"; \
        echo "" >> "\$COMPONENT_FILE"; \
        echo "// Función requerida para prerendering" >> "\$COMPONENT_FILE"; \
        echo "export function getPrerenderParams() {" >> "\$COMPONENT_FILE"; \
        echo "  return [" >> "\$COMPONENT_FILE"; \
        echo "    { id: '1' }," >> "\$COMPONENT_FILE"; \
        echo "    { id: '2' }," >> "\$COMPONENT_FILE"; \
        echo "    { id: '3' }," >> "\$COMPONENT_FILE"; \
        echo "    { id: '4' }," >> "\$COMPONENT_FILE"; \
        echo "    { id: '5' }" >> "\$COMPONENT_FILE"; \
        echo "  ];" >> "\$COMPONENT_FILE"; \
        echo "}" >> "\$COMPONENT_FILE"; \
        echo "✅ getPrerenderParams agregado a \$COMPONENT_FILE"; \
    else \
        echo "⚠️ No se encontró componente para: \$file"; \
    fi; \
done

# Buscar el componente que maneja movies/:id (detalles)
RUN find . -name "*.ts" -type f -exec grep -l "movies/[^/]*'" {} \; | head -1 | while read file; do \
    echo "Archivo de detalles encontrado: \$file"; \
    COMPONENT_DIR=$(dirname "$file"); \
    COMPONENT_FILE=$(find "$COMPONENT_DIR" -name "*.ts" -exec grep -l "@Component" {} \; | head -1); \
    if [ -n "\$COMPONENT_FILE" ]; then \
        echo "Verificando getPrerenderParams en: \$COMPONENT_FILE"; \
        if ! grep -q "getPrerenderParams" "\$COMPONENT_FILE"; then \
            echo "Agregando getPrerenderParams a: \$COMPONENT_FILE"; \
            echo "" >> "\$COMPONENT_FILE"; \
            echo "// Función requerida para prerendering" >> "\$COMPONENT_FILE"; \
            echo "export function getPrerenderParams() {" >> "\$COMPONENT_FILE"; \
            echo "  return [" >> "\$COMPONENT_FILE"; \
            echo "    { id: '1' }," >> "\$COMPONENT_FILE"; \
            echo "    { id: '2' }," >> "\$COMPONENT_FILE"; \
            echo "    { id: '3' }," >> "\$COMPONENT_FILE"; \
            echo "    { id: '4' }," >> "\$COMPONENT_FILE"; \
            echo "    { id: '5' }" >> "\$COMPONENT_FILE"; \
            echo "  ];" >> "\$COMPONENT_FILE"; \
            echo "}" >> "\$COMPONENT_FILE"; \
            echo "✅ getPrerenderParams agregado a \$COMPONENT_FILE"; \
        else \
            echo "✅ getPrerenderParams ya existe en \$COMPONENT_FILE"; \
        fi; \
    fi; \
done

# Construir Angular
RUN echo "=== CONSTRUYENDO ANGULAR ==="
RUN npx ng build --configuration=production

# Mover build a Laravel
WORKDIR /var/www/html
RUN cp -r /tmp/frontend/dist/frontend/* public/

# Configurar CORS para Laravel (importante para producción)
RUN echo '<?php\n\
return [\n\
    "paths" => ["api/*", "sanctum/csrf-cookie"],\n\
    "allowed_methods" => ["*"],\n\
    "allowed_origins" => ["*"],\n\
    "allowed_origins_patterns" => [],\n\
    "allowed_headers" => ["*"],\n\
    "exposed_headers" => [],\n\
    "max_age" => 0,\n\
    "supports_credentials" => false,\n\
];' > config/cors.php

# Permisos
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 storage bootstrap/cache

EXPOSE 80

# Comando de inicio con migraciones
CMD sh -c "php artisan migrate --force && apache2-foreground"
