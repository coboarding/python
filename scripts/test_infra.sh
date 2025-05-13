#!/bin/bash

# Test health endpoints for all main containers
set -e

function test_endpoint() {
  local name="$1"
  local url="$2"
  echo -n "Testing $name ($url)... "
  if curl -s --max-time 5 "$url" | grep -q 'ok'; then
    echo "[OK]"
  else
    echo "[FAIL]"
    exit 1
  fi
}

test_endpoint "llm-orchestrator" "http://localhost:5000/health"
# Dodaj tu kolejne testy dla innych usług, np.:
# test_endpoint "browser-service" "http://localhost:5001/health"
# test_endpoint "webapp" "http://localhost:8080/health"

echo "All infrastructure tests passed!"
