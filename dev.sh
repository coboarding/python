#!/bin/bash
# dev.sh - Uruchamianie minimalnego stacka i testowanie llm-orchestrator
set -e

COMPOSE_FILE="docker-compose.minimal.yml"
TEST_DIR="test-examples"

# 1. Buduj i uruchom minimalny stack w tle
echo "[INFO] Buduję i uruchamiam stack ($COMPOSE_FILE)..."
docker-compose -f "$COMPOSE_FILE" up --build -d

# 2. Poczekaj aż llm-orchestrator będzie dostępny (port 5000)
echo "[INFO] Czekam na uruchomienie llm-orchestrator na porcie 5000..."
for i in {1..30}; do
  if curl -s http://localhost:5000/ > /dev/null; then
    echo "[INFO] llm-orchestrator jest dostępny."
    break
  fi
  sleep 2
done

# 3. Uruchom testy przykładowe (jeśli katalog i skrypt istnieją)
if [ -d "$TEST_DIR" ] && [ -f "$TEST_DIR/run_examples.py" ]; then
  echo "[INFO] Uruchamiam testy przykładowe..."
  docker-compose -f "$COMPOSE_FILE" run --rm test-client
else
  echo "[WARN] Brak katalogu $TEST_DIR lub pliku run_examples.py - pomijam testy."
fi

# 4. Wyświetl logi llm-orchestrator po testach
echo "[INFO] Logi llm-orchestrator po testach:"
docker-compose -f "$COMPOSE_FILE" logs llm-orchestrator

# 5. Zatrzymaj stack po zakończeniu
echo "[INFO] Zatrzymuję stack..."
docker-compose -f "$COMPOSE_FILE" down
