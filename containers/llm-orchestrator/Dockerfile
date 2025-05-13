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
VOLUME /root/.cache/pip
RUN pip install --cache-dir=/root/.cache/pip -r requirements.txt

# Kopiowanie pozostałych plików aplikacji
COPY api.py ./
COPY detect-hardware.py ./
COPY pipeline_generator.py ./
COPY model-configs/ ./model-configs/
COPY data/ ./data/

# Utworzenie potrzebnych katalogów
RUN mkdir -p /app/models /app/config
RUN mkdir -p /app/model-configs /app/data


# Ekspozycja portu API
EXPOSE 5000

# Uruchomienie API
# Uruchom API z logami na stdout i wyjściem błędów
CMD ["python", "-u", "api.py"]