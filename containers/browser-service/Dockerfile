FROM debian:bullseye-slim

# Tymczasowo przekieruj interaktywne dialogi podczas instalacji
ENV DEBIAN_FRONTEND=noninteractive

# Instalacja zależności
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip \
    tigervnc-standalone-server \
    tigervnc-common \
    fluxbox \
    xterm \
    x11-xserver-utils \
    dbus-x11 \
    libglib2.0-0 \
    libnss3 \
    libx11-xcb1 \
    libxtst6 \
    libxss1 \
    libgbm1 \
    libasound2 \
    fonts-noto-color-emoji \
    fonts-noto-core \
    xdg-utils \
    wget \
    curl \
    gnupg \
    supervisor \
    ffmpeg \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Instalacja Chrome (nowy sposób dodania klucza)
RUN set -eux; \
    mkdir -p /etc/apt/keyrings; \
    wget -qO /etc/apt/keyrings/google-linux-signing-key.gpg https://dl.google.com/linux/linux_signing_key.pub; \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-linux-signing-key.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list; \
    apt-get update; \
    apt-get install -y google-chrome-stable; \
    rm -rf /var/lib/apt/lists/*

# Instalacja Firefox
RUN apt-get update && apt-get install -y --no-install-recommends \
    firefox-esr \
    && rm -rf /var/lib/apt/lists/*

# Instalacja ChromeDriver z fallbackiem na najnowszą wersję
RUN set -eux; \
    CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | cut -d '.' -f 1); \
    CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION}" || curl -s https://chromedriver.storage.googleapis.com/LATEST_RELEASE); \
    wget -q "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip"; \
    unzip chromedriver_linux64.zip -d /usr/local/bin; \
    rm chromedriver_linux64.zip; \
    chmod +x /usr/local/bin/chromedriver

# Instalacja GeckoDriver (Firefox)
RUN set -eux; \
    GECKO_DRIVER_VERSION=$(curl -s https://api.github.com/repos/mozilla/geckodriver/releases/latest | grep tag_name | cut -d '"' -f 4); \
    wget -q "https://github.com/mozilla/geckodriver/releases/download/${GECKO_DRIVER_VERSION}/geckodriver-${GECKO_DRIVER_VERSION}-linux64.tar.gz"; \
    tar -xzf "geckodriver-${GECKO_DRIVER_VERSION}-linux64.tar.gz" -C /usr/local/bin; \
    rm "geckodriver-${GECKO_DRIVER_VERSION}-linux64.tar.gz"; \
    chmod +x /usr/local/bin/geckodriver

# Instalacja menedżerów haseł CLI
RUN curl -fsSL https://get.bitwarden.com/sh | bash

# Tworzymy strukturę katalogów
RUN mkdir -p /app/cv /app/config /app/passwords /app/recordings /app/scripts \
    && mkdir -p /opt/scripts \
    && mkdir -p /root/.vnc \
    && mkdir -p /var/log/supervisor

# Kopiowanie skryptów
COPY scripts/ /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

# Kopiowanie plików konfiguracyjnych
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Instalacja zależności Pythona
COPY requirements.txt /app/
RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Konfiguracja TigerVNC
RUN mkdir -p /root/.vnc && \
    echo "#!/bin/sh" > /root/.vnc/xstartup && \
    echo "xrdb $HOME/.Xresources" >> /root/.vnc/xstartup && \
    echo "startfluxbox &" >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Ustawienie zmiennych środowiskowych
ENV DISPLAY=:99
ENV PYTHONUNBUFFERED=1

# Ekspozycja portu VNC
EXPOSE 5900

# Uruchomienie supervisora
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]