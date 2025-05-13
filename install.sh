#!/bin/bash

# Funkcja do mówienia komunikatów głosowych (TTS)
say() {
  if command -v espeak >/dev/null 2>&1; then
    espeak "$1" 2>/dev/null &
  else
    if [ -z "$TTS_WARNED" ]; then
      echo "[WARN] espeak (TTS) nie jest zainstalowany. Komunikaty głosowe są wyłączone."
      TTS_WARNED=1
    fi
  fi
}

# Kompletny instalator środowiska coboarding (Linux/macOS/Fedora)
set -e
set -o pipefail

LOG() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}
ERR() {
  echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

DEBUG() {
  if [[ "$DEBUG_INSTALL" == "1" ]]; then
    echo -e "\033[1;33m[DEBUG]\033[0m $1"
  fi
}

trap 'ERR "Wystąpił błąd w linii $LINENO. Sprawdź logi powyżej."' ERR

LOG "Tryb debugowania: ${DEBUG_INSTALL:-0} (ustaw DEBUG_INSTALL=1 aby zobaczyć więcej)"
echo "[DEBUG] Rozpoczynam aktualizację systemu pakietów (apt-get update)..."
say "Rozpoczynam aktualizację systemu pakietów."


# Wykrywanie platformy
OS="$(uname -s)"
PM=""
INSTALL=""

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ $ID == "ubuntu" || $ID == "debian" ]]; then
        PM="apt"
        INSTALL="echo \"[DEBUG] apt-get install\"; apt-get install -y"
    elif [[ $ID == "fedora" || $ID == "rhel" || $ID == "centos" ]]; then
        PM="dnf"
        INSTALL="dnf install -y"
    elif [[ $ID == "arch" ]]; then
        PM="pacman"
        INSTALL="pacman -Syu --noconfirm"
    fi
fi

if [[ $PM == "" ]]; then
    echo "Nieobsługiwana platforma. Zainstaluj wymagane pakiety ręcznie: curl, wget, git, python3, python3-pip, unzip, docker, docker-compose, terraform, ansible, code-server"; exit 1
fi

# Aktualizacja systemu
LOG "Aktualizacja systemu pakietów ($PM)"
echo "[DEBUG] Rozpoczynam aktualizację systemu pakietów ($PM)..."
if [[ $PM == "apt" ]]; then
    echo "[DEBUG] apt-get update"; apt-get update && echo "[DEBUG] apt-get upgrade"; apt-get upgrade -y || (ERR "apt upgrade nie powiodło się, próbuję ponownie..." && echo "[DEBUG] apt-get upgrade"; apt-get upgrade -y)
elif [[ $PM == "dnf" ]]; then
    echo "[DEBUG] dnf upgrade"; dnf upgrade -y || (ERR "dnf upgrade nie powiodło się, próbuję ponownie..." && dnf upgrade -y)
elif [[ $PM == "pacman" ]]; then
    echo "[DEBUG] pacman -Syu"; pacman -Syu --noconfirm || (ERR "pacman upgrade nie powiodło się, próbuję ponownie..." && pacman -Syu --noconfirm)
fi
echo "[DEBUG] Zakończono aktualizację systemu pakietów ($PM)..."
say "Zakończono aktualizację systemu pakietów."


LOG "Instalacja narzędzi systemowych (curl, wget, git, python3, pip, unzip)"
echo "[DEBUG] Rozpoczynam instalację narzędzi systemowych..."
say "Rozpoczynam instalację narzędzi systemowych."

$INSTALL curl wget git python3 python3-pip unzip npm || (ERR "Instalacja narzędzi systemowych nie powiodła się, próbuję ponownie..." && $INSTALL curl wget git python3 python3-pip unzip npm)
echo "[DEBUG] Zakończono instalację narzędzi systemowych..."
say "Zakończono instalację narzędzi systemowych."


# Instalacja terraform i ansible-lint
if [[ $PM == "apt" ]]; then
    if ! command -v terraform &> /dev/null; then
        if grep -q 'Ubuntu 24.10' /etc/os-release || grep -q 'Ubuntu 25' /etc/os-release; then
            echo "[INFO] Instaluję terraform przez snap (brak w apt na Ubuntu 24.10+)"
            echo "[DEBUG] Rozpoczynam instalację terraform przez snap..."
say "Rozpoczynam instalację Terraform przez snap."

            sudo snap install terraform --classic
            echo "[DEBUG] Zakończono instalację terraform przez snap..."
        else
            echo "[DEBUG] Rozpoczynam instalację terraform..."
            $INSTALL terraform
            echo "[DEBUG] Zakończono instalację terraform..."
        fi
    fi
    echo "[DEBUG] Rozpoczynam instalację ansible-lint..."
    $INSTALL ansible-lint
    echo "[DEBUG] Zakończono instalację ansible-lint..."
elif [[ $PM == "dnf" ]]; then
    echo "[DEBUG] Rozpoczynam instalację terraform..."
    $INSTALL terraform
    echo "[DEBUG] Zakończono instalację terraform..."
    echo "[DEBUG] Rozpoczynam instalację ansible-lint..."
    $INSTALL ansible-lint
    echo "[DEBUG] Zakończono instalację ansible-lint..."
elif [[ $PM == "pacman" ]]; then
    echo "[DEBUG] Rozpoczynam instalację terraform..."
    $INSTALL terraform
    echo "[DEBUG] Zakończono instalację terraform..."
    echo "[DEBUG] Rozpoczynam instalację ansible-lint..."
    $INSTALL ansible-lint
    echo "[DEBUG] Zakończono instalację ansible-lint..."
fi

# Instalacja Docker
LOG "Instalacja Docker (jeśli brak)"
echo "[DEBUG] Rozpoczynam instalację Docker..."
say "Rozpoczynam instalację Dockera."

if ! command -v docker &> /dev/null; then
    if [[ $PM == "apt" ]]; then
        $INSTALL docker.io || (ERR "Instalacja docker.io nie powiodła się!" && exit 1)
    elif [[ $PM == "dnf" ]]; then
        $INSTALL docker || (ERR "Instalacja docker nie powiodła się!" && exit 1)
        echo "[DEBUG] Uruchamiam usługę docker..."
        systemctl enable --now docker
        echo "[DEBUG] Zakończono uruchamianie usługi docker..."
    elif [[ $PM == "pacman" ]]; then
        $INSTALL docker || (ERR "Instalacja docker nie powiodła się!" && exit 1)
        echo "[DEBUG] Uruchamiam usługę docker..."
        systemctl enable --now docker
        echo "[DEBUG] Zakończono uruchamianie usługi docker..."
    fi
    if ! command -v docker &> /dev/null; then ERR "Docker nadal nie jest dostępny!"; exit 1; fi
fi
echo "[DEBUG] Zakończono instalację Docker..."
say "Zakończono instalację Dockera."


# Instalacja Node.js i npm z NodeSource (jeśli npm nie działa)
if ! command -v npm >/dev/null 2>&1 && ! [ -x /usr/bin/npm ]; then
  LOG "npm nie znaleziono lub nie działa – instaluję Node.js i npm z NodeSource"
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && $INSTALL nodejs
fi

# Doinstaluj npm jeśli nadal brak
if ! command -v npm >/dev/null 2>&1 && ! [ -x /usr/bin/npm ]; then
  LOG "npm nadal nie znaleziono – instaluję npm osobno przez apt lub install.sh z npmjs.com"
  $INSTALL npm || (curl -L https://www.npmjs.com/install.sh | bash -)
fi

# Instalacja socket.io-client (npm)
LOG "Instalacja socket.io-client (npm)"
if [ -d containers/video-chat ]; then
  cd containers/video-chat
  if [ -f package.json ]; then
    echo "[DEBUG] Instaluję socket.io-client przez npm..."
    if command -v npm >/dev/null 2>&1; then
      npm install socket.io-client || (ERR "Instalacja socket.io-client nie powiodła się!" && exit 1)
    elif [ -x /usr/bin/npm ]; then
      /usr/bin/npm install socket.io-client || (ERR "Instalacja socket.io-client nie powiodła się!" && exit 1)
    else
      ERR "Nie znaleziono npm w systemie PATH ani w /usr/bin/npm. Przerwano instalację socket.io-client."
      exit 1
    fi
    echo "[DEBUG] Zakończono instalację socket.io-client."
  else
    echo "[WARN] Brak package.json w containers/video-chat — pomijam instalację socket.io-client."
  fi
  cd - >/dev/null
else
  echo "[WARN] Brak katalogu containers/video-chat — pomijam instalację socket.io-client."
fi

# Instalacja Docker Compose
LOG "Instalacja Docker Compose (jeśli brak)"
echo "[DEBUG] Rozpoczynam instalację Docker Compose..."
say "Rozpoczynam instalację Docker Compose."

if ! docker compose version >/dev/null 2>&1; then
  LOG "Aktualizuję Docker Compose do wersji v2 (plugin CLI)..."
  DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
  mkdir -p $DOCKER_CONFIG/cli-plugins
  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o $DOCKER_CONFIG/cli-plugins/docker-compose
  chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
  if docker compose version >/dev/null 2>&1; then
    LOG "Docker Compose v2 zainstalowany jako plugin CLI."
  else
    ERR "Nie udało się zainstalować Docker Compose v2. Zainstaluj ręcznie lub sprawdź uprawnienia."
  fi
else
  LOG "Docker Compose v2 już zainstalowany."
fi

if [[ $PM == "apt" ]]; then
    $INSTALL docker-compose || (ERR "Instalacja docker-compose nie powiodła się!" && exit 1)
elif [[ $PM == "dnf" ]]; then
    $INSTALL docker-compose || (ERR "Instalacja docker-compose nie powiodła się!" && exit 1)
elif [[ $PM == "pacman" ]]; then
    $INSTALL docker-compose || (ERR "Instalacja docker-compose nie powiodła się!" && exit 1)
else
    echo "[DEBUG] Pobieram docker-compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    echo "[DEBUG] Zakończono pobieranie docker-compose..."
    chmod +x /usr/local/bin/docker-compose
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        echo "[DEBUG] Zakończono pobieranie docker-compose..."
        chmod +x /usr/local/bin/docker-compose
    fi
    if ! command -v docker-compose &> /dev/null; then ERR "Docker Compose nadal nie jest dostępny!"; exit 1; fi
fi
echo "[DEBUG] Zakończono instalację Docker Compose..."
say "Zakończono instalację Docker Compose."


# Instalacja Terraform
LOG "Instalacja Terraform (jeśli brak)"
echo "[DEBUG] Rozpoczynam instalację Terraform..."
say "Rozpoczynam instalację Terraform."

if ! command -v terraform &> /dev/null; then
    if [[ $PM == "dnf" ]]; then
        echo "[DEBUG] Instaluję dnf-plugins-core..."
        $INSTALL dnf-plugins-core || true
        echo "[DEBUG] Zakończono instalację dnf-plugins-core..."
        echo "[DEBUG] Dodaję repozytorium HashiCorp..."
        dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
        echo "[DEBUG] Zakończono dodawanie repozytorium HashiCorp..."
        echo "[DEBUG] Instaluję terraform..."
        $INSTALL terraform || (ERR "Instalacja terraform nie powiodła się!" && exit 1)
        echo "[DEBUG] Zakończono instalację terraform..."
    else
        echo "[DEBUG] Pobieram terraform..."
        wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
        echo "[DEBUG] Zakończono pobieranie terraform..."
        echo "[DEBUG] Rozpakowuję terraform..."
        unzip terraform_1.6.6_linux_amd64.zip
        echo "[DEBUG] Zakończono rozpakowywanie terraform..."
        echo "[DEBUG] Przenoszę terraform do /usr/local/bin..."
        mv terraform /usr/local/bin/
        echo "[DEBUG] Zakończono przenoszenie terraform do /usr/local/bin..."
        echo "[DEBUG] Usuwam plik zip..."
        rm terraform_1.6.6_linux_amd64.zip
        echo "[DEBUG] Zakończono usuwanie pliku zip..."
    fi
    if ! command -v terraform &> /dev/null; then ERR "Terraform nadal nie jest dostępny!"; exit 1; fi
fi
echo "[DEBUG] Zakończono instalację Terraform..."
say "Zakończono instalację Terraform."


# Instalacja Ansible
LOG "Instalacja Ansible (jeśli brak)"
echo "[DEBUG] Rozpoczynam instalację Ansible..."
say "Rozpoczynam instalację Ansible."

if ! command -v ansible &> /dev/null; then
    $INSTALL ansible || (ERR "Instalacja ansible nie powiodła się!" && exit 1)
    if ! command -v ansible &> /dev/null; then ERR "Ansible nadal nie jest dostępny!"; exit 1; fi
fi
echo "[DEBUG] Zakończono instalację Ansible..."
say "Zakończono instalację Ansible."

# Instalacja NVIDIA Container Toolkit (nvidia-docker2)
echo "[INFO] Instaluję NVIDIA Container Toolkit (nvidia-docker2)..."
if ! dpkg -l | grep -q nvidia-docker2; then
    #distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    distribution=ubuntu22.04
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt-get install -y nvidia-docker2
    sudo systemctl restart docker
else
    echo "[INFO] NVIDIA Container Toolkit już zainstalowany."
fi

# Konfiguracja Dockera do obsługi GPU (nvidia jako default-runtime)
if [ ! -f /etc/docker/daemon.json ]; then
  LOG "Tworzę /etc/docker/daemon.json z domyślnym runtime nvidia"
  sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
EOF
  sudo systemctl restart docker
  LOG "Zrestartowano Dockera po zmianie konfiguracji."
else
  ERR "Plik /etc/docker/daemon.json już istnieje. Jeśli chcesz korzystać z GPU, upewnij się, że zawiera konfigurację default-runtime nvidia."
fi

# Instalacja VS Code Server (code-server)
LOG "Instalacja code-server (jeśli brak)"
echo "[DEBUG] Rozpoczynam instalację code-server..."
say "Rozpoczynam instalację Code Server."

if ! command -v code-server &> /dev/null; then
    curl -fsSL https://code-server.dev/install.sh | sh || (ERR "Instalacja code-server nie powiodła się!" && exit 1)
    if ! command -v code-server &> /dev/null; then ERR "code-server nadal nie jest dostępny!"; exit 1; fi
fi
echo "[DEBUG] Zakończono instalację code-server..."
say "Zakończono instalację Code Server."


# Zapewnij uprawnienia do zapisu dla bieżącego użytkownika (np. dla katalogu projektu)
LOG "Nadawanie uprawnień do zapisu dla katalogu projektu: $(pwd)"
echo "[DEBUG] Nadaję uprawnienia do zapisu dla katalogu projektu..."
say "Nadaję uprawnienia do zapisu dla katalogu projektu."

sudo chown -R $(id -u):$(id -g) "$(pwd)"
chmod -R u+rw "$(pwd)"
echo "[DEBUG] Zakończono nadawanie uprawnień do zapisu dla katalogu projektu..."
say "Zakończono nadawanie uprawnień do zapisu dla katalogu projektu."


# Instalacja nagłówków developerskich Pythona (Python development headers)
PYTHON_VERSION="3.11"
PYTHON_CMD="python3.11"
LOG "Instalacja nagłówków developerskich Pythona ($PYTHON_VERSION)"
echo "[DEBUG] Rozpoczynam instalację nagłówków developerskich Pythona..."
say "Rozpoczynam instalację nagłówków developerskich Pythona."

if [[ $PM == "apt" ]]; then
    # Wykryj Ubuntu >=24.10 i fallback do 3.12
    if grep -q 'Ubuntu 24.10' /etc/os-release || grep -q 'Ubuntu 25' /etc/os-release; then
        LOG "Wykryto Ubuntu 24.10+ – używam Python 3.12 (brak oficjalnych pakietów 3.11)"
        PYTHON_VERSION="3.12"
        PYTHON_CMD="python3.12"
        $INSTALL python3.12 python3.12-venv python3.12-dev || $INSTALL python3-dev
    else
        $INSTALL python3.11 python3.11-venv python3.11-dev || $INSTALL python3-dev
    fi
elif [[ $PM == "dnf" ]]; then
    $INSTALL python3.11 python3.11-venv python3.11-devel || $INSTALL python3-devel
elif [[ $PM == "pacman" ]]; then
    $INSTALL python-pybind11 python python-pip
fi
echo "[DEBUG] Zakończono instalację nagłówków developerskich Pythona..."
say "Zakończono instalację nagłówków developerskich Pythona."


# Instalacja i aktywacja środowiska wirtualnego (Python 3.11/3.12)
if [ ! -d "venv-py$PYTHON_VERSION" ]; then
    echo "[DEBUG] Tworzę środowisko wirtualne Python..."; say "Tworzę środowisko wirtualne Python."
    $PYTHON_CMD -m venv venv-py$PYTHON_VERSION
    echo "[DEBUG] Zakończono tworzenie środowiska wirtualnego Python..."; say "Zakończono tworzenie środowiska wirtualnego Python."
fi
source venv-py$PYTHON_VERSION/bin/activate

# Upewnij się, że pip, setuptools i wheel są zaktualizowane
echo "[DEBUG] Aktualizuję pip..."; say "Aktualizuję pip."
say "Aktualizuję pip."

python -m pip install --upgrade pip setuptools wheel
echo "[DEBUG] Zakończono aktualizację pip..."; say "Zakończono aktualizację pip."
say "Zakończono aktualizację pip."


# Dodatkowe komunikaty diagnostyczne
python -m pip --version
python -m pip list

# Instalacja zależności Pythona
echo "[DEBUG] Instaluję zależności z requirements.txt..."; say "Instaluję zależności z requirements.txt."
say "Instaluję zależności z requirements.txt."

python -m pip install -r requirements.txt
echo "[DEBUG] Zakończono instalację zależności z requirements.txt..."; say "Zakończono instalację zależności z requirements.txt."
say "Zakończono instalację zależności z requirements.txt."


# Instalacja zależności testowych (selenium, pytest) do venv
if [ -z "$VIRTUAL_ENV" ]; then
  if [ -d "venv" ]; then
    LOG "Aktywuję środowisko venv do instalacji zależności testowych..."
    source venv/bin/activate
  else
    LOG "Tworzę środowisko venv do instalacji zależności testowych..."
    python3 -m venv venv
    source venv/bin/activate
  fi
fi

LOG "Instaluję selenium i pytest do środowiska venv..."
pip install --upgrade pip
pip install selenium pytest

# Ensure beautifulsoup4 is installed (for e2e/test-runner)
pip show beautifulsoup4 >/dev/null 2>&1 || pip install beautifulsoup4

# Inicjalizacja struktury projektu
if [ -f scripts/setup.sh ]; then
  echo "[DEBUG] Uruchamiam skrypt setup.sh..."
say "Uruchamiam skrypt setup.sh."

  bash scripts/setup.sh
  echo "[DEBUG] Zakończono uruchamianie skryptu setup.sh..."
say "Zakończono uruchamianie skryptu setup.sh."

else
  echo "[WARN] Pominięto scripts/setup.sh (plik nie istnieje)"
fi

echo "\nŚrodowisko autodev zainstalowane. Użyj ./run.sh lub ./run.ps1 do uruchomienia systemu."
