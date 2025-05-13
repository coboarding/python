# Funkcja do uruchamiania monitora
start_monitor() {
  echo -e "${GREEN}Uruchamianie monitora coboarding...${NC}"
  local MONITOR_PORT=${MONITOR_PORT:-8082}
  local MONITOR_RUNNING=false
  if lsof -i :$MONITOR_PORT -t >/dev/null 2>&1; then
    if [ -f monitor.pid ] && ps -p $(cat monitor.pid) >/dev/null 2>&1; then
      echo -e "${YELLOW}Monitor już działa na porcie $MONITOR_PORT (PID: $(cat monitor.pid))${NC}"
      MONITOR_RUNNING=true
    else
      echo -e "${YELLOW}Port $MONITOR_PORT jest zajęty przez inny proces.${NC}"
      echo -e "${YELLOW}Próbuję znaleźć wolny port...${NC}"
      local PORT=8081
      while lsof -i :$PORT -t >/dev/null 2>&1 && [ $PORT -lt 8100 ]; do
        ((PORT++))
      done
      if [ $PORT -lt 8100 ]; then
        echo -e "${YELLOW}Znaleziono wolny port: $PORT${NC}"
        MONITOR_PORT=$PORT
      else
        echo -e "${RED}Nie można znaleźć wolnego portu!${NC}"
        echo -e "${RED}Zatrzymaj istniejące procesy na portach 8082-8099 i spróbuj ponownie.${NC}"
        return 1
      fi
    fi
  fi
  if [ "$MONITOR_RUNNING" = false ]; then
    echo -e "Instalacja zależności monitora..."
    pip install -q -r monitor/requirements.txt || {
      echo -e "${RED}Nie można zainstalować zależności monitora!${NC}"
      return 1
    }
    echo -e "${GREEN}Uruchamianie monitora na porcie ${MONITOR_PORT:-8082}...${NC}"
    say "Uruchamianie monitora na porcie ${MONITOR_PORT:-8082}."
    (cd monitor && echo "[DEBUG] Uruchamiam skrypt Python..."; python app.py > ../monitor.log 2>&1) &
    MONITOR_PID=$!
    echo $MONITOR_PID > monitor.pid
    sleep 2
    if ! ps -p $MONITOR_PID >/dev/null 2>&1; then
      echo -e "${RED}Nie udało się uruchomić monitora!${NC}"
      echo -e "${YELLOW}Wyciąg z logu monitora:${NC}"
      tail -20 monitor.log 2>/dev/null || echo -e "${RED}Brak pliku monitor.log${NC}"
      return 1
    fi
  fi
  if ! curl -s -f http://localhost:${MONITOR_PORT:-8082}/health >/dev/null 2>&1; then
    echo -e "${RED}Monitor nie odpowiada na port ${MONITOR_PORT:-8082}!${NC}"
    echo -e "${YELLOW}Wyciąg z logu monitora:${NC}"
    tail -20 monitor.log 2>/dev/null || echo -e "${RED}Brak pliku monitor.log${NC}"
    return 1
  fi
  local monitor_url="http://localhost:${MONITOR_PORT:-8082}"
  echo -e "${GREEN}Monitor uruchomiony na: ${monitor_url}${NC}"
  return 0
}
