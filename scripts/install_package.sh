# Funkcja do instalacji pakietów
install_package() {
  local package_name=$1
  local check_command=$2
  # Sprawdź czy pakiet jest już zainstalowany
  if command -v $check_command &>/dev/null || $check_command --version &>/dev/null 2>&1; then
    echo -e "${GREEN}OK: $package_name już zainstalowany.${NC}"
    return 0
  fi
  echo -e "${YELLOW}Instaluję brakującą zależność: $package_name${NC}"
  echo -e "${YELLOW}UWAGA: Do instalacji $package_name wymagane są uprawnienia administratora.${NC}"
  echo -e "${YELLOW}Zostaniesz poproszony o podanie hasła sudo.${NC}"
  sleep 1
  if [ -z "$package_name" ]; then
    echo -e "${RED}Nie podano nazwy pakietu do instalacji!${NC}"
    return 1
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install $package_name || return 1
  elif [ -f /etc/debian_version ]; then
    sudo apt-get update && sudo apt-get install -y $package_name || return 1
  elif [ -f /etc/redhat-release ]; then
    sudo dnf install -y $package_name 2>/dev/null || sudo yum install -y $package_name
    if [ $? -ne 0 ]; then
      if [ "$package_name" = "terraform" ]; then
        echo -e "${YELLOW}Instaluję Terraform z binarki...${NC}"
        T_VERSION="1.8.5"
        ARCH=$(uname -m)
        case "$ARCH" in
          x86_64) ARCH=amd64 ;;
          aarch64) ARCH=arm64 ;;
        esac
        OS=$(uname | tr '[:upper:]' '[:lower:]')
        URL="https://releases.hashicorp.com/terraform/${T_VERSION}/terraform_${T_VERSION}_${OS}_${ARCH}.zip"
        TMPFILE=$(mktemp)
        echo -e "Pobieram Terraform z ${URL}..."
        echo "[DEBUG] Testuję usługę przez curl..."; curl -o "$TMPFILE" -fsSL "$URL" && unzip -o "$TMPFILE" -d /tmp && sudo mv /tmp/terraform /usr/local/bin/ && rm "$TMPFILE" || return 1
      elif [ "$package_name" = "python3-pip" ]; then
        echo -e "${YELLOW}Instaluję pip przez get-pip.py...${NC}"
        echo "[DEBUG] Testuję usługę przez curl..."; curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
        python3 /tmp/get-pip.py --user || return 1
        rm /tmp/get-pip.py
      else
        echo -e "${RED}Nie można zainstalować $package_name!${NC}"
        return 1
      fi
    fi
  else
    echo -e "${RED}Nieobsługiwany system! Zainstaluj $package_name ręcznie.${NC}"
    return 1
  fi
  echo -e "${GREEN}Pakiet $package_name został zainstalowany.${NC}"
  return 0
}
