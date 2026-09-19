# LLM Orchestrator Microservices

System do uruchamiania i testowania modeli językowych (LLM) w architekturze mikrousług z wykorzystaniem Docker.

## Funkcjonalności

- **Architektura mikrousług** - model-service i api-gateway
- **Optymalizacja wydajności** - cachowanie pakietów i modeli
- **Łatwe testowanie** - środowisko testowe z noVNC i przeglądarką
- **Monitorowanie** - dashboard Traefik do monitorowania mikrousług
- **Skalowalność** - możliwość uruchomienia wielu instancji model-service

## Wymagania

- MicroK8s (zalecane) lub inny klaster Kubernetes
- kubectl (lub microk8s kubectl)
- Minimum 4GB RAM dla podu modelu LLM
- Dostęp do internetu (do pobierania obrazów i modeli)

## Szybki start

### 1. Instalacja MicroK8s i wymaganych narzędzi

```bash
sudo snap install microk8s --classic
sudo microk8s enable dns storage
```

### 2. Budowa obrazu model-service i import do MicroK8s

```bash
# Buduj obraz Docker lokalnie
cd microservices/model-service
sudo docker build -t llm-model-service:latest .
# Zapisz i zaimportuj do MicroK8s
sudo docker save llm-model-service:latest | sudo microk8s ctr image import -
```

### 3. Uruchomienie usług na Kubernetes

```bash
cd ../../k8s
sudo microk8s kubectl apply -f model-service-deployment.yaml
sudo microk8s kubectl apply -f novnc-deployment.yaml
```

### 4. Testowanie systemu

1. Otwórz przeglądarkę i przejdź do adresu:
   ```
   http://<IP_NODES>:30080
   ```
   (Użyj polecenia `sudo microk8s kubectl get nodes -o wide` aby znaleźć IP)

2. Zaloguj się do noVNC używając hasła:
   ```
   password
   ```

3. W przeglądarce Firefox wewnątrz noVNC, otwórz:
   ```
   file:///config/test_llm.html
   ```

### 5. Monitorowanie systemu

Aby monitorować stan usług i postęp ładowania modelu LLM:

```bash
sudo microk8s kubectl get pods,pvc,svc
```

Możesz sprawdzić logi podów:
```bash
sudo microk8s kubectl logs <nazwa-poda>
```
- `./monitor.sh --live` - monitorowanie w czasie rzeczywistym (aktualizacja co 5 sekund)
- `./monitor.sh --summary` - wyświetlenie tylko podsumowania statusu
- `./monitor.sh --model` - monitorowanie procesu ładowania modelu
- `./monitor.sh --api` - monitorowanie statusu API
- `./monitor.sh --help` - wyświetlenie wszystkich dostępnych opcji

### 4. Zatrzymanie systemu

```bash
./stop.sh
```

## Rozwiązywanie problemów

Jeśli występują problemy z uruchomieniem kontenerów za pomocą `run.sh`, użyj alternatywnego skryptu:

```bash
./reset_and_run.sh
```

Ten skrypt całkowicie resetuje środowisko Docker i uruchamia kontenery ręcznie, co pomaga rozwiązać problemy z kompatybilnością Docker/docker-compose.

### Problem z ładowaniem modelu

Jeśli model-service nie działa lub API zwraca "Service Unavailable", użyj skryptu naprawczego:

```bash
sudo ./fix_model_service.sh
```

Ten skrypt automatycznie pobiera niezbędne pliki modelu i ponownie uruchamia kontener model-service.

## Dokumentacja

Szczegółowa dokumentacja jest dostępna w katalogu `docs`:

- [Testowanie z noVNC](docs/NOVNC_TESTING.md) - instrukcje dotyczące testowania systemu z przeglądarką i noVNC
- [Migracja do mikrousług](docs/MICROSERVICES.md) - informacje o migracji do architektury mikrousług
- [Monitorowanie](docs/MONITORING.md) - instrukcje dotyczące monitorowania systemu

## Struktura projektu

```
llm-orchestrator-min/
├── k8s/
│   ├── model-service-deployment.yaml   # Manifesty Kubernetes dla model-service i cache
│   └── novnc-deployment.yaml           # Manifesty Kubernetes dla noVNC
├── microservices/               # Katalog z mikrousługami
│   ├── api-gateway/             # Brama API (Traefik)
│   └── model-service/           # Usługa modelu LLM
├── models/                      # Katalog na pliki modeli
├── .cache/                      # Katalog cache
│   ├── pip/                     # Cache pakietów pip
│   └── models/                  # Cache pobranych modeli
└── docs/                        # Dokumentacja
```

## Konfiguracja

Główne parametry konfiguracyjne są dostępne w plikach manifestów Kubernetes (`k8s/model-service-deployment.yaml`):

- **MODEL_PATH**: Ścieżka do plików modelu
- **USE_INT8**: Flaga włączająca kwantyzację INT8
- **MODEL_SERVICE_PORT**: Port, na którym nasłuchuje usługa modelu

## Licencja

Ten projekt jest udostępniany na licencji MIT.
