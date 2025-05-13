FROM node:16-bullseye-slim

# Instalacja zależności
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    python3 \
    python3-pip \
    build-essential \
    libasound2-dev \
    libpulse-dev \
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kopiowanie package.json
COPY package.json package-lock.json* ./
RUN npm install

# Instalacja zależności Python dla integracji z TTS/STT
COPY requirements.txt ./
VOLUME /root/.cache/pip
VOLUME /root/.cache/pip
RUN pip install --cache-dir=/root/.cache/pip -r requirements.txt

# Kopiowanie kodu źródłowego
COPY . .

# Generowanie certyfikatów SSL
RUN mkdir -p ./certs
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ./certs/key.pem -out ./certs/cert.pem \
    -subj "/C=PL/ST=State/L=City/O=AutoFormFiller/CN=localhost"

# Budowa aplikacji
RUN npm run build

RUN ls -l /app/src

# Ekspozycja portu HTTPS
EXPOSE 443

# Uruchomienie serwera
CMD ["npm", "start"]