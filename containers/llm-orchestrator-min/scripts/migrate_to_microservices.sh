#!/bin/bash
# Skrypt do migracji z monolitycznej architektury do mikrousług

# Kolory do logów
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funkcja do wyświetlania komunikatów
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Katalog projektu
PROJECT_DIR=$(pwd)
MONOLITH_DIR="${PROJECT_DIR}"
MICROSERVICES_DIR="${PROJECT_DIR}/microservices"
CACHE_DIR="${PROJECT_DIR}/.cache"

# Funkcja do sprawdzania wymagań
check_requirements() {
    log_info "Sprawdzanie wymagań..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker nie jest zainstalowany."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_warn "Docker Compose nie jest zainstalowany."
        exit 1
    fi
    
    log_info "Wszystkie wymagania spełnione."
}

# Funkcja do tworzenia struktury katalogów
create_directory_structure() {
    log_info "Tworzenie struktury katalogów dla mikrousług..."
    
    mkdir -p "${MICROSERVICES_DIR}/model-service"
    mkdir -p "${MICROSERVICES_DIR}/api-gateway"
    mkdir -p "${MICROSERVICES_DIR}/model-service/scripts"
    mkdir -p "${CACHE_DIR}/pip"
    mkdir -p "${CACHE_DIR}/models"
    
    log_info "Struktura katalogów utworzona."
}

# Funkcja do kopiowania plików
copy_files() {
    log_info "Kopiowanie plików do nowej struktury..."
    
    # Kopiowanie plików dla model-service
    cp "${MONOLITH_DIR}/api.py" "${MICROSERVICES_DIR}/model-service/model_service.py"
    cp "${MONOLITH_DIR}/requirements.txt" "${MICROSERVICES_DIR}/model-service/"
    
    # Kopiowanie skryptów
    cp "${MONOLITH_DIR}/scripts/run_tests_after_startup.sh" "${MICROSERVICES_DIR}/model-service/scripts/"
    cp "${MONOLITH_DIR}/scripts/comprehensive_test.py" "${MICROSERVICES_DIR}/model-service/scripts/"
    
    log_info "Pliki skopiowane."
}

# Funkcja do cachowania pakietów Pythona
setup_package_caching() {
    log_info "Konfigurowanie cachowania pakietów Pythona..."
    
    # Tworzenie katalogu dla cache
    mkdir -p "${CACHE_DIR}/pip"
    mkdir -p "${CACHE_DIR}/models/tinyllama"
    
    # Tworzenie pliku .dockerignore
    cat > "${PROJECT_DIR}/.dockerignore" << EOF
**/.git
**/.gitignore
**/.vscode
**/__pycache__
**/*.pyc
**/*.pyo
**/*.pyd
**/.Python
**/env
**/venv
**/.env
**/.venv
**/.idea
**/.coverage
**/.pytest_cache
**/.tox
**/.eggs
**/*.egg-info
**/*.egg
!.cache/pip
!.cache/models
EOF
    
    # Tworzenie skryptu do pobierania modelu
    cat > "${MICROSERVICES_DIR}/model-service/download_model.sh" << EOF
#!/bin/bash
# Skrypt do pobierania modelu TinyLlama

MODEL_DIR="\${1:-/app/models/tinyllama}"
CACHE_DIR="\${2:-/app/.cache/models/tinyllama}"

# Tworzenie katalogów
mkdir -p "\${MODEL_DIR}"
mkdir -p "\${CACHE_DIR}"

# Funkcja do pobierania pliku, jeśli nie istnieje w cache
download_if_not_exists() {
    local filename=\$1
    local url=\$2
    local target_dir=\$3
    local cache_dir=\$4
    
    # Sprawdzenie, czy plik istnieje w cache
    if [ -f "\${cache_dir}/\${filename}" ]; then
        echo "Używam \${filename} z cache..."
        cp "\${cache_dir}/\${filename}" "\${target_dir}/\${filename}"
    else
        echo "Pobieram \${filename}..."
        wget -q "\${url}/\${filename}" -O "\${target_dir}/\${filename}"
        # Kopiowanie do cache
        cp "\${target_dir}/\${filename}" "\${cache_dir}/\${filename}"
    fi
}

# Pobieranie plików modelu
MODEL_URL="https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main"
FILES=("tokenizer.model" "tokenizer_config.json" "config.json" "pytorch_model.bin")

for file in "\${FILES[@]}"; do
    download_if_not_exists "\${file}" "\${MODEL_URL}" "\${MODEL_DIR}" "\${CACHE_DIR}"
done

echo "Model pobrany pomyślnie."
EOF
    
    chmod +x "${MICROSERVICES_DIR}/model-service/download_model.sh"
    
    log_info "Cachowanie pakietów skonfigurowane."
}

# Funkcja do tworzenia plików Docker
create_docker_files() {
    log_info "Tworzenie plików Docker dla mikrousług..."
    
    # Tworzenie Dockerfile dla model-service
    cat > "${MICROSERVICES_DIR}/model-service/Dockerfile" << EOF
FROM python:3.9-slim as builder

# Ustawienie zmiennych środowiskowych
ENV PYTHONDONTWRITEBYTECODE=1 \\
    PYTHONUNBUFFERED=1 \\
    PIP_NO_CACHE_DIR=0 \\
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Instalacja podstawowych zależności systemowych
RUN apt-get update && apt-get install -y --no-install-recommends \\
    build-essential \\
    && rm -rf /var/lib/apt/lists/*

# Utworzenie katalogu aplikacji
WORKDIR /app

# Kopiowanie tylko pliku requirements.txt, aby wykorzystać cache Docker
COPY requirements.txt .

# Instalacja zależności Pythona z wykorzystaniem cache
RUN pip install --upgrade pip && \\
    pip wheel --wheel-dir=/app/wheels -r requirements.txt

# Druga faza - obraz docelowy
FROM python:3.9-slim

# Ustawienie zmiennych środowiskowych
ENV PYTHONDONTWRITEBYTECODE=1 \\
    PYTHONUNBUFFERED=1 \\
    USE_INT8=true \\
    MODEL_SERVICE_PORT=5000

# Instalacja podstawowych zależności systemowych
RUN apt-get update && apt-get install -y --no-install-recommends \\
    wget \\
    curl \\
    && rm -rf /var/lib/apt/lists/*

# Utworzenie katalogu aplikacji
WORKDIR /app

# Kopiowanie skompilowanych pakietów z poprzedniej fazy
COPY --from=builder /app/wheels /app/wheels
COPY requirements.txt .

# Instalacja pakietów z lokalnych plików wheel
RUN pip install --no-index --find-links=/app/wheels -r requirements.txt && \\
    rm -rf /app/wheels

# Tworzenie katalogów dla aplikacji
RUN mkdir -p /app/models/tinyllama /app/.cache/models/tinyllama

# Kopiowanie kodu aplikacji
COPY model_service.py ./
COPY download_model.sh ./

# Kopiowanie skryptów
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh /app/download_model.sh

# Skrypt healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \\
  CMD curl -f http://localhost:\${MODEL_SERVICE_PORT}/health || exit 1

# Ekspozycja portu API
EXPOSE \${MODEL_SERVICE_PORT}

# Uruchomienie aplikacji
CMD ["/bin/bash", "-c", "./download_model.sh /app/models/tinyllama /app/.cache/models/tinyllama && python -u model_service.py"]
EOF
    
    # Tworzenie Dockerfile dla api-gateway
    cat > "${MICROSERVICES_DIR}/api-gateway/Dockerfile" << EOF
FROM traefik:v2.9

# Kopiowanie konfiguracji
COPY traefik.yml /etc/traefik/traefik.yml
COPY dynamic_conf.yml /etc/traefik/dynamic_conf.yml

# Ekspozycja portów
EXPOSE 80
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \\
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ping || exit 1

# Uruchomienie Traefik
ENTRYPOINT ["traefik"]
EOF
    
    log_info "Pliki Docker utworzone."
}

# Funkcja do tworzenia konfiguracji Traefik
create_traefik_config() {
    log_info "Tworzenie konfiguracji Traefik dla API Gateway..."
    
    # Tworzenie głównego pliku konfiguracyjnego traefik.yml
    cat > "${MICROSERVICES_DIR}/api-gateway/traefik.yml" << EOF
# Konfiguracja Traefik dla API Gateway
global:
  checkNewVersion: true
  sendAnonymousUsage: false

api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
  traefik:
    address: ":8080"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    filename: /etc/traefik/dynamic_conf.yml
    watch: true

accessLog: {}
EOF

    # Tworzenie pliku konfiguracyjnego dynamic_conf.yml
    cat > "${MICROSERVICES_DIR}/api-gateway/dynamic_conf.yml" << EOF
http:
  routers:
    model-router:
      rule: "PathPrefix(\`/api\`)"
      service: model-service
      entryPoints:
        - web

  services:
    model-service:
      loadBalancer:
        servers:
          - url: "http://model-service:5000"
        healthCheck:
          path: /health
          interval: "10s"
          timeout: "3s"
EOF

    log_info "Konfiguracja Traefik utworzona."
}

# Funkcja do tworzenia pliku docker-compose.yml
create_docker_compose() {
    log_info "Tworzenie pliku docker-compose.yml..."
    
    cat > "${PROJECT_DIR}/docker-compose.yml" << EOF
version: '3.8'

services:
  # API Gateway (Traefik)
  api-gateway:
    build: ./microservices/api-gateway
    container_name: llm-api-gateway
    ports:
      - "80:80"      # API
      - "8080:8080"  # Dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - llm-network
    depends_on:
      - model-service
    restart: unless-stopped

  # Model Service
  model-service:
    build: 
      context: ./microservices/model-service
      dockerfile: Dockerfile
    container_name: llm-model-service
    environment:
      - MODEL_PATH=/app/models/tinyllama
      - USE_INT8=true
      - MODEL_SERVICE_PORT=5000
    volumes:
      - model-data:/app/models
      - ./.cache/pip:/root/.cache/pip
      - ./.cache/models:/app/.cache/models
    networks:
      - llm-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 4G

networks:
  llm-network:
    driver: bridge

volumes:
  model-data:
    driver: local
EOF
    
    log_info "Plik docker-compose.yml utworzony."
}

# Funkcja do tworzenia skryptu uruchamiającego
create_run_script() {
    log_info "Tworzenie skryptu uruchamiającego..."
    
    cat > "${PROJECT_DIR}/run_microservices.sh" << EOF
#!/bin/bash
# Skrypt do uruchamiania architektury mikrousług llm-orchestrator-min

# Kolory do logów
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funkcja do wyświetlania komunikatów
log_info() { echo -e "\${GREEN}[INFO]\${NC} \$1"; }
log_warn() { echo -e "\${YELLOW}[WARN]\${NC} \$1"; }
log_error() { echo -e "\${RED}[ERROR]\${NC} \$1"; }

# Funkcja do sprawdzania cache
check_cache() {
    log_info "Sprawdzanie cache pakietów..."
    
    CACHE_DIR="./.cache"
    PIP_CACHE="\${CACHE_DIR}/pip"
    MODEL_CACHE="\${CACHE_DIR}/models/tinyllama"
    
    # Sprawdzenie, czy katalogi cache istnieją
    if [ ! -d "\${PIP_CACHE}" ]; then
        log_warn "Katalog cache pip nie istnieje. Tworzenie..."
        mkdir -p "\${PIP_CACHE}"
    else
        log_info "Znaleziono cache pip."
    fi
    
    if [ ! -d "\${MODEL_CACHE}" ]; then
        log_warn "Katalog cache modelu nie istnieje. Tworzenie..."
        mkdir -p "\${MODEL_CACHE}"
    else
        log_info "Znaleziono cache modelu."
        log_info "Pliki w cache modelu:"
        ls -la "\${MODEL_CACHE}"
    fi
}

# Główna logika skryptu
case "\$1" in
    build)
        log_info "Budowanie mikrousług..."
        check_cache
        docker-compose build
        ;;
    run)
        log_info "Uruchamianie mikrousług..."
        check_cache
        docker-compose up -d
        log_info "API dostępne pod adresem: http://localhost/api"
        ;;
    stop)
        log_info "Zatrzymywanie mikrousług..."
        docker-compose down
        ;;
    logs)
        log_info "Wyświetlanie logów..."
        docker-compose logs -f \$2
        ;;
    test)
        log_info "Uruchamianie testów..."
        curl -s http://localhost/api/health
        ;;
    cache-status)
        check_cache
        ;;
    *)
        echo "Użycie: \$0 {build|run|stop|logs|test|cache-status}"
        exit 1
        ;;
esac

exit 0
EOF
    
    chmod +x "${PROJECT_DIR}/run_microservices.sh"
    
    log_info "Skrypt uruchamiający utworzony."
}

# Funkcja do modyfikacji kodu API
modify_api_code() {
    log_info "Modyfikowanie kodu API dla mikrousług..."
    
    # Modyfikacja model_service.py
    sed -i 's/app = Flask(__name__)/app = Flask(__name__)\n\n@app.route("\/health", methods=["GET"])\ndef health_check():\n    return jsonify({"status": "ok"}), 200/' "${MICROSERVICES_DIR}/model-service/model_service.py"
    
    # Dodanie endpointu dla metryk Prometheus
    cat >> "${MICROSERVICES_DIR}/model-service/model_service.py" << EOF

# Dodanie metryk Prometheus
from prometheus_client import Counter, Histogram, generate_latest
import time

# Metryki
REQUESTS = Counter('model_requests_total', 'Total number of requests')
PREDICTION_TIME = Histogram('model_prediction_seconds', 'Time spent processing prediction')

@app.route('/metrics', methods=['GET'])
def metrics():
    return generate_latest()

# Modyfikacja głównej funkcji predykcji, aby zbierać metryki
@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    if request.path != '/metrics' and request.path != '/health':
        REQUESTS.inc()
        if hasattr(request, 'start_time'):
            PREDICTION_TIME.observe(time.time() - request.start_time)
    return response
EOF
    
    log_info "Kod API zmodyfikowany."
}

# Funkcja do tworzenia konfiguracji monitoringu
create_monitoring_config() {
    log_info "Tworzenie konfiguracji monitoringu..."
    
    # Tworzenie katalogu dla monitoringu
    mkdir -p "${PROJECT_DIR}/monitoring"
    
    # Tworzenie pliku docker-compose dla monitoringu
    cat > "${PROJECT_DIR}/monitoring/docker-compose.yml" << EOF
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.40.0
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"
    restart: unless-stopped
    networks:
      - monitoring-network
      - llm-network

  grafana:
    image: grafana/grafana:9.3.0
    container_name: grafana
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    ports:
      - "3000:3000"
    restart: unless-stopped
    networks:
      - monitoring-network

networks:
  monitoring-network:
    driver: bridge
  llm-network:
    external: true

volumes:
  prometheus_data:
  grafana_data:
EOF

    # Tworzenie pliku konfiguracyjnego Prometheus
    cat > "${PROJECT_DIR}/monitoring/prometheus.yml" << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "model-service"
    metrics_path: /metrics
    static_configs:
      - targets: ["model-service:5000"]

  - job_name: "api-gateway"
    metrics_path: /metrics
    static_configs:
      - targets: ["api-gateway:8080"]
EOF

    log_info "Konfiguracja monitoringu utworzona."
}

# Główna funkcja
main() {
    log_info "Rozpoczynam migrację do architektury mikrousług..."
    
    check_requirements
    create_directory_structure
    copy_files
    setup_package_caching
    create_docker_files
    create_traefik_config
    create_docker_compose
    create_run_script
    modify_api_code
    create_monitoring_config
    
    log_info "Migracja zakończona pomyślnie."
    log_info "Aby uruchomić mikrousługi, wykonaj:"
    log_info "  ./run_microservices.sh build"
    log_info "  ./run_microservices.sh run"
}

# Uruchomienie głównej funkcji
main
