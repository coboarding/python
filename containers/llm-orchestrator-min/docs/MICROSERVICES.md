# Architektura mikrousług dla llm-orchestrator-min

Ten dokument opisuje nową architekturę mikrousług dla llm-orchestrator-min, która zastępuje poprzednie monolityczne podejście. Nowa architektura zapewnia lepszą skalowalność, niezawodność i łatwiejsze zarządzanie.

## Spis treści

1. [Przegląd architektury](#przegląd-architektury)
2. [Komponenty](#komponenty)
3. [Szybki start](#szybki-start)
4. [Zarządzanie infrastrukturą](#zarządzanie-infrastrukturą)
5. [Monitorowanie](#monitorowanie)
6. [Rozwiązywanie problemów](#rozwiązywanie-problemów)
7. [Porównanie z architekturą monolityczną](#porównanie-z-architekturą-monolityczną)

## Przegląd architektury

Nowa architektura dzieli funkcjonalność na niezależne mikrousługi, które komunikują się ze sobą przez API. Główne zalety:

- **Niezależne skalowanie** - każda usługa może być skalowana niezależnie od innych
- **Izolacja błędów** - problemy w jednej usłudze nie wpływają na pozostałe
- **Łatwiejsze wdrażanie** - można aktualizować usługi niezależnie
- **Elastyczność technologiczna** - różne usługi mogą używać różnych technologii

### Schemat architektury

```
                   ┌─────────────┐
                   │             │
 ┌─────────────┐   │ API Gateway │   ┌─────────────┐
 │             │   │             │   │             │
 │    Klient   ├───►  (Traefik)  ├───►Model Service│
 │             │   │             │   │             │
 └─────────────┘   └──────┬──────┘   └─────────────┘
                          │
                          │
              ┌───────────┼───────────┐
              │           │           │
      ┌───────▼──┐  ┌─────▼────┐ ┌────▼─────┐
      │          │  │          │ │          │
      │  Cache   │  │ Storage  │ │Monitoring│
      │ Service  │  │ Service  │ │ Service  │
      │          │  │          │ │          │
      └──────────┘  └──────────┘ └──────────┘
```

## Komponenty

### 1. API Gateway (Traefik)

Traefik służy jako brama API i reverse proxy, kierując żądania do odpowiednich mikrousług. Zapewnia:

- Automatyczną konfigurację routingu
- Load balancing
- Obsługę SSL/TLS
- Wbudowany dashboard do monitorowania

### 2. Model Service

Usługa odpowiedzialna za obsługę modelu LLM:

- Ładowanie i zarządzanie modelem
- Generowanie odpowiedzi
- Optymalizacje wydajności (INT8, cache)

### 3. Cache Service (opcjonalnie)

Usługa do przechowywania i zarządzania cache'em:

- Przechowywanie często używanych zapytań
- Redukcja obciążenia Model Service

### 4. Monitoring Service (opcjonalnie)

Usługa do monitorowania i zbierania metryk:

- Prometheus do zbierania metryk
- Grafana do wizualizacji
- Alerty o problemach

## Szybki start

### Wymagania

- Docker
- Docker Compose
- Git

### Uruchomienie

```bash
# Sklonuj repozytorium
git clone https://github.com/coboarding/python.git
cd python/containers/llm-orchestrator-min

# Uruchom skrypt
./run_microservices.sh build
./run_microservices.sh run
```

Po uruchomieniu:
- API będzie dostępne pod adresem: http://localhost/api
- Dashboard Traefik będzie dostępny pod adresem: http://localhost:8080

### Testowanie

```bash
./run_microservices.sh test
```

### Zatrzymanie

```bash
./run_microservices.sh stop
```

## Zarządzanie infrastrukturą

### Terraform

Terraform jest używany do zarządzania infrastrukturą w chmurze:

```bash
cd terraform
terraform init
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"
```

Główne zasoby tworzone przez Terraform:
- VPC i podsieci
- ECS Cluster
- ECR Repositories
- Load Balancer
- EFS dla przechowywania modeli

### Ansible

Ansible jest używany do konfiguracji serwerów i wdrażania aplikacji:

```bash
cd ansible
ansible-playbook -i inventory.yml playbooks/deploy_microservices.yml
```

Playbook Ansible wykonuje:
- Instalację wymaganych pakietów
- Konfigurację Docker
- Wdrożenie mikrousług
- Konfigurację monitoringu

## Monitorowanie

System monitorowania składa się z:

- **Prometheus** - zbieranie metryk
- **Grafana** - wizualizacja metryk
- **Node Exporter** - metryki systemu
- **cAdvisor** - metryki kontenerów

Dostęp do dashboardu Grafana:
- URL: http://localhost:3000
- Login: admin
- Hasło: admin (zmień przy pierwszym logowaniu)

## Rozwiązywanie problemów

### Typowe problemy

1. **API Gateway nie uruchamia się**
   - Sprawdź, czy port 80 nie jest zajęty: `netstat -tuln | grep :80`
   - Zmień port w pliku `.env` lub użyj `export API_PORT=8000` przed uruchomieniem

2. **Model Service zużywa zbyt dużo pamięci**
   - Zmień `USE_INT8=true` w pliku `.env`
   - Zwiększ limit pamięci w `docker-compose.yml`

3. **Problemy z pobieraniem modelu**
   - Sprawdź logi: `./run_microservices.sh logs model-service`
   - Upewnij się, że masz dostęp do internetu

### Diagnostyka

```bash
# Sprawdź status usług
docker-compose ps

# Sprawdź logi konkretnej usługi
./run_microservices.sh logs model-service

# Uruchom diagnostykę API
curl http://localhost/api/health
```

## Porównanie z architekturą monolityczną

| Aspekt | Architektura monolityczna | Architektura mikrousług |
|--------|---------------------------|--------------------------|
| **Złożoność** | Niska | Wyższa |
| **Skalowalność** | Ograniczona | Wysoka |
| **Odporność na błędy** | Niska | Wysoka |
| **Czas wdrożenia** | Krótszy | Dłuższy początkowo, szybszy później |
| **Zużycie zasobów** | Niższe | Wyższe (overhead) |
| **Łatwość rozwoju** | Prosta na początku, trudniejsza z czasem | Trudniejsza na początku, łatwiejsza z czasem |
| **Czas budowania** | Dłuższy | Krótszy (równoległe budowanie) |

### Kiedy używać mikrousług?

Mikrousługi są zalecane, gdy:
- System wymaga niezależnego skalowania komponentów
- Zespół jest rozproszony i pracuje nad różnymi częściami systemu
- Wymagana jest wysoka dostępność i odporność na błędy
- System jest złożony i będzie rozwijany przez dłuższy czas

### Kiedy używać monolitu?

Monolit jest zalecany, gdy:
- System jest prosty i nie wymaga skalowalności
- Zespół jest mały i pracuje nad całym systemem
- Szybkość wdrożenia jest priorytetem
- Zasoby infrastruktury są ograniczone
