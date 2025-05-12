FROM debian:bullseye-slim

# Instalacja niezbędnych pakietów
RUN apt-get update && apt-get install -y \
    firefox-esr chromium xvfb x11vnc \
    python3 python3-pip supervisor ffmpeg \
    curl wget gnupg2 xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Instalacja menedżerów haseł CLI
RUN curl -fsSL https://pkg.bitwarden.com/config.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/bitwarden.gpg \
    && curl -fsSL https://pkg.bitwarden.com/stable.list > /etc/apt/sources.list.d/bitwarden.list \
    && apt-get update && apt-get install -y bitwarden-cli

# Instalacja Selenium i innych zależności Pythona
RUN pip3 install selenium webdriver-manager requests beautifulsoup4 langchain transformers

# Ustawienie zmiennych środowiskowych
ENV DISPLAY=:99
ENV RESOLUTION=1920x1080x24

# Kopiowanie skryptów
COPY scripts/ /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

# Konfiguracja Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Ekspozycja portu VNC
EXPOSE 5900

# Uruchomienie Supervisor (Xvfb, VNC, Python)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]