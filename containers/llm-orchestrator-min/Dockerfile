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
    API_PORT=5000

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
RUN mkdir -p /app/models/tinyllama /app/scripts

# Kopiowanie kodu aplikacji
COPY api.py ./

# Skrypt do pobierania modelu
RUN echo '#!/bin/bash \n\
if [ ! -f /app/models/tinyllama/pytorch_model.bin ]; then \n\
  echo "Pobieranie modelu TinyLlama..." \n\
  cd /app/models/tinyllama && \
  wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/tokenizer.model && \
  wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/tokenizer_config.json && \
  wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/config.json && \
  wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/pytorch_model.bin \n\
  echo "Model pobrany pomyślnie." \n\
else \n\
  echo "Model TinyLlama już istnieje, pomijanie pobierania." \n\
fi' > /app/download_model.sh && chmod +x /app/download_model.sh

# Kopiowanie skryptów (pojedynczo, aby uniknąć problemów z nieistniejącymi plikami)
COPY scripts/*.sh /app/scripts/
COPY scripts/*.py /app/scripts/

# Nadanie uprawnień wykonywania dla skryptów
RUN find /app/scripts -name "*.sh" -exec chmod +x {} \;

# Skrypt healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:${API_PORT}/api/health || exit 1

# Ekspozycja portu API
EXPOSE ${API_PORT}

# Uruchomienie aplikacji
CMD ["/bin/bash", "-c", "/app/download_model.sh && python -u api.py"]
