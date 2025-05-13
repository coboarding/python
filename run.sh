#!/bin/bash

# Load functions and colors
source "$(dirname "$0")/scripts/colors.sh"
source "$(dirname "$0")/scripts/tts.sh"
source "$(dirname "$0")/scripts/browser.sh"

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

# Load helper functions
source "$(dirname "$0")/scripts/install_package.sh"
source "$(dirname "$0")/scripts/start_monitor.sh"
source "$(dirname "$0")/scripts/install_requirements.sh"

# Function to open browser
open_browser() {
  local url="$1"
  echo -e "${GREEN}Opening browser: $url${NC}"

  # Detect operating system and open URL in browser
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v xdg-open &>/dev/null; then
      xdg-open "$url" &>/dev/null &
    elif command -v gnome-open &>/dev/null; then
      gnome-open "$url" &>/dev/null &
    else
      echo -e "${YELLOW}Cannot automatically open browser. Please open URL manually: $url${NC}"
      return 1
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    open "$url" &>/dev/null &
  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    start "" "$url" &>/dev/null &
  else
    echo -e "${YELLOW}Unsupported system. Open URL manually: $url${NC}"
    return 1
  fi

  # Give browser time to open
  sleep 3
  return 0
}

# Function to display logs view in browser
view_logs_in_browser() {
  local logs_url="http://localhost:${MONITOR_PORT:-8082}/logs"
  echo -e "${GREEN}Opening logs view in browser...${NC}"
  open_browser "$logs_url"
  return 0
}

# Function to install packages
install_package() {
  local package_name="$1"
  local command_name="${2:-$package_name}"

  if command -v "$command_name" &>/dev/null; then
    echo -e "${GREEN}Package $package_name is already installed.${NC}"
    return 0
  fi

  echo -e "${YELLOW}Installing package $package_name...${NC}"
  # Only announce important installations via TTS
  if [[ "$package_name" == "docker" || "$package_name" == "terraform" ]]; then
    say "Installing ${package_name}."
  fi

  # Choose appropriate package manager
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq && sudo apt-get install -y "$package_name" || {
        # Handle alternative installation methods
        if [ "$package_name" = "terraform" ]; then
          # Alternative installation of Terraform via binary download
          echo -e "${YELLOW}Installing Terraform from binary...${NC}"
          say "Installing Terraform from binary."
          T_VERSION="1.8.5"
          ARCH=$(uname -m)
          case "$ARCH" in
            x86_64) ARCH=amd64 ;;
            aarch64) ARCH=arm64 ;;
          esac
          OS=$(uname | tr '[:upper:]' '[:lower:]')
          URL="https://releases.hashicorp.com/terraform/${T_VERSION}/terraform_${T_VERSION}_${OS}_${ARCH}.zip"
          TMPFILE=$(mktemp)
          echo -e "Downloading Terraform from ${URL}..."
          echo "[DEBUG] Testing service via curl..."; curl -o "$TMPFILE" -fsSL "$URL" && unzip -o "$TMPFILE" -d /tmp && sudo mv /tmp/terraform /usr/local/bin/ && rm "$TMPFILE" || {
            say "Error installing Terraform."
            return 1
          }
        elif [ "$package_name" = "python3-pip" ]; then
          # Alternative installation of pip via get-pip.py
          echo -e "${YELLOW}Installing pip via get-pip.py...${NC}"
          echo "[DEBUG] Testing service via curl..."; curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
          python3 /tmp/get-pip.py --user || {
            say "Error installing Python pip."
            return 1
          }
          rm /tmp/get-pip.py
        else
          echo -e "${RED}Cannot install $package_name!${NC}"
          say "Cannot install ${package_name}."
          return 1
        fi
      }
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y "$package_name" || return 1
    elif command -v yum &>/dev/null; then
      sudo yum install -y "$package_name" || return 1
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm "$package_name" || return 1
    else
      echo -e "${RED}Unsupported package manager! Install $package_name manually.${NC}"
      say "Unsupported package manager. Please install ${package_name} manually."
      return 1
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      brew install "$package_name" || return 1
    else
      echo -e "${YELLOW}Homebrew is not installed. Installing...${NC}"
      say "Installing Homebrew."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        say "Error installing Homebrew."
        return 1
      }
      brew install "$package_name" || {
        say "Error installing ${package_name}."
        return 1
      }
    fi
  else
    echo -e "${RED}Unsupported system! Install $package_name manually.${NC}"
    say "Unsupported system. Please install ${package_name} manually."
    return 1
  fi

  echo -e "${GREEN}Package $package_name has been installed.${NC}"
  return 0
}

# Start monitor as background process
start_monitor() {
  echo -e "${GREEN}Starting coboarding monitor...${NC}"

  # Check if monitor is already running
  local MONITOR_PORT=${MONITOR_PORT:-8082}
  local MONITOR_RUNNING=false

  # Check if monitor port is in use
  if lsof -i :$MONITOR_PORT -t >/dev/null 2>&1; then
    # Check if it's our monitor with PID
    if [ -f ./monitor.pid ] && ps -p $(cat ./monitor.pid) >/dev/null 2>&1; then
      echo -e "${YELLOW}Monitor already running on port $MONITOR_PORT (PID: $(cat ./monitor.pid))${NC}"
      MONITOR_RUNNING=true
    else
      echo -e "${YELLOW}Port $MONITOR_PORT is in use by another process.${NC}"
      say "Monitor port is in use. Trying to find a free port."
      echo -e "${YELLOW}Trying to find free port...${NC}"

      # Find free port
      local PORT=8081
      while lsof -i :$PORT -t >/dev/null 2>&1 && [ $PORT -lt 8100 ]; do
        ((PORT++))
      done

      if [ $PORT -lt 8100 ]; then
        echo -e "${YELLOW}Found free port: $PORT${NC}"
        say "Found free port: ${PORT}"
        MONITOR_PORT=$PORT
      else
        echo -e "${RED}Cannot find free port!${NC}"
        echo -e "${RED}Stop existing processes on ports 8082-8099 and try again.${NC}"
        say "Error: Cannot find free port. Please stop existing processes on ports 8082 to 8099 and try again."
        return 1
      fi
    fi
  fi

  # Start monitor if not running
  if [ "$MONITOR_RUNNING" = false ]; then
    # Install dependencies
    echo -e "Installing monitor dependencies..."
    pip install -q -r ./monitor/requirements.txt || {
      echo -e "${RED}Cannot install monitor dependencies!${NC}"
      say "Error installing monitor dependencies."
      return 1
    }

    # Start monitor in background
    echo -e "${GREEN}Starting monitor on port ${MONITOR_PORT:-8082}...${NC}"
    say "Starting monitor on port ${MONITOR_PORT:-8082}."
    (cd monitor && python app.py > ../monitor.log 2>&1) &
    MONITOR_PID=$!

    # Save PID to file
    echo $MONITOR_PID > ./monitor.pid

    # Check if process started correctly
    sleep 2
    if ! ps -p $MONITOR_PID >/dev/null 2>&1; then
      echo -e "${RED}Failed to start monitor!${NC}"
      say "Error: Failed to start monitor."
      echo -e "${YELLOW}Monitor log excerpt:${NC}"
      tail -20 monitor.log 2>/dev/null || echo -e "${RED}No monitor.log file${NC}"
      return 1
    fi
  fi

  # Final verification that monitor is actually working
  if ! curl -s -f http://localhost:${MONITOR_PORT:-8082}/health >/dev/null 2>&1; then
    echo -e "${RED}Monitor not responding on port ${MONITOR_PORT:-8082}!${NC}"
    say "Error: Monitor not responding on port ${MONITOR_PORT}."
    echo -e "${YELLOW}Monitor log excerpt:${NC}"
    tail -20 monitor.log 2>/dev/null || echo -e "${RED}No monitor.log file${NC}"
    return 1
  fi

  # Open browser
  local monitor_url="http://localhost:${MONITOR_PORT:-8082}"
  echo -e "${GREEN}Monitor running at: ${monitor_url}${NC}"

  # No need to automatically open browser, user can do it manually
  # or choose "--logs" option to see logs view
  return 0
}

# Install required system packages
install_requirements() {
  # List of dependencies
  install_package docker docker
  install_package docker-compose docker-compose
  install_package terraform terraform
  install_package ansible ansible
  install_package python3-pip pip3

  # Ensure pip is installed
  if ! command -v pip3 >/dev/null 2>&1; then
    echo -e "${RED}Pip is still not installed! Try installing python3-pip manually.${NC}"
    say "Error: Pip is not installed. Trying to install python3-pip."
    install_package python3-pip pip3
  fi

  return 0
}

# Main function to run the system
main() {
  # --- Create and activate virtual environment ---
  if [ ! -d "venv" ]; then
    echo "[coBoarding] Creating Python virtual environment (Python 3.11 recommended)..."
    say "Creating Python virtual environment."
    if command -v python3.11 &> /dev/null; then
      python3.11 -m venv venv
    else
      python3 -m venv venv
    fi
    source venv/bin/activate
    pip install --upgrade pip
    echo "[DEBUG] Installing dependencies from requirements.txt..."
    pip install -r requirements.txt || {
      say "Error installing dependencies."
      echo "[coBoarding] Error installing dependencies. Check Python version and requirements.txt."
      exit 1
    }
    # Ensure beautifulsoup4 is installed for all test/e2e scenarios
    pip show beautifulsoup4 >/dev/null 2>&1 || pip install beautifulsoup4 || echo "[coBoarding] Error installing dependencies. Check Python version and requirements.txt."
  else
    source venv/bin/activate
    echo "[coBoarding] Activated Python virtual environment."
  fi

  # 1. Check if environment is already initialized (e.g. volumes/models directory and docker-compose.yml file)
  if [ ! -d "volumes/models" ] || [ ! -f "docker-compose.yml" ]; then
    echo "[coBoarding] Environment not initialized. Starting installation..."
    say "Environment not initialized. Starting installation."
    echo "[DEBUG] Checking environment and dependencies..."
    if [ -f ./install.sh ]; then
      bash ./install.sh
    elif [ -f ./setup-all.sh ]; then
      bash ./setup-all.sh
    elif [ -f ./coboarding.sh ]; then
      bash ./coboarding.sh
    else
      echo "No installation script (install.sh/setup-all.sh/init.sh) found! Aborted."
      say "Error: No installation script found."
      exit 1
    fi
  else
    echo "[coBoarding] Environment already configured. Starting environment..."
  fi

  # 2. Install required packages
  install_requirements

  # 3. Start monitor before other services
  start_monitor

  # 4. Add option to display logs in browser
  if [ "$1" == "--logs" ] || [ "$1" == "-l" ]; then
    view_logs_in_browser
    exit 0
  fi

  # 5. Start docker-compose services
  if [ -f docker-compose.yml ]; then
    echo -e "${GREEN}Starting services with Docker Compose...${NC}"
    say "Starting Docker Compose services."
    docker-compose up --build -d || {
      say "Error starting Docker Compose services."
      echo -e "${RED}Docker Compose failed to start!${NC}"
      echo -e "${YELLOW}Check Docker Compose logs with: docker-compose logs${NC}"
      exit 1
    }
    echo "[DEBUG] Docker Compose services started..."

    # --- Test container services ---
    echo "[coBoarding] Testing services..."
    # Test llm-orchestrator
    if [ -f containers/llm-orchestrator/test.sh ]; then
      echo "[DEBUG] Testing llm-orchestrator..."
      bash containers/llm-orchestrator/test.sh || {
        echo "[coBoarding] llm-orchestrator: test failed."
        say "Warning: llm-orchestrator test failed."
      }
    fi
    # Test browser-service
    if [ -f containers/browser-service/test.sh ]; then
      bash containers/browser-service/test.sh || {
        echo "[coBoarding] browser-service: test failed."
        say "Warning: browser-service test failed."
      }
    fi
    # Test test-forms-server
    if [ -f containers/test-forms-server/test.sh ]; then
      bash containers/test-forms-server/test.sh || {
        echo "[coBoarding] test-forms-server: test failed."
        say "Warning: test-forms-server test failed."
      }
    fi
    # Test web-interface
    if [ -f containers/web-interface/test.sh ]; then
      bash containers/web-interface/test.sh || {
        echo "[coBoarding] web-interface: test failed."
        say "Warning: web-interface test failed."
      }
    fi

    # Access information
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}\n============================================="
      echo -e "[coBoarding] System has been started!"
      echo -e "---------------------------------------------"
      echo -e "- Web:      http://localhost:8082"
      echo -e "- Terminal: http://localhost:8081"
      echo -e "- Overview: http://localhost:8082"
      echo -e "=============================================${NC}\n"
      say "System has been started successfully."
    else
      echo -e "${RED}\n============================================="
      echo -e "[coBoarding] Error starting environment!"
      echo -e "---------------------------------------------"
      echo -e "- Check container logs: docker-compose logs --tail=40"
      echo -e "- Check monitor log: tail -40 monitor.log"
      echo -e "- Common causes: no free ports, incorrect .env configuration, missing dependencies or errors in requirements.txt"
      echo -e "=============================================${NC}\n"
      say "Error starting environment. Please check the logs."
      exit 1
    fi
  else
    echo -e "${RED}No docker-compose.yml file! Environment was not properly initialized.${NC}"
    say "Error: No docker-compose.yml file found."
    exit 1
  fi
}

# Run main function with arguments
main "$@"

# --- TEST INFRASTRUCTURE ---
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/scripts/test_infra.sh" ]; then
  echo "\n=== Sprawdzanie infrastruktury po starcie kontenerów ==="
  bash "$SCRIPT_DIR/scripts/test_infra.sh"
else
  echo "test_infra.sh nie znaleziony, pomiń test infrastruktury."
fi