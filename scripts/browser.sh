# Funkcje do otwierania przeglądarki i logów
open_browser() {
  local url="$1"
  echo -e "${GREEN}Otwieram przeglądarkę: $url${NC}"
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v xdg-open &>/dev/null; then
      xdg-open "$url" &>/dev/null &
    elif command -v gnome-open &>/dev/null; then
      gnome-open "$url" &>/dev/null &
    else
      echo -e "${YELLOW}Nie można automatycznie otworzyć przeglądarki. Otwórz ręcznie URL: $url${NC}"
      return 1
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    open "$url" &>/dev/null &
  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    start "" "$url" &>/dev/null &
  else
    echo -e "${YELLOW}Nieobsługiwany system. Otwórz ręcznie URL: $url${NC}"
    return 1
  fi
  sleep 3
  return 0
}

view_logs_in_browser() {
  local logs_url="http://localhost:${MONITOR_PORT:-8082}/logs"
  echo -e "${GREEN}Otwieram widok logów w przeglądarce...${NC}"
  open_browser "$logs_url"
  return 0
}
