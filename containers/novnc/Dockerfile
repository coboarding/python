FROM debian:bullseye-slim

# Ustawienie zmiennych środowiskowych dla pip, aby zoptymalizować cache
ENV PIP_NO_CACHE_DIR=0 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_CACHE_DIR=/root/.cache/pip

# Utworzenie katalogów dla cache
RUN mkdir -p /root/.cache/pip /root/.cache/pip/wheels

# Instalacja zależności
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    nginx \
    python3 \
    python3-pip \
    python3-numpy \
    net-tools \
    supervisor \
    procps \
    curl \
    wget \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Klonowanie repozytorium noVNC z określoną wersją dla lepszego cache
RUN git clone --depth 1 --branch v1.3.0 https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone --depth 1 --branch v0.10.0 https://github.com/novnc/websockify /opt/novnc/utils/websockify

# Tworzenie dowiązania symbolicznego do vnc.html
RUN ln -sf /opt/novnc/vnc.html /opt/novnc/index.html

# Kopiowanie konfiguracji Nginx z HTTPS
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Tworzenie samopodpisanego certyfikatu dla HTTPS
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=PL/ST=State/L=City/O=AutoFormFiller/CN=localhost"

# Kopiowanie pliku startowego
COPY start.sh /opt/
RUN chmod +x /opt/start.sh

# Kopiowanie konfiguracji supervisora
COPY supervisord.conf /etc/supervisor/conf.d/

# Ekspozycja portów
EXPOSE 8080 6080

# Uruchomienie supervisora
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]