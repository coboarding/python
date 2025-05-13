# Instalacja

## Wymagania
- Python 3.11+ lub 3.12
- Docker, docker-compose
- Linux (testowane na Ubuntu 24.04/24.10)

## Instalacja krok po kroku

1. Zainstaluj wymagane pakiety systemowe:
   ```bash
   sudo apt-get update && sudo apt-get install python3.11 python3.11-venv python3.11-dev docker docker-compose
   # Lub na Ubuntu 24.10+:
   sudo apt-get install python3.12 python3.12-venv python3.12-dev
   ```
2. Utwórz i aktywuj środowisko virtualenv:
   ```bash
   python3.11 -m venv venv-py311
   source venv-py311/bin/activate
   # lub
   python3.12 -m venv venv-py312
   source venv-py312/bin/activate
   ```
3. Zainstaluj zależności Pythona:
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```
4. Uruchom instalator:
   ```bash
   bash install.sh
   ```

---

## Problemy z uprawnieniami?
Jeśli pojawią się błędy dostępu do plików, uruchom:
```bash
sudo chown -R $(id -u):$(id -g) $(pwd)
chmod -R u+rw $(pwd)
```

---

Przejdź do [Szybki start](quickstart.md) lub [Testy end-to-end](e2e-tests.md).
