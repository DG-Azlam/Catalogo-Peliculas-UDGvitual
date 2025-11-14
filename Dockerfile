# Stage 1: Build Angular frontend
FROM node:22.19-alpine as angular-build

WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci --legacy-peer-deps
COPY frontend/ .

# Build Angular
RUN npx ng build --configuration=production --base-href="/"

# DEBUG: Ver qué se generó
RUN echo "=== ESTRUCTURA DEL BUILD ===" && \
    find dist/catalogo_frontend/browser/ -type f -name "*.html" | head -10 && \
    echo "=== ARCHIVOS EN BROWSER/ ===" && \
    ls -la dist/catalogo_frontend/browser/

# Stage 2: Laravel + Angular
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y nginx
WORKDIR /var/www
COPY backend/ .

# Copiar Angular al public de Laravel
COPY --from=angular-build /app/frontend/dist/catalogo_frontend/browser/ /var/www/public/

# VERIFICAR que todo esté correcto
RUN echo "=== ESTRUCTURA FINAL ===" && \
    ls -la /var/www/public/ && \
    echo "=== ¿index.html EN RAÍZ? ===" && \
    test -f /var/www/public/index.html && echo "✅ index.html EN RAÍZ" || echo "❌ index.html NO ENCONTRADO"

COPY docker/nginx.conf /etc/nginx/sites-available/default
EXPOSE 10000

CMD sh -c "nginx -g 'daemon off;' & php-fpm"
