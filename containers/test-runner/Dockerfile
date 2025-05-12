# test-runner/Dockerfile
FROM python:3.9-slim

# Instalacja narzędzi testowych
RUN pip install --no-cache-dir pytest requests beautifulsoup4 selenium webdriver-manager

# Kopiowanie skryptów testowych
COPY tests/ /app/tests/

WORKDIR /app

# Ustawienie zmiennych środowiskowych
ENV PYTHONUNBUFFERED=1

# Domyślna komenda
CMD ["python", "/app/tests/run-tests.py"]