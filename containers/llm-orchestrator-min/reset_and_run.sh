#!/bin/bash

# Kolory do logów
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funkcja do wyświetlania komunikatów
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Funkcja do sprawdzania błędów
check_error() {
    if [ $? -ne 0 ]; then
        log_error "$1"
        exit 1
    fi
}

# Funkcja do całkowitego resetowania środowiska Docker
reset_docker_environment() {
    log_info "Resetowanie środowiska Docker..."
    
    # Zatrzymanie i usunięcie wszystkich kontenerów związanych z projektem
    log_info "Zatrzymywanie i usuwanie kontenerów..."
    for container in $(docker ps -a --filter name=llm -q); do
        docker stop $container 2>/dev/null || true
        docker rm $container 2>/dev/null || true
    done
    
    # Zatrzymanie i usunięcie kontenerów noVNC i browser
    for container in novnc browser; do
        if docker ps -a | grep -q "$container"; then
            log_info "Zatrzymywanie i usuwanie kontenera $container..."
            docker stop $container 2>/dev/null || true
            docker rm $container 2>/dev/null || true
        fi
    done
    
    # Usunięcie sieci Docker
    if docker network ls | grep -q "llm-network"; then
        log_info "Usuwanie sieci Docker 'llm-network'..."
        docker network rm llm-network 2>/dev/null || true
    fi
    
    # Usunięcie obrazów Docker
    log_info "Usuwanie obrazów Docker..."
    for image in $(docker images | grep llm-orchestrator-min | awk '{print $3}'); do
        docker rmi -f $image 2>/dev/null || true
    done
    
    log_info "Środowisko Docker zostało zresetowane."
}

# Funkcja do ręcznego uruchamiania kontenerów
manual_run_containers() {
    log_info "Ręczne uruchamianie kontenerów..."
    
    # Tworzenie sieci Docker
    log_info "Tworzenie sieci Docker 'llm-network'..."
    docker network create llm-network
    check_error "Tworzenie sieci Docker nie powiodło się."
    
    # Budowanie i uruchamianie model-service
    log_info "Budowanie i uruchamianie model-service..."
    cd ./microservices/model-service
    docker build -t llm-model-service .
    check_error "Budowanie model-service nie powiodło się."
    
    docker run -d --name llm-model-service \
        --network llm-network \
        -e MODEL_PATH=/app/models/tinyllama \
        -e USE_INT8=true \
        -e MODEL_SERVICE_PORT=5000 \
        -v $(pwd)/../../models:/app/models \
        -v $(pwd)/../../.cache/pip:/root/.cache/pip \
        -v $(pwd)/../../.cache/models:/app/.cache/models \
        llm-model-service
    check_error "Uruchamianie model-service nie powiodło się."
    
    # Budowanie i uruchamianie api-gateway
    log_info "Budowanie i uruchamianie api-gateway..."
    cd ../api-gateway
    docker build -t llm-api-gateway .
    check_error "Budowanie api-gateway nie powiodło się."
    
    docker run -d --name llm-api-gateway \
        --network llm-network \
        -p 80:80 \
        -p 8080:8080 \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        llm-api-gateway
    check_error "Uruchamianie api-gateway nie powiodło się."
    
    cd ../..
    log_info "Kontenery zostały uruchomione ręcznie."
}

# Funkcja do konfiguracji środowiska testowego z noVNC
setup_novnc_test() {
    log_info "Konfiguracja środowiska testowego z noVNC..."
    
    # Uruchomienie noVNC
    log_info "Uruchamianie kontenera noVNC..."
    docker run -d --name novnc \
        --network llm-network \
        -p 6080:6080 \
        -e VNC_PASSWORD=password \
        theasp/novnc:latest
    check_error "Uruchamianie kontenera noVNC nie powiodło się."
    
    # Uruchomienie przeglądarki Firefox
    log_info "Uruchamianie kontenera przeglądarki..."
    docker run -d --name browser \
        --network llm-network \
        -e DISPLAY=novnc:0 \
        jlesage/firefox:latest
    check_error "Uruchamianie kontenera przeglądarki nie powiodło się."
    
    # Tworzenie strony testowej HTML
    log_info "Tworzenie strony testowej HTML..."
    mkdir -p ./test_files
    
    cat > ./test_files/test_llm.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Test LLM API</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            display: flex;
            flex-direction: column;
            gap: 15px;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        textarea {
            height: 120px;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 16px;
            resize: vertical;
        }
        button {
            padding: 12px;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            transition: background-color 0.3s;
        }
        button:hover {
            background-color: #45a049;
        }
        button:disabled {
            background-color: #cccccc;
            cursor: not-allowed;
        }
        #response {
            margin-top: 20px;
            padding: 15px;
            border: 1px solid #ddd;
            border-radius: 4px;
            min-height: 120px;
            background-color: #f9f9f9;
            white-space: pre-wrap;
        }
        .status {
            margin-top: 10px;
            font-style: italic;
            color: #666;
        }
        .controls {
            display: flex;
            gap: 10px;
        }
        .slider-container {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        .slider-label {
            display: flex;
            justify-content: space-between;
        }
    </style>
</head>
<body>
    <h1>Test LLM API</h1>
    <div class="container">
        <label for="prompt"><strong>Wprowadź prompt:</strong></label>
        <textarea id="prompt">Opowiedz mi krótką historię o kocie.</textarea>
        
        <div class="controls">
            <div class="slider-container">
                <label for="temperature" class="slider-label">
                    <span>Temperatura:</span>
                    <span id="temp-value">0.7</span>
                </label>
                <input type="range" id="temperature" min="0.1" max="1.5" step="0.1" value="0.7" oninput="updateSliderValue('temp-value', this.value)">
            </div>
            
            <div class="slider-container">
                <label for="max-length" class="slider-label">
                    <span>Maks. długość:</span>
                    <span id="length-value">256</span>
                </label>
                <input type="range" id="max-length" min="64" max="512" step="32" value="256" oninput="updateSliderValue('length-value', this.value)">
            </div>
        </div>
        
        <button id="generate-btn" onclick="generateText()">Generuj tekst</button>
        
        <div>
            <h3>Odpowiedź:</h3>
            <div id="response">Tutaj pojawi się odpowiedź...</div>
            <p class="status" id="status"></p>
        </div>
    </div>

    <script>
        function updateSliderValue(elementId, value) {
            document.getElementById(elementId).textContent = value;
        }
        
        async function generateText() {
            const prompt = document.getElementById('prompt').value;
            const temperature = parseFloat(document.getElementById('temperature').value);
            const maxLength = parseInt(document.getElementById('max-length').value);
            const responseDiv = document.getElementById('response');
            const statusDiv = document.getElementById('status');
            const generateBtn = document.getElementById('generate-btn');
            
            if (!prompt.trim()) {
                alert('Proszę wprowadzić prompt!');
                return;
            }
            
            responseDiv.textContent = "Generowanie odpowiedzi...";
            statusDiv.textContent = "Łączenie z API...";
            generateBtn.disabled = true;
            
            try {
                const startTime = new Date();
                statusDiv.textContent = "Wysyłanie zapytania...";
                
                const response = await fetch('http://llm-api-gateway/api/generate', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        prompt: prompt,
                        max_length: maxLength,
                        temperature: temperature
                    })
                });
                
                statusDiv.textContent = "Przetwarzanie odpowiedzi...";
                const data = await response.json();
                const endTime = new Date();
                const timeTaken = (endTime - startTime) / 1000;
                
                if (data.success) {
                    responseDiv.textContent = data.response;
                    statusDiv.textContent = `Odpowiedź wygenerowana w ${timeTaken.toFixed(2)} sekund.`;
                } else {
                    responseDiv.textContent = "Błąd: " + data.error;
                    statusDiv.textContent = "Wystąpił błąd podczas generowania odpowiedzi.";
                }
            } catch (error) {
                responseDiv.textContent = "Błąd połączenia: " + error.message;
                statusDiv.textContent = "Nie można połączyć się z API.";
            } finally {
                generateBtn.disabled = false;
            }
        }
    </script>
</body>
</html>
EOF
    
    # Kopiowanie pliku testowego do kontenera przeglądarki
    log_info "Kopiowanie strony testowej do kontenera przeglądarki..."
    docker cp ./test_files/test_llm.html browser:/config/
    check_error "Kopiowanie strony testowej nie powiodło się."
    
    log_info "Środowisko testowe zostało skonfigurowane pomyślnie."
}

# Funkcja do testowania API
test_api() {
    log_info "Testowanie API..."
    
    # Oczekiwanie na uruchomienie API (max 30 sekund)
    log_info "Oczekiwanie na uruchomienie API..."
    for i in {1..30}; do
        if curl -s http://localhost/api/health > /dev/null; then
            log_info "API jest dostępne."
            break
        fi
        
        if [ $i -eq 30 ]; then
            log_error "API nie jest dostępne po 30 sekundach. Sprawdź logi mikrousług."
            exit 1
        fi
        
        log_info "Oczekiwanie na API... ($i/30)"
        sleep 1
    done
    
    # Testowanie endpointu health
    log_info "Testowanie endpointu health..."
    HEALTH_RESPONSE=$(curl -s http://localhost/api/health)
    echo "Odpowiedź: $HEALTH_RESPONSE"
    
    # Testowanie generowania tekstu
    log_info "Testowanie generowania tekstu..."
    log_info "Wysyłanie zapytania do API..."
    GENERATE_RESPONSE=$(curl -s -X POST http://localhost/api/generate \
        -H "Content-Type: application/json" \
        -d '{"prompt":"Powiedz cześć", "max_length":64, "temperature":0.7}')
    echo "Odpowiedź: $GENERATE_RESPONSE"
    
    log_info "Testy API zakończone."
}

# Funkcja do wyświetlania instrukcji
show_instructions() {
    log_info "System został uruchomiony pomyślnie!"
    log_info "Aby przetestować system LLM, wykonaj następujące kroki:"
    log_info "1. Otwórz przeglądarkę i przejdź do adresu: http://localhost:6080"
    log_info "2. Zaloguj się używając hasła: password"
    log_info "3. W przeglądarce Firefox wewnątrz noVNC, otwórz plik: file:///config/test_llm.html"
    log_info "4. Możesz również przetestować API bezpośrednio, przechodząc do: http://localhost/api/health"
    log_info "5. Dashboard Traefik jest dostępny pod adresem: http://localhost:8080"
    log_info ""
    log_info "Aby zatrzymać system, użyj skryptu: ./stop.sh"
}

# Główna funkcja
main() {
    log_info "Resetowanie i uruchamianie systemu LLM..."
    
    # Sprawdzenie, czy katalogi istnieją
    if [ ! -d "./.cache" ]; then
        log_info "Tworzenie katalogów cache..."
        mkdir -p ./.cache/pip
        mkdir -p ./.cache/models/tinyllama
    fi
    
    # Sprawdzenie, czy katalog models istnieje
    if [ ! -d "./models" ]; then
        log_info "Tworzenie katalogu models..."
        mkdir -p ./models/tinyllama
    fi
    
    # Resetowanie środowiska Docker
    reset_docker_environment
    
    # Ręczne uruchamianie kontenerów
    manual_run_containers
    
    # Konfiguracja środowiska testowego
    setup_novnc_test
    
    # Testowanie API
    test_api
    
    # Wyświetlenie instrukcji
    show_instructions
    
    log_info "System został uruchomiony pomyślnie."
}

# Uruchomienie głównej funkcji
main
