#!/bin/bash

# Skrypt do sprawdzania i poprawiania jakości kodu
# Autor: Tom
# Data: 2025-05-13

echo "=== Narzędzia do podnoszenia jakości kodu ==="

# Instalacja narzędzi jeśli nie istnieją
echo "Sprawdzanie i instalacja narzędzi do analizy kodu..."
pip install --no-cache-dir black flake8 pylint mypy isort pytest tox 2>/dev/null

# Formatowanie kodu przy użyciu black
echo -e "\n=== Formatowanie kodu (black) ==="
black --line-length 88 /app/*.py || echo "Wystąpiły błędy podczas formatowania kodu"

# Sortowanie importów
echo -e "\n=== Sortowanie importów (isort) ==="
isort --profile black /app/*.py || echo "Wystąpiły błędy podczas sortowania importów"

# Analiza statyczna kodu
echo -e "\n=== Analiza statyczna kodu (flake8) ==="
flake8 --max-line-length=88 --extend-ignore=E203 /app/*.py || echo "Znaleziono problemy z kodem"

# Analiza typów
echo -e "\n=== Analiza typów (mypy) ==="
mypy --ignore-missing-imports /app/*.py || echo "Znaleziono problemy z typami"

# Pylint
echo -e "\n=== Analiza kodu (pylint) ==="
pylint --disable=C0111,C0103,C0303,W0621,C0301,W0212,W0703,R0913,R0914 /app/*.py || echo "Znaleziono problemy z kodem"

# Raport podsumowujący
echo -e "\n=== Podsumowanie analizy kodu ==="
echo "Sprawdź powyższe wyniki, aby poprawić jakość kodu."
echo "Aby automatycznie naprawić część problemów, uruchom: ./scripts/code_quality.sh --fix"

# Automatyczne naprawianie problemów
if [ "$1" == "--fix" ]; then
  echo -e "\n=== Automatyczne naprawianie problemów ==="
  black --line-length 88 /app/*.py
  isort --profile black /app/*.py
  echo "Podstawowe problemy zostały naprawione."
fi

echo "=== Analiza kodu zakończona ==="
