FROM nginx:1.27-alpine

# REQUIRED: USER_ID and GROUP_ID must be provided via build args
ARG USER_ID
ARG GROUP_ID

# Weg mit unklarem Default-User, wir wollen Kontrolle
RUN deluser nginx 2>/dev/null || true \
    && addgroup -g ${GROUP_ID} -S nginx \
    && adduser  -u ${USER_ID} -S -D -H -G nginx nginx

# Eigene Konfiguration
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d /etc/nginx/conf.d

# Runtime-Verzeichnisse vorbereiten
RUN mkdir -p /var/cache/nginx /var/run \
    && chown -R nginx:nginx \
       /var/cache/nginx \
       /var/run \
       /etc/nginx

USER nginx

EXPOSE 8080
