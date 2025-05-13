FROM python:3.9-slim

# Instalacja zależności systemowych
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libasound2-dev \
    libportaudio2 \
    portaudio19-dev \
    libpulse-dev \
    ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kopiowanie plików wymagań
COPY requirements.txt .

# Instalacja zależności Python
VOLUME /root/.cache/pip
RUN pip install --cache-dir=/root/.cache/pip -r requirements.txt

# Kopiowanie plików źródłowych
COPY . .

# Tworzenie katalogu na nagrania audio
RUN mkdir -p /app/audio

# Ekspozycja portu
EXPOSE 6000

# Uruchomienie aplikacji
CMD ["python", "app.py"]