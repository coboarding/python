#!/bin/bash

# Skrypt do automatycznego uruchamiania testów po starcie kontenera
# Autor: Tom
# Data: 2025-05-13

set -e

# Kolory do lepszej czytelności
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funkcja do wyświetlania komunikatów
log() {
  local level=$1
  local message=$2
  
  case $level in
    "INFO")
      echo -e "${GREEN}[INFO]${NC} $message"
      ;;
    "WARN")
      echo -e "${YELLOW}[WARN]${NC} $message"
      ;;
    "ERROR")
      echo -e "${RED}[ERROR]${NC} $message"
      ;;
    *)
      echo -e "${BLUE}[DEBUG]${NC} $message"
      ;;
  esac
}

# Funkcja do czekania na dostępność API
wait_for_api() {
  local api_url=${1:-"http://localhost:5000/api/health"}
  local max_attempts=${2:-60}
  local attempt=0
  
  log "INFO" "Czekam na dostępność API pod adresem: $api_url"
  
  while [ $attempt -lt $max_attempts ]; do
    attempt=$((attempt+1))
    
    if curl -s "$api_url" &>/dev/null; then
      log "INFO" "API jest dostępne!"
      return 0
    fi
    
    echo -n "."
    sleep 1
  done
  
  log "ERROR" "API nie uruchomiło się w oczekiwanym czasie"
  return 1
}

# Funkcja do uruchamiania podstawowych testów
run_basic_tests() {
  log "INFO" "Uruchamianie podstawowych testów API..."
  
  if [ -f "/app/scripts/test_api.sh" ]; then
    # Jesteśmy wewnątrz kontenera
    /app/scripts/test_api.sh
  else
    # Jesteśmy na hoście
    if docker ps | grep -q llm-orchestrator-min; then
      docker exec llm-orchestrator-min /app/scripts/test_api.sh || {
        log "WARN" "Nie można uruchomić skryptu testowego w kontenerze"
        log "INFO" "Kopiuję skrypt testowy do kontenera..."
        docker cp "$(dirname "$0")/test_api.sh" llm-orchestrator-min:/app/scripts/
        docker exec llm-orchestrator-min chmod +x /app/scripts/test_api.sh
        docker exec llm-orchestrator-min /app/scripts/test_api.sh
      }
    else
      log "ERROR" "Kontener llm-orchestrator-min nie jest uruchomiony"
      return 1
    fi
  fi
  
  return $?
}

# Funkcja do uruchamiania kompleksowych testów
run_comprehensive_tests() {
  local api_url=${1:-"http://localhost:5000"}
  local output_file=${2:-"test_results.json"}
  local run_load_test=${3:-false}
  
  log "INFO" "Uruchamianie kompleksowych testów API..."
  
  local load_test_args=""
  if [ "$run_load_test" = true ]; then
    load_test_args="--load-test"
  fi
  
  if [ -f "/app/scripts/comprehensive_test.py" ]; then
    # Jesteśmy wewnątrz kontenera
    python /app/scripts/comprehensive_test.py --url "$api_url" --verbose --output "$output_file" $load_test_args
  else
    # Jesteśmy na hoście
    if docker ps | grep -q llm-orchestrator-min; then
      # Kopiujemy skrypt do kontenera
      docker cp "$(dirname "$0")/comprehensive_test.py" llm-orchestrator-min:/app/scripts/
      
      # Instalujemy zależności jeśli potrzebne
      docker exec llm-orchestrator-min pip install requests 2>/dev/null || true
      
      # Uruchamiamy testy
      docker exec llm-orchestrator-min python /app/scripts/comprehensive_test.py --url "$api_url" --verbose --output "/app/scripts/$output_file" $load_test_args
      
      # Kopiujemy wyniki na hosta
      docker cp "llm-orchestrator-min:/app/scripts/$output_file" "$(dirname "$0")/$output_file"
      log "INFO" "Wyniki testów zapisane w pliku: $(dirname "$0")/$output_file"
    else
      log "ERROR" "Kontener llm-orchestrator-min nie jest uruchomiony"
      return 1
    fi
  fi
  
  return $?
}

# Funkcja do generowania raportu HTML
generate_html_report() {
  local json_file=${1:-"test_results.json"}
  local html_file=${2:-"test_report.html"}
  
  log "INFO" "Generowanie raportu HTML z wyników testów..."
  
  # Sprawdzamy czy mamy dostęp do pliku JSON
  if [ ! -f "$json_file" ]; then
    if [ -f "$(dirname "$0")/$json_file" ]; then
      json_file="$(dirname "$0")/$json_file"
    else
      log "ERROR" "Nie znaleziono pliku z wynikami testów: $json_file"
      return 1
    fi
  fi
  
  # Generujemy raport HTML
  cat > "$html_file" <<EOF
<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Raport z testów API LLM-Orchestrator-Min</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      margin: 0;
      padding: 20px;
      color: #333;
    }
    h1, h2, h3 {
      color: #2c3e50;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
    }
    .summary {
      background-color: #f8f9fa;
      padding: 20px;
      border-radius: 5px;
      margin-bottom: 20px;
    }
    .success {
      color: #28a745;
    }
    .warning {
      color: #ffc107;
    }
    .error {
      color: #dc3545;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
    }
    th, td {
      padding: 12px 15px;
      text-align: left;
      border-bottom: 1px solid #ddd;
    }
    th {
      background-color: #f2f2f2;
    }
    tr:hover {
      background-color: #f5f5f5;
    }
    .test-details {
      margin-top: 30px;
    }
    .timestamp {
      color: #6c757d;
      font-size: 0.9em;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Raport z testów API LLM-Orchestrator-Min</h1>
    <p class="timestamp">Wygenerowano: $(date '+%Y-%m-%d %H:%M:%S')</p>
    
    <div class="summary">
      <h2>Podsumowanie</h2>
      <p>Łączna liczba testów: <span id="total-tests">...</span></p>
      <p>Testy zaliczone: <span id="passed-tests" class="success">...</span></p>
      <p>Testy niezaliczone: <span id="failed-tests" class="error">...</span></p>
      <p>Współczynnik powodzenia: <span id="success-rate">...</span></p>
    </div>
    
    <div class="test-details">
      <h2>Szczegóły testów</h2>
      <table id="test-table">
        <thead>
          <tr>
            <th>Endpoint</th>
            <th>Metoda</th>
            <th>Opis</th>
            <th>Status</th>
            <th>Czas odpowiedzi (ms)</th>
          </tr>
        </thead>
        <tbody id="test-results">
          <!-- Dane testów będą wstawione przez JavaScript -->
        </tbody>
      </table>
    </div>
  </div>
  
  <script>
    // Wczytanie danych z pliku JSON
    const testData = JSON.parse(\`$(cat "$json_file")\`);
    
    // Aktualizacja podsumowania
    document.getElementById('total-tests').textContent = testData.total;
    document.getElementById('passed-tests').textContent = testData.passed;
    document.getElementById('failed-tests').textContent = testData.failed;
    
    const successRate = ((testData.passed / testData.total) * 100).toFixed(2);
    const successRateElement = document.getElementById('success-rate');
    successRateElement.textContent = successRate + '%';
    
    if (successRate >= 90) {
      successRateElement.className = 'success';
    } else if (successRate >= 70) {
      successRateElement.className = 'warning';
    } else {
      successRateElement.className = 'error';
    }
    
    // Wypełnienie tabeli wynikami testów
    const testResultsElement = document.getElementById('test-results');
    testData.tests.forEach(test => {
      const row = document.createElement('tr');
      
      const endpointCell = document.createElement('td');
      endpointCell.textContent = test.endpoint;
      row.appendChild(endpointCell);
      
      const methodCell = document.createElement('td');
      methodCell.textContent = test.method;
      row.appendChild(methodCell);
      
      const descriptionCell = document.createElement('td');
      descriptionCell.textContent = test.description;
      row.appendChild(descriptionCell);
      
      const statusCell = document.createElement('td');
      if (test.passed) {
        statusCell.textContent = 'Zaliczony';
        statusCell.className = 'success';
      } else {
        statusCell.textContent = 'Niezaliczony';
        statusCell.className = 'error';
      }
      row.appendChild(statusCell);
      
      const responseTimeCell = document.createElement('td');
      responseTimeCell.textContent = test.response_time;
      row.appendChild(responseTimeCell);
      
      testResultsElement.appendChild(row);
    });
  </script>
</body>
</html>
EOF
  
  log "INFO" "Raport HTML wygenerowany: $html_file"
  return 0
}

# Główna funkcja
main() {
  local api_url=${1:-"http://localhost:5000"}
  local run_load_test=${2:-false}
  local generate_report=${3:-true}
  
  log "INFO" "Rozpoczynam automatyczne testy po uruchomieniu kontenera"
  
  # Czekamy na dostępność API
  wait_for_api "$api_url/api/health" || {
    log "ERROR" "API nie jest dostępne, przerywam testy"
    return 1
  }
  
  # Uruchamiamy podstawowe testy
  run_basic_tests || {
    log "WARN" "Podstawowe testy nie powiodły się"
  }
  
  # Uruchamiamy kompleksowe testy
  run_comprehensive_tests "$api_url" "test_results.json" "$run_load_test" || {
    log "WARN" "Kompleksowe testy nie powiodły się"
  }
  
  # Generujemy raport HTML
  if [ "$generate_report" = true ]; then
    generate_html_report "test_results.json" "test_report.html" || {
      log "WARN" "Nie udało się wygenerować raportu HTML"
    }
  fi
  
  log "INFO" "Automatyczne testy zakończone"
  return 0
}

# Parsowanie argumentów
API_URL="http://localhost:5000"
RUN_LOAD_TEST=false
GENERATE_REPORT=true

while [[ $# -gt 0 ]]; do
  case $1 in
    --url=*)
      API_URL="${1#*=}"
      shift
      ;;
    --load-test)
      RUN_LOAD_TEST=true
      shift
      ;;
    --no-report)
      GENERATE_REPORT=false
      shift
      ;;
    *)
      log "WARN" "Nieznany argument: $1"
      shift
      ;;
  esac
done

# Uruchomienie głównej funkcji
main "$API_URL" "$RUN_LOAD_TEST" "$GENERATE_REPORT"
