FROM node:16 as build

WORKDIR /app

# Kopiowanie plików projektu
COPY package.json package-lock.json* ./
RUN npm install

COPY . .
RUN npm run build

# Druga faza - serwer produkcyjny
FROM nginx:alpine

# Kopiowanie zbudowanej aplikacji z poprzedniej fazy
COPY --from=build /app/build /usr/share/nginx/html

# Katalogi na certyfikaty
RUN mkdir -p /etc/nginx/ssl


# Tworzenie samopodpisanego certyfikatu dla rozwoju
RUN apk add --no-cache openssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=PL/ST=State/L=City/O=coboarding/CN=localhost"
# Zmieniono O=AutoFormFiller na O=coboarding

# Kopiowanie konfiguracji Nginx z HTTPS
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]