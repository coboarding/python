# Uniwersalny skrypt uruchomieniowy coBoarding (Windows PowerShell)

$ErrorActionPreference = 'Stop'

# Sprawdź, czy środowisko jest już zainicjalizowane
if (!(Test-Path -Path './volumes/models') -or !(Test-Path -Path './docker-compose.yml')) {
    Write-Host '[coBoarding] Środowisko nie jest zainicjalizowane. Uruchamiam instalację...'
    if (Test-Path './install.ps1') {
        .\install.ps1
    } elseif (Test-Path './install.sh') {
        bash ./install.sh
    } elseif (Test-Path './setup-all.sh') {
        bash ./setup-all.sh
    } elseif (Test-Path './init.sh') {
        bash ./init.sh
    } else {
        Write-Error 'Brak skryptu instalacyjnego (install.sh/setup-all.sh/init.sh)! Przerwano.'
        exit 1
    }
} else {
    Write-Host '[coBoarding] Środowisko już skonfigurowane. Uruchamiam środowisko...'
    docker-compose up -d
}

# --- Tworzenie i aktywacja środowiska venv (Windows) ---
if (!(Test-Path -Path './venv')) {
    Write-Host '[coBoarding] Tworzenie środowiska venv (rekomendowany Python 3.11)...'
    if (Get-Command python3.11 -ErrorAction SilentlyContinue) {
        python3.11 -m venv venv
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        python -m venv venv
    } else {
        Write-Error 'Nie znaleziono interpretera Python!'
        exit 1
    }
    .\venv\Scripts\Activate.ps1
    pip install --upgrade pip
    pip install -r requirements.txt
} else {
    .\venv\Scripts\Activate.ps1
}

if ($LASTEXITCODE -eq 0) {
    Write-Host '[coBoarding] System został uruchomiony!'
    Write-Host '- Web:      http://localhost:8082'
    Write-Host '- Terminal: http://localhost:8081'
    Write-Host '- Przegląd: http://localhost:8082'
} else {
    Write-Error '[coBoarding] Błąd podczas uruchamiania środowiska.'
    exit 1
}
