FROM python:3.9-slim as builder

# Ustawienie zmiennych środowiskowych
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=0 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Instalacja podstawowych zależności systemowych
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Utworzenie katalogu aplikacji
WORKDIR /app

# Kopiowanie tylko pliku requirements.txt, aby wykorzystać cache Docker
COPY requirements.txt .

# Instalacja zależności Pythona z wykorzystaniem cache
RUN pip install --upgrade pip && \
    pip wheel --wheel-dir=/app/wheels -r requirements.txt

# Druga faza - obraz docelowy
FROM python:3.9-slim

# Ustawienie zmiennych środowiskowych
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    USE_INT8=true \
    MODEL_SERVICE_PORT=5000

# Instalacja podstawowych zależności systemowych
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Utworzenie katalogu aplikacji
WORKDIR /app

# Kopiowanie skompilowanych pakietów z poprzedniej fazy
COPY --from=builder /app/wheels /app/wheels
COPY requirements.txt .

# Instalacja pakietów z lokalnych plików wheel
RUN pip install --no-index --find-links=/app/wheels -r requirements.txt && \
    rm -rf /app/wheels

# Tworzenie katalogów dla aplikacji
RUN mkdir -p /app/models/tinyllama

# Kopiowanie kodu aplikacji
COPY model_service.py ./

# Skrypt do pobierania modelu
COPY download_model.sh /app/
RUN chmod +x /app/download_model.sh

# Skrypt healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:${MODEL_SERVICE_PORT}/health || exit 1

# Ekspozycja portu API
EXPOSE ${MODEL_SERVICE_PORT}

# Uruchomienie aplikacji
CMD ["/bin/bash", "-c", "/app/download_model.sh && python -u model_service.py"]
