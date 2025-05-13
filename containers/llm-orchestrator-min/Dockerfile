FROM python:3.9-slim

# Instalacja zależności systemowych
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kopiowanie tylko pliku requirements.txt najpierw, aby lepiej wykorzystać cache
COPY requirements.txt .

# Ustawienie zmiennych środowiskowych dla pip, aby zoptymalizować cache
ENV PIP_NO_CACHE_DIR=0 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Utworzenie katalogu cache dla pip i instalacja zależności
RUN mkdir -p /root/.cache/pip && \
    pip install -r requirements.txt

# Kopiowanie pozostałych plików aplikacji
COPY api.py ./
COPY model-configs/ ./model-configs/
COPY data/ ./data/

# Utworzenie potrzebnych katalogów
RUN mkdir -p /app/models /app/config
RUN mkdir -p /app/model-configs /app/data

# Pobieranie małego modelu LLM (TinyLlama-1.1B)
# Używamy ARG, aby wymusić przebudowanie tej warstwy przy zmianie wersji modelu
ARG MODEL_VERSION=1.0
RUN mkdir -p /app/models/tinyllama && \
    cd /app/models/tinyllama && \
    wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/tokenizer.model && \
    wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/tokenizer_config.json && \
    wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/config.json && \
    wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/pytorch_model.bin

# Ekspozycja portu API
EXPOSE 5000

# Uruchomienie API
CMD ["python", "-u", "api.py"]
