#!/bin/bash
# Skrypt do pobierania modelu TinyLlama

MODEL_DIR="/app/models/tinyllama"
MODEL_URL_BASE="https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main"
MODEL_FILES=(
  "tokenizer.model"
  "tokenizer_config.json"
  "config.json"
  "pytorch_model.bin"
)

# Tworzenie katalogu dla modelu
mkdir -p $MODEL_DIR

# Sprawdzenie, czy model już istnieje
if [ ! -f "$MODEL_DIR/pytorch_model.bin" ]; then
  echo "Pobieranie modelu TinyLlama..."
  
  # Pobieranie plików modelu
  for file in "${MODEL_FILES[@]}"; do
    echo "Pobieranie $file..."
    wget -q "$MODEL_URL_BASE/$file" -O "$MODEL_DIR/$file"
    
    # Sprawdzenie, czy pobieranie się powiodło
    if [ $? -ne 0 ]; then
      echo "Błąd podczas pobierania $file!"
      exit 1
    fi
  done
  
  echo "Model pobrany pomyślnie."
else
  echo "Model TinyLlama już istnieje, pomijanie pobierania."
fi
