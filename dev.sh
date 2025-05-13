#!/bin/bash
# dev.sh - Testuje każdy serwis dockerowy osobno i uruchamia testy Ansible healthcheck
set -e

SERVICES=(llm-orchestrator browser-service web-interface novnc video-chat web-terminal)

for SERVICE in "${SERVICES[@]}"; do
  echo -e "\n==============================="
  echo    "[DEV] TESTUJĘ SERWIS: $SERVICE"
  echo    "==============================="
  bash containers/test-service.sh "$SERVICE"

  # Po każdym teście uruchom healthcheck Ansible tylko dla tego serwisu
  if [ -f "infra/ansible/playbook.yml" ]; then
    case $SERVICE in
      llm-orchestrator)
        ENDPOINT="[{name:'llm-orchestrator',url:'http://localhost:5000/health',status:200}]";;
      browser-service)
        ENDPOINT="[{name:'browser-service',url:'http://localhost:3000/health',status:200}]";;
      web-interface)
        ENDPOINT="[{name:'web-interface',url:'http://localhost:8080/',status:200}]";;
      novnc)
        ENDPOINT="[{name:'novnc',url:'http://localhost:6080/',status:200}]";;
      video-chat)
        ENDPOINT="[{name:'video-chat',url:'http://localhost:8443/',status:200}]";;
      web-terminal)
        ENDPOINT="[{name:'web-terminal',url:'http://localhost:8081/',status:200}]";;
      *)
        ENDPOINT="[]";;
    esac
    echo "[DEV] Ansible E2E healthcheck dla $SERVICE..."
    ansible-playbook infra/ansible/playbook.yml --extra-vars "endpoints=$ENDPOINT" || echo "[WARN] Ansible E2E healthcheck failed for $SERVICE!"
  else
    echo "[WARN] Brak infra/ansible/playbook.yml - pomijam testy Ansible."
  fi
  echo "[DEV] ZAKOŃCZONO TESTY SERWISU: $SERVICE"
  echo "===============================\n"
done

echo "[DEV] Wszystkie testy serwisów zakończone."
