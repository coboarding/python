#!/bin/bash

# Skrypt do diagnostyki API LLM
# Autor: Tom
# Data: 2025-05-13

echo "=== Diagnostyka API LLM ==="
echo "Sprawdzanie procesów Python..."
pgrep -a python || echo "Brak uruchomionych procesów Python!"

echo -e "\nSprawdzanie dostępności API na porcie ${API_PORT:-5000}..."
curl -s http://localhost:${API_PORT:-5000}/api/health || echo "API nie odpowiada na endpoint /api/health!"

echo -e "\nSprawdzanie zależności Pythona..."
pip list | grep -E 'torch|transformers|accelerate|protobuf|bitsandbytes'

echo -e "\nSprawdzanie dostępności modelu..."
if [ -f /app/models/tinyllama/pytorch_model.bin ]; then
  echo "Model TinyLlama istnieje ($(du -h /app/models/tinyllama/pytorch_model.bin | cut -f1))"
else
  echo "BŁĄD: Model TinyLlama nie istnieje!"
fi

echo -e "\nSprawdzanie logów aplikacji..."
tail -n 50 /var/log/api.log 2>/dev/null || echo "Brak pliku logów /var/log/api.log"

echo -e "\nSprawdzanie wykorzystania zasobów..."
free -h
df -h
top -b -n 1 | head -n 20

echo "=== Diagnostyka zakończona ==="
