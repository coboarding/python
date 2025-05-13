# install.ps1 - Instalacja środowiska coBoarding na Windows

Write-Host "[INFO] Sprawdzanie wersji Pythona..."
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Error "Python nie jest zainstalowany. Pobierz i zainstaluj Python 3.11+ ze strony https://www.python.org/downloads/"
    exit 1
}
$pythonVersion = python --version
if ($pythonVersion -notmatch "3\.(1[1-9]|[2-9][0-9])") {
    Write-Error "Wymagana wersja Python >= 3.11. Twoja wersja: $pythonVersion"
    exit 1
}

Write-Host "[INFO] Tworzenie środowiska wirtualnego..."
python -m venv venv
if (!(Test-Path "venv")) {
    Write-Error "Nie udało się utworzyć środowiska venv."
    exit 1
}

Write-Host "[INFO] Aktywacja środowiska venv..."
.\venv\Scripts\Activate.ps1

Write-Host "[INFO] Aktualizacja pip..."
pip install --upgrade pip

Write-Host "[INFO] Instalacja zależności z requirements.txt..."
pip install -r requirements.txt

Write-Host "[INFO] Sprawdzanie instalacji Dockera..."
$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Error "Docker nie jest zainstalowany. Pobierz i zainstaluj Docker Desktop: https://www.docker.com/products/docker-desktop/"
    exit 1
}

Write-Host "[INFO] Sprawdzanie Docker Compose v2..."
$composeVersion = docker compose version 2>$null
if (-not $composeVersion) {
    Write-Warning "Docker Compose v2 nie jest dostępny jako 'docker compose'. Upewnij się, że masz aktualny Docker Desktop (v2+)."
} else {
    Write-Host "[INFO] Docker Compose v2 jest dostępny."
}

Write-Host "[INFO] Instalacja zakończona. Uruchom ./run.ps1 lub ./run.sh aby wystartować system."
