#!/bin/bash

# Skrypt do naprawy typowych problemów z API LLM
# Autor: Tom
# Data: 2025-05-13

echo "=== Naprawa typowych problemów API LLM ==="

# Sprawdzenie i naprawienie brakujących zależności
echo "Sprawdzanie i instalacja brakujących zależności..."
pip install --no-cache-dir torch==2.0.1 transformers==4.30.2 accelerate==0.20.3 protobuf==3.20.3 bitsandbytes==0.40.2 2>/dev/null

# Sprawdzenie i pobranie modelu jeśli brakuje
if [ ! -f /app/models/tinyllama/pytorch_model.bin ]; then
  echo "Model TinyLlama nie istnieje, pobieram..."
  mkdir -p /app/models/tinyllama
  cd /app/models/tinyllama
  wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/tokenizer.model
  wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/tokenizer_config.json
  wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/config.json
  wget -q https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/pytorch_model.bin
  echo "Model pobrany pomyślnie."
else
  echo "Model TinyLlama istnieje, pomijam pobieranie."
fi

# Sprawdzenie i restart API
echo "Sprawdzanie czy API działa..."
if ! curl -s http://localhost:${API_PORT:-5000}/api/health > /dev/null; then
  echo "API nie odpowiada, restartuję..."
  pkill -f "python -u api.py" || true
  nohup python -u api.py > /var/log/api.log 2>&1 &
  echo "API zrestartowane, czekam 10 sekund na uruchomienie..."
  sleep 10
  if curl -s http://localhost:${API_PORT:-5000}/api/health > /dev/null; then
    echo "API działa poprawnie!"
  else
    echo "BŁĄD: API nadal nie odpowiada po restarcie."
  fi
else
  echo "API działa poprawnie!"
fi

# Czyszczenie cache Pythona
echo "Czyszczenie niepotrzebnych plików cache..."
find /root/.cache -type f -name "*.json" -delete
find /tmp -type f -name "*.py[co]" -delete 2>/dev/null || true

echo "=== Naprawa zakończona ==="
