# Architektura mikrousług dla llm-orchestrator

Ten dokument opisuje propozycję migracji z monolitycznego kontenera Docker do rozproszonej architektury mikrousług zarządzanej przez Terraform i Ansible.

## Problemy obecnej architektury

1. **Długi czas budowania i uruchamiania** - monolityczny kontener zawiera wszystkie komponenty, co wydłuża czas budowy
2. **Trudności w skalowaniu** - nie można niezależnie skalować poszczególnych komponentów
3. **Problemy z zależnościami** - wszystkie zależności muszą być kompatybilne w jednym kontenerze
4. **Utrudniona diagnostyka** - problemy w jednym komponencie wpływają na cały system

## Proponowana architektura mikrousług

Proponujemy podział systemu na następujące mikrousługi:

1. **model-service** - odpowiedzialny tylko za obsługę modelu LLM
2. **api-gateway** - zarządzanie zapytaniami API i routingiem
3. **cache-service** - przechowywanie i zarządzanie cache'em
4. **monitoring-service** - zbieranie metryk i monitorowanie
5. **storage-service** - zarządzanie plikami i danymi

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

## Korzyści z nowej architektury

1. **Szybsze wdrożenia** - można budować i aktualizować usługi niezależnie
2. **Lepsza skalowalność** - możliwość skalowania tylko potrzebnych komponentów
3. **Izolacja błędów** - problemy w jednej usłudze nie wpływają na pozostałe
4. **Elastyczność technologiczna** - możliwość używania różnych technologii dla różnych usług
5. **Łatwiejsze testowanie** - możliwość testowania komponentów niezależnie

## Implementacja z użyciem Terraform i Ansible

### Terraform (zarządzanie infrastrukturą)

Terraform będzie odpowiedzialny za:
- Tworzenie i zarządzanie infrastrukturą (serwery, sieci, load balancery)
- Konfigurację grup bezpieczeństwa i reguł dostępu
- Zarządzanie skalowaniem automatycznym

```hcl
# Przykładowy kod Terraform dla model-service
resource "aws_ecs_service" "model_service" {
  name            = "model-service"
  cluster         = aws_ecs_cluster.llm_cluster.id
  task_definition = aws_ecs_task_definition.model_service.arn
  desired_count   = 2
  
  load_balancer {
    target_group_arn = aws_lb_target_group.model_service.arn
    container_name   = "model-service"
    container_port   = 5000
  }
  
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
}
```

### Ansible (konfiguracja i wdrożenie)

Ansible będzie odpowiedzialny za:
- Konfigurację serwerów i środowiska
- Wdrażanie aplikacji i ich aktualizacje
- Zarządzanie zależnościami i konfiguracją usług

```yaml
# Przykładowy playbook Ansible dla model-service
- name: Deploy model service
  hosts: model_servers
  tasks:
    - name: Pull model service image
      docker_image:
        name: registry.example.com/model-service:latest
        source: pull
        
    - name: Start model service container
      docker_container:
        name: model-service
        image: registry.example.com/model-service:latest
        state: started
        restart_policy: always
        ports:
          - "5000:5000"
        env:
          MODEL_PATH: "/models/tinyllama"
          USE_INT8: "true"
```

## Alternatywy dla Nginx

Zamiast Nginx, proponujemy użycie **Traefik** jako reverse proxy i API gateway:

### Zalety Traefik:
1. **Automatyczna konfiguracja** - wykrywa zmiany w usługach i aktualizuje routing
2. **Integracja z Docker/Kubernetes** - natywna integracja z kontenerami
3. **Let's Encrypt** - automatyczne zarządzanie certyfikatami SSL
4. **Middleware** - łatwe dodawanie funkcji jak rate limiting, autentykacja
5. **Dashboard** - wbudowany panel do monitorowania

```yaml
# Przykładowa konfiguracja Traefik
services:
  traefik:
    image: traefik:v2.5
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      
  model-service:
    image: model-service:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.model.rule=PathPrefix(`/api/model`)"
      - "traefik.http.services.model.loadbalancer.server.port=5000"
```

## Plan migracji

1. **Faza 1**: Podział monolitycznego kontenera na mikrousługi
2. **Faza 2**: Wdrożenie Traefik jako API gateway
3. **Faza 3**: Konfiguracja infrastruktury za pomocą Terraform
4. **Faza 4**: Automatyzacja wdrożeń za pomocą Ansible
5. **Faza 5**: Wdrożenie monitoringu i logowania

## Podsumowanie

Migracja do architektury mikrousług z wykorzystaniem Terraform i Ansible pozwoli na:
- Skrócenie czasu budowania i wdrażania
- Lepszą skalowalność i niezawodność
- Łatwiejsze zarządzanie i diagnostykę
- Elastyczność w wyborze technologii

Traefik jako alternatywa dla Nginx zapewni łatwiejszą konfigurację i lepszą integrację z kontenerami.
