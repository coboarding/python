#!/bin/bash
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

# Wykrywanie platformy
OS="$(uname -s)"
PM=""
INSTALL=""

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ $ID == "ubuntu" || $ID == "debian" ]]; then
        PM="apt"
        INSTALL="apt install -y"
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
if [[ $PM == "apt" ]]; then
    apt update && apt upgrade -y || (ERR "apt upgrade nie powiodło się, próbuję ponownie..." && apt upgrade -y)
elif [[ $PM == "dnf" ]]; then
    dnf upgrade -y || (ERR "dnf upgrade nie powiodło się, próbuję ponownie..." && dnf upgrade -y)
elif [[ $PM == "pacman" ]]; then
    pacman -Syu --noconfirm || (ERR "pacman upgrade nie powiodło się, próbuję ponownie..." && pacman -Syu --noconfirm)
fi

LOG "Instalacja narzędzi systemowych (curl, wget, git, python3, pip, unzip)"
$INSTALL curl wget git python3 python3-pip unzip || (ERR "Instalacja narzędzi systemowych nie powiodła się, próbuję ponownie..." && $INSTALL curl wget git python3 python3-pip unzip)

# Instalacja terraform i ansible-lint
if [[ $PM == "apt" ]]; then
    if ! command -v terraform &> /dev/null; then
        if grep -q 'Ubuntu 24.10' /etc/os-release || grep -q 'Ubuntu 25' /etc/os-release; then
            echo "[INFO] Instaluję terraform przez snap (brak w apt na Ubuntu 24.10+)"
            sudo snap install terraform --classic
        else
            $INSTALL terraform
        fi
    fi
    $INSTALL ansible-lint
elif [[ $PM == "dnf" ]]; then
    $INSTALL terraform ansible-lint
elif [[ $PM == "pacman" ]]; then
    $INSTALL terraform ansible-lint
fi

# Instalacja Docker
LOG "Instalacja Docker (jeśli brak)"
if ! command -v docker &> /dev/null; then
    if [[ $PM == "apt" ]]; then
        $INSTALL docker.io || (ERR "Instalacja docker.io nie powiodła się!" && exit 1)
    elif [[ $PM == "dnf" ]]; then
        $INSTALL docker || (ERR "Instalacja docker nie powiodła się!" && exit 1)
        systemctl enable --now docker
    elif [[ $PM == "pacman" ]]; then
        $INSTALL docker || (ERR "Instalacja docker nie powiodła się!" && exit 1)
        systemctl enable --now docker
    fi
    if ! command -v docker &> /dev/null; then ERR "Docker nadal nie jest dostępny!"; exit 1; fi
fi
DEBUG "Docker wersja: $(docker --version 2>/dev/null || echo 'niedostępny')"

# Instalacja Docker Compose
LOG "Instalacja Docker Compose (jeśli brak)"
if ! command -v docker-compose &> /dev/null; then
    if [[ $PM == "apt" ]]; then
        $INSTALL docker-compose || (ERR "Instalacja docker-compose nie powiodła się!" && exit 1)
    elif [[ $PM == "dnf" ]]; then
        $INSTALL docker-compose || (ERR "Instalacja docker-compose nie powiodła się!" && exit 1)
    elif [[ $PM == "pacman" ]]; then
        $INSTALL docker-compose || (ERR "Instalacja docker-compose nie powiodła się!" && exit 1)
    else
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    if ! command -v docker-compose &> /dev/null; then ERR "Docker Compose nadal nie jest dostępny!"; exit 1; fi
fi
DEBUG "Docker Compose wersja: $(docker-compose --version 2>/dev/null || echo 'niedostępny')"

# Instalacja Terraform
LOG "Instalacja Terraform (jeśli brak)"
if ! command -v terraform &> /dev/null; then
    if [[ $PM == "dnf" ]]; then
        $INSTALL dnf-plugins-core || true
        dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
        $INSTALL terraform || (ERR "Instalacja terraform nie powiodła się!" && exit 1)
    else
        wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
        unzip terraform_1.6.6_linux_amd64.zip
        mv terraform /usr/local/bin/
        rm terraform_1.6.6_linux_amd64.zip
    fi
    if ! command -v terraform &> /dev/null; then ERR "Terraform nadal nie jest dostępny!"; exit 1; fi
fi
DEBUG "Terraform wersja: $(terraform version 2>/dev/null | head -n 1 || echo 'niedostępny')"

# Instalacja Ansible
LOG "Instalacja Ansible (jeśli brak)"
if ! command -v ansible &> /dev/null; then
    $INSTALL ansible || (ERR "Instalacja ansible nie powiodła się!" && exit 1)
    if ! command -v ansible &> /dev/null; then ERR "Ansible nadal nie jest dostępny!"; exit 1; fi
fi
DEBUG "Ansible wersja: $(ansible --version 2>/dev/null | head -n 1 || echo 'niedostępny')"

# Instalacja VS Code Server (code-server)
LOG "Instalacja code-server (jeśli brak)"
if ! command -v code-server &> /dev/null; then
    curl -fsSL https://code-server.dev/install.sh | sh || (ERR "Instalacja code-server nie powiodła się!" && exit 1)
    if ! command -v code-server &> /dev/null; then ERR "code-server nadal nie jest dostępny!"; exit 1; fi
fi
DEBUG "code-server wersja: $(code-server --version 2>/dev/null || echo 'niedostępny')"

# Zapewnij uprawnienia do zapisu dla bieżącego użytkownika (np. dla katalogu projektu)
LOG "Nadawanie uprawnień do zapisu dla katalogu projektu: $(pwd)"
sudo chown -R $(id -u):$(id -g) "$(pwd)"
chmod -R u+rw "$(pwd)"

# Instalacja nagłówków developerskich Pythona (Python development headers)
PYTHON_VERSION="3.11"
PYTHON_CMD="python3.11"
LOG "Instalacja nagłówków developerskich Pythona ($PYTHON_VERSION)"
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
DEBUG "Python wersja: $($PYTHON_CMD --version 2>/dev/null || echo 'niedostępny')"

# Instalacja i aktywacja środowiska wirtualnego (Python 3.11/3.12)
if [ ! -d "venv-py$PYTHON_VERSION" ]; then
    $PYTHON_CMD -m venv venv-py$PYTHON_VERSION
fi
source venv-py$PYTHON_VERSION/bin/activate

# Upewnij się, że pip, setuptools i wheel są zaktualizowane
python -m pip install --upgrade pip setuptools wheel

# Dodatkowe komunikaty diagnostyczne
python -m pip --version
python -m pip list

# Instalacja zależności Pythona
python -m pip install -r requirements.txt
# Ensure beautifulsoup4 is installed (for e2e/test-runner)
pip show beautifulsoup4 >/dev/null 2>&1 || pip install beautifulsoup4

# Inicjalizacja struktury projektu
if [ -f scripts/setup.sh ]; then
  bash scripts/setup.sh
else
  echo "[WARN] Pominięto scripts/setup.sh (plik nie istnieje)"
fi

echo "\nŚrodowisko autodev zainstalowane. Użyj ./run.sh lub ./run.ps1 do uruchomienia systemu."
