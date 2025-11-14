# Stage 1: Build Angular
FROM node:22.19-alpine as angular-build

WORKDIR /app/frontend
COPY frontend/ .
RUN npm ci --legacy-peer-deps

# Build Angular
RUN npx ng build --configuration=production --base-href="/"

# FORZAR estructura correcta
RUN echo "=== CORRIGIENDO ESTRUCTURA ===" && \
    # Buscar dónde está realmente index.html
    FIND_RESULT=$(find dist/ -name "index.html" | head -1) && \
    echo "index.html encontrado en: $FIND_RESULT" && \
    # Si no está en browser/, copiarlo allí
    if [ ! -f "dist/catalogo_frontend/browser/index.html" ]; then \
        echo "📁 Moviendo index.html a posición correcta..." && \
        cp "$FIND_RESULT" dist/catalogo_frontend/browser/ && \
        echo "✅ index.html movido"; \
    else \
        echo "✅ index.html ya está en posición correcta"; \
    fi && \
    # Verificar estructura final
    echo "=== ESTRUCTURA CORREGIDA ===" && \
    ls -la dist/catalogo_frontend/browser/

# Stage 2: Servir
FROM nginx:alpine

# Copiar SOLO Angular (sin Laravel temporalmente)
COPY --from=angular-build /app/frontend/dist/catalogo_frontend/browser/ /usr/share/nginx/html/

# Configuración Nginx simple
RUN echo 'server { \
    listen 10000; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { try_files \$uri \$uri/ /index.html; } \
    }' > /etc/nginx/conf.d/default.conf

EXPOSE 10000
CMD ["nginx", "-g", "daemon off;"]
