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

# Ustawienie zmiennych środowiskowych dla pip
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Utworzenie katalogów dla aplikacji
RUN mkdir -p /app/models /app/config /app/model-configs /app/data

# Kopiowanie tylko pliku requirements.txt najpierw, aby lepiej wykorzystać cache
COPY containers/llm-orchestrator-min/requirements.txt .

# Instalacja zależności bez użycia BuildKit
RUN pip install --no-cache-dir -r requirements.txt

# Kopiowanie pozostałych plików aplikacji
COPY containers/llm-orchestrator-min/api.py ./
COPY containers/llm-orchestrator-min/model-configs/ ./model-configs/
COPY containers/llm-orchestrator-min/data/ ./data/

# Pobieranie małego modelu LLM (TinyLlama-1.1B) tylko jeśli nie istnieje
# Używamy wolumenu, aby zachować model między uruchomieniami
ARG MODEL_VERSION=1.0
RUN mkdir -p /app/models/tinyllama

# Skrypt do sprawdzania i pobierania modelu tylko jeśli jest to konieczne
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

# Ekspozycja portu API
EXPOSE 5000

# Uruchomienie API z wcześniejszym sprawdzeniem modelu
CMD ["/bin/bash", "-c", "/app/download_model.sh && python -u api.py"]
