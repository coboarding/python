#!/bin/bash
# dev.sh - Testuje każdy serwis dockerowy osobno i uruchamia testy Ansible healthcheck
# dev.sh - Testuje każdy serwis dockerowy osobno i uruchamia testy Ansible healthcheck
# Każdy kontener uruchamiany jest po kolei, niezależnie od wyniku poprzedniego.
# Kolorowanie logów + logowanie do pliku dev.log

GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
RED="$(tput setaf 1)"
NC="$(tput sgr0)"
LOGFILE="dev.log"

SERVICES=(llm-orchestrator browser-service web-interface novnc video-chat web-terminal)

for SERVICE in "${SERVICES[@]}"; do
  echo -e "\n===============================" | tee -a "$LOGFILE"
  echo    "[DEV] TESTUJĘ SERWIS: $SERVICE" | tee -a "$LOGFILE"
  echo    "===============================" | tee -a "$LOGFILE"
  if bash containers/test-service.sh "$SERVICE" 2>&1 | tee -a "$LOGFILE"; then
    echo -e "${GREEN}[INFO] Kontener $SERVICE działa lub test przeszedł.${NC}" | tee -a "$LOGFILE"
  else
    echo -e "${YELLOW}[WARN] Kontener $SERVICE nie działa lub test nie przeszedł! Kontynuuję dalej.${NC}" | tee -a "$LOGFILE"
  fi

  # Po każdym teście uruchom healthcheck Ansible tylko dla tego serwisu
  if [ -f "infra/ansible/playbook.yml" ]; then
    case $SERVICE in
      llm-orchestrator)
        ENDPOINT='[{"name":"llm-orchestrator","url":"http://localhost:5000/health","status":200}]';;
      browser-service)
        ENDPOINT='[{"name":"browser-service","url":"http://localhost:3000/health","status":200}]';;
      web-interface)
        ENDPOINT='[{"name":"web-interface","url":"http://localhost:8080/","status":200}]';;
      novnc)
        ENDPOINT='[{"name":"novnc","url":"http://localhost:6080/","status":200}]';;
      video-chat)
        ENDPOINT='[{"name":"video-chat","url":"http://localhost:8443/","status":200}]';;
      web-terminal)
        ENDPOINT='[{"name":"web-terminal","url":"http://localhost:8081/","status":200}]';;
      *)
        ENDPOINT='[]';;
    esac
    if [ "$ENDPOINT" != "[]" ]; then
      echo "[DEV] Ansible E2E healthcheck dla $SERVICE..." | tee -a "$LOGFILE"
      if ansible-playbook infra/ansible/playbook.yml --extra-vars "endpoints=$ENDPOINT" 2>&1 | tee -a "$LOGFILE"; then
        echo -e "${GREEN}[INFO] Ansible healthcheck OK dla $SERVICE.${NC}" | tee -a "$LOGFILE"
      else
        echo -e "${YELLOW}[WARN] Ansible E2E healthcheck failed for $SERVICE! Kontynuuję dalej.${NC}" | tee -a "$LOGFILE"
      fi
    else
      echo -e "${YELLOW}[INFO] Pomijam healthcheck Ansible dla $SERVICE (brak endpointu).${NC}" | tee -a "$LOGFILE"
    fi
  else
    echo -e "${YELLOW}[WARN] Brak infra/ansible/playbook.yml - pomijam testy Ansible.${NC}" | tee -a "$LOGFILE"
  fi
  echo "[DEV] ZAKOŃCZONO TESTY SERWISU: $SERVICE" | tee -a "$LOGFILE"
  echo "===============================\n" | tee -a "$LOGFILE"
done

echo "[DEV] Wszystkie testy serwisów zakończone." | tee -a "$LOGFILE"
