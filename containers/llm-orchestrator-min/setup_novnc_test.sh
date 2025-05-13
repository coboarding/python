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

# Sprawdzenie, czy mikrousługi są uruchomione
check_microservices() {
    log_info "Sprawdzanie, czy mikrousługi są uruchomione..."
    
    if ! docker ps | grep -q "llm-model-service"; then
        log_warn "Mikrousługa model-service nie jest uruchomiona. Uruchamiam..."
        ./run_microservices.sh run
    else
        log_info "Mikrousługi są już uruchomione."
    fi
}

# Tworzenie sieci Docker, jeśli nie istnieje
create_network() {
    if ! docker network ls | grep -q "llm-network"; then
        log_info "Tworzenie sieci Docker 'llm-network'..."
        docker network create llm-network
    else
        log_info "Sieć 'llm-network' już istnieje."
    fi
    
    # Dodanie istniejących kontenerów do sieci, jeśli jeszcze nie są
    for container in llm-model-service llm-api-gateway; do
        if docker ps | grep -q "$container"; then
            if ! docker network inspect llm-network | grep -q "$container"; then
                log_info "Dodawanie kontenera $container do sieci llm-network..."
                docker network connect llm-network $container
            fi
        fi
    done
}

# Uruchomienie noVNC
start_novnc() {
    log_info "Uruchamianie kontenera noVNC..."
    
    # Sprawdzenie, czy kontener już istnieje
    if docker ps -a | grep -q "novnc"; then
        log_info "Kontener noVNC już istnieje. Uruchamiam..."
        docker start novnc
    else
        log_info "Tworzenie nowego kontenera noVNC..."
        docker run -d --name novnc \
            --network llm-network \
            -p 6080:6080 \
            -e VNC_PASSWORD=password \
            theasp/novnc:latest
    fi
}

# Uruchomienie przeglądarki Firefox
start_browser() {
    log_info "Uruchamianie kontenera z przeglądarką Firefox..."
    
    # Sprawdzenie, czy kontener już istnieje
    if docker ps -a | grep -q "browser"; then
        log_info "Kontener przeglądarki już istnieje. Uruchamiam..."
        docker start browser
    else
        log_info "Tworzenie nowego kontenera przeglądarki..."
        docker run -d --name browser \
            --network llm-network \
            -e DISPLAY=novnc:0 \
            jlesage/firefox:latest
    fi
}

# Tworzenie strony testowej HTML
create_test_page() {
    log_info "Tworzenie strony testowej HTML..."
    
    # Tworzenie katalogu dla plików testowych
    mkdir -p ./test_files
    
    # Tworzenie pliku HTML do testowania API
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
    
    log_info "Strona testowa utworzona w ./test_files/test_llm.html"
}

# Kopiowanie pliku testowego do kontenera przeglądarki
copy_test_page() {
    log_info "Kopiowanie strony testowej do kontenera przeglądarki..."
    
    # Sprawdzenie, czy kontener przeglądarki jest uruchomiony
    if ! docker ps | grep -q "browser"; then
        log_error "Kontener przeglądarki nie jest uruchomiony. Nie można skopiować pliku."
        return 1
    fi
    
    # Kopiowanie pliku do kontenera
    docker cp ./test_files/test_llm.html browser:/config/
    
    log_info "Plik testowy skopiowany do kontenera przeglądarki."
}

# Wyświetlenie instrukcji dla użytkownika
show_instructions() {
    log_info "Środowisko testowe zostało skonfigurowane pomyślnie!"
    log_info "Aby przetestować system LLM, wykonaj następujące kroki:"
    log_info "1. Otwórz przeglądarkę i przejdź do adresu: http://localhost:6080"
    log_info "2. Zaloguj się używając hasła: password"
    log_info "3. W przeglądarce Firefox wewnątrz noVNC, otwórz plik: file:///config/test_llm.html"
    log_info "4. Możesz również przetestować API bezpośrednio, przechodząc do: http://llm-api-gateway/api/health"
    log_info "5. Dashboard Traefik jest dostępny pod adresem: http://localhost:8080"
}

# Główna funkcja
main() {
    log_info "Rozpoczynam konfigurację środowiska testowego z noVNC..."
    
    check_microservices
    create_network
    start_novnc
    start_browser
    create_test_page
    copy_test_page
    show_instructions
    
    log_info "Konfiguracja zakończona."
}

# Uruchomienie głównej funkcji
main
