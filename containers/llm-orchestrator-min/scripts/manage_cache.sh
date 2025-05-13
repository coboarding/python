#!/bin/bash

# Skrypt do zarządzania cache Docker i pakietów Pythona
# Autor: Tom
# Data: 2025-05-13

set -e

echo "=== Zarządzanie cache Docker i pakietów Pythona ==="

# Funkcja do wyświetlania rozmiaru
format_size() {
  local size=$1
  if [ $size -ge 1073741824 ]; then
    echo "$(awk "BEGIN {printf \"%.2f\", $size/1073741824}") GB"
  elif [ $size -ge 1048576 ]; then
    echo "$(awk "BEGIN {printf \"%.2f\", $size/1048576}") MB"
  elif [ $size -ge 1024 ]; then
    echo "$(awk "BEGIN {printf \"%.2f\", $size/1024}") KB"
  else
    echo "$size bajtów"
  fi
}

# Sprawdzenie wolumenów Docker
echo "Sprawdzanie wolumenów Docker..."
docker volume ls | grep -E 'pip-cache|wheel-cache|models-cache' || echo "Brak wolumenów cache"

# Utworzenie wolumenów cache jeśli nie istnieją
echo "Tworzenie wolumenów cache jeśli nie istnieją..."
docker volume create coboarding-pip-cache 2>/dev/null || true
docker volume create coboarding-wheel-cache 2>/dev/null || true
docker volume create coboarding-models-cache 2>/dev/null || true

# Sprawdzenie rozmiaru obrazów Docker
echo -e "\nSprawdzanie rozmiaru obrazów Docker..."
docker images --format "{{.Repository}}:{{.Tag}} - {{.Size}}" | grep -E 'llm-orchestrator|coboarding'

# Sprawdzenie cache pip
echo -e "\nSprawdzanie cache pip..."
PIP_CACHE_SIZE=$(du -sb ~/.cache/pip 2>/dev/null | cut -f1 || echo 0)
echo "Rozmiar lokalnego cache pip: $(format_size $PIP_CACHE_SIZE)"

# Funkcja do budowania obrazu z wykorzystaniem cache
build_with_cache() {
  echo -e "\nBudowanie obrazu z wykorzystaniem cache wolumenów..."
  docker build \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from llm-orchestrator-min:latest \
    --tag llm-orchestrator-min:latest \
    --file containers/llm-orchestrator-min/Dockerfile \
    --volume coboarding-pip-cache:/root/.cache/pip \
    --volume coboarding-wheel-cache:/app/wheels \
    .
}

# Funkcja do czyszczenia nieużywanych obrazów i kontenerów
clean_docker() {
  echo -e "\nCzyszczenie nieużywanych obrazów i kontenerów..."
  docker container prune -f
  docker image prune -f
  echo "Czyszczenie zakończone."
}

# Funkcja do zapisywania i wczytywania obrazów Docker
save_docker_image() {
  echo -e "\nZapisywanie obrazu Docker do pliku..."
  mkdir -p ./docker-images
  docker save llm-orchestrator-min:latest | gzip > ./docker-images/llm-orchestrator-min-latest.tar.gz
  echo "Obraz zapisany do ./docker-images/llm-orchestrator-min-latest.tar.gz"
}

load_docker_image() {
  echo -e "\nWczytywanie obrazu Docker z pliku..."
  if [ -f ./docker-images/llm-orchestrator-min-latest.tar.gz ]; then
    docker load < ./docker-images/llm-orchestrator-min-latest.tar.gz
    echo "Obraz wczytany pomyślnie."
  else
    echo "Plik obrazu nie istnieje!"
  fi
}

# Obsługa argumentów
case "$1" in
  build)
    build_with_cache
    ;;
  clean)
    clean_docker
    ;;
  save)
    save_docker_image
    ;;
  load)
    load_docker_image
    ;;
  status)
    # Już wyświetliliśmy status na początku
    ;;
  *)
    echo -e "\nUżycie: $0 {build|clean|save|load|status}"
    echo "  build  - Buduje obraz Docker z wykorzystaniem cache"
    echo "  clean  - Czyści nieużywane obrazy i kontenery"
    echo "  save   - Zapisuje obraz Docker do pliku"
    echo "  load   - Wczytuje obraz Docker z pliku"
    echo "  status - Wyświetla status cache i obrazów"
    ;;
esac

echo -e "\n=== Zarządzanie cache zakończone ==="
