#!/bin/bash
# Skrypt do pobierania modelu TinyLlama

MODEL_DIR="${1:-/app/models/tinyllama}"
CACHE_DIR="${2:-/app/.cache/models/tinyllama}"

# Tworzenie katalogów
mkdir -p "${MODEL_DIR}"
mkdir -p "${CACHE_DIR}"

# Funkcja do pobierania pliku, jeśli nie istnieje w cache
download_if_not_exists() {
    local filename=$1
    local url=$2
    local target_dir=$3
    local cache_dir=$4
    
    # Sprawdzenie, czy plik istnieje w cache
    if [ -f "${cache_dir}/${filename}" ]; then
        echo "Używam ${filename} z cache..."
        cp "${cache_dir}/${filename}" "${target_dir}/${filename}"
    else
        echo "Pobieram ${filename}..."
        wget -q "${url}/${filename}" -O "${target_dir}/${filename}"
        # Kopiowanie do cache
        cp "${target_dir}/${filename}" "${cache_dir}/${filename}"
    fi
}

# Pobieranie plików modelu
MODEL_URL="https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main"
FILES=("tokenizer.model" "tokenizer_config.json" "config.json" "pytorch_model.bin")

for file in "${FILES[@]}"; do
    download_if_not_exists "${file}" "${MODEL_URL}" "${MODEL_DIR}" "${CACHE_DIR}"
done

echo "Model pobrany pomyślnie."
