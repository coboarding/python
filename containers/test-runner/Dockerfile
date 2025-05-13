FROM python:3.9-slim

# Instalacja narzędzi testowych
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    unzip \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalacja Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Utworzenie katalogu aplikacji
WORKDIR /app

# Kopiowanie requirements i instalacja zależności
COPY requirements.txt .
VOLUME /root/.cache/pip
RUN pip install --cache-dir=/root/.cache/pip -r requirements.txt

# (Pominięto kopiowanie testów - katalog nie istnieje w kontekście budowania)

# Ustawienie zmiennych środowiskowych
ENV PYTHONUNBUFFERED=1

# Domyślna komenda
CMD ["python", "/app/tests/run-tests.py"]