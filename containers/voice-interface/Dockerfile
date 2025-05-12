FROM python:3.9-slim

# Instalacja zależności do obsługi audio i SpeechRecognition
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libasound2-dev \
    libportaudio2 \
    portaudio19-dev \
    libpulse-dev \
    espeak \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kopiowanie plików
COPY requirements.txt .
COPY app.py .

# Instalacja zależności Pythona
RUN pip install --no-cache-dir -r requirements.txt

# Udostępnienie portu
EXPOSE 6000

# Uruchomienie aplikacji
CMD ["python", "app.py"]