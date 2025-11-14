# ========== DOCKERFILE ==========
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

# Limpiar cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar Apache
RUN a2enmod rewrite
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/www/html/public\n\
    <Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Directorio de trabajo
WORKDIR /var/www/html

# ========== CONFIGURAR LARAVEL ==========
COPY backend/ .
RUN composer install --no-dev --optimize-autoloader
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

# ========== SOLUCIÓN DEFINITIVA PARA ANGULAR ==========
WORKDIR /tmp/frontend
COPY frontend/ .
RUN npm install

# SOLUCIÓN: Deshabilitar SSR/Prerendering completamente
RUN echo "=== DESHABILITANDO PRERENDERING EN CONFIGURACIÓN ==="

# Método 1: Modificar angular.json temporalmente para deshabilitar prerendering
RUN node -e "\
const fs = require('fs');\
const path = require('path');\
\
// Leer angular.json\
const angularJsonPath = path.join(process.cwd(), 'angular.json');\
let angularJson = JSON.parse(fs.readFileSync(angularJsonPath, 'utf8'));\
\
// Función para deshabilitar prerendering en todas las configuraciones\
function disablePrerendering(config) {\
    if (config.configurations && config.configurations.production) {\
        config.configurations.production.prerender = false;\
        delete config.configurations.production.ssr;\
        delete config.configurations.production.prerender;\\
    }\
    if (config.options) {\
        delete config.options.prerender;\
        delete config.options.ssr;\
    }\
}\
\
// Aplicar a build configuration\
if (angularJson.projects?.frontend?.architect?.build) {\
    disablePrerendering(angularJson.projects.frontend.architect.build);\
}\
\
// Eliminar configuraciones de server y prerender si existen\
if (angularJson.projects?.frontend?.architect?.server) {\
    delete angularJson.projects.frontend.architect.server;\
}\\
if (angularJson.projects?.frontend?.architect?.prerender) {\
    delete angularJson.projects.frontend.architect.prerender;\
}\
\
// Guardar cambios\
fs.writeFileSync(angularJsonPath, JSON.stringify(angularJson, null, 2));\
console.log('✅ Prerendering deshabilitado en angular.json');\
"

# Método 2: También modificar package.json scripts si es necesario
RUN node -e "\
const fs = require('fs');\
const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));\
\
// Reemplazar scripts de build para evitar prerendering\
if (packageJson.scripts) {\
    if (packageJson.scripts.build) {\
        packageJson.scripts.build = packageJson.scripts.build.replace(/--prerender/g, '');\
    }\
    if (packageJson.scripts['build:prod']) {\
        packageJson.scripts['build:prod'] = 'ng build --configuration=production';\
    }\
}\
\
fs.writeFileSync('package.json', JSON.stringify(packageJson, null, 2));\
console.log('✅ Scripts de build actualizados');\
"

# Ahora construir Angular SIN prerendering
RUN echo "=== CONSTRUYENDO ANGULAR ==="
RUN npx ng build --configuration=production

# Verificar que el build se creó correctamente
RUN ls -la dist/ && echo "✅ Build de Angular completado"

# ========== PREPARAR APLICACIÓN FINAL ==========
WORKDIR /var/www/html

# Copiar build de Angular al public de Laravel
RUN cp -r /tmp/frontend/dist/frontend/* public/

# Configurar permisos
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 storage bootstrap/cache

# Exponer puerto
EXPOSE 80

# Comando de inicio
CMD ["apache2-foreground"]
