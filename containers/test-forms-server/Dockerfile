FROM nginx:alpine

# Kopiowanie formularzy testowych
COPY forms/ /usr/share/nginx/html/forms/

# Kopiowanie konfiguracji Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Ekspozycja portu
EXPOSE 80