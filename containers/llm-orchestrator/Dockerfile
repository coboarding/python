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

# Kopiowanie plików requirements i instalacja zależności
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Kopiowanie pozostałych plików aplikacji
COPY api.py .
COPY detect-hardware.py .
COPY pipeline_generator.py .
COPY model-configs/ ./model-configs/
COPY data/ ./data/

# Utworzenie potrzebnych katalogów
RUN mkdir -p /app/models /app/config

# Ekspozycja portu API
EXPOSE 5000

# Uruchomienie API
CMD ["python", "api.py"]