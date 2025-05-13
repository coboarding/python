#!/bin/bash

# Skrypt do testowania API LLM
# Autor: Tom
# Data: 2025-05-13

echo "=== Testy API LLM ==="

API_PORT=${API_PORT:-5000}
API_URL="http://localhost:$API_PORT"
TESTS_PASSED=0
TESTS_FAILED=0

# Funkcja do testowania endpointu
test_endpoint() {
  local endpoint=$1
  local method=${2:-GET}
  local data=$3
  local expected_status=${4:-200}
  
  echo -n "Test $endpoint ($method): "
  
  if [ "$method" == "GET" ]; then
    response=$(curl -s -o /dev/null -w "%{http_code}" $API_URL$endpoint)
  else
    response=$(curl -s -o /dev/null -w "%{http_code}" -X $method -H "Content-Type: application/json" -d "$data" $API_URL$endpoint)
  fi
  
  if [ "$response" == "$expected_status" ]; then
    echo "OK (status $response)"
    TESTS_PASSED=$((TESTS_PASSED+1))
  else
    echo "BŁĄD (oczekiwano: $expected_status, otrzymano: $response)"
    TESTS_FAILED=$((TESTS_FAILED+1))
  fi
}

# Test 1: Endpoint zdrowia
test_endpoint "/api/health"

# Test 2: Endpoint generowania tekstu
test_endpoint "/api/generate" "POST" '{"prompt": "Hello, how are you?", "max_length": 50}' 200

# Test 3: Endpoint generowania z nieprawidłowymi danymi
test_endpoint "/api/generate" "POST" '{"invalid": "data"}' 400

# Test 4: Nieistniejący endpoint
test_endpoint "/api/nonexistent" "GET" "" 404

# Podsumowanie testów
echo -e "\n=== Podsumowanie testów ==="
echo "Testy udane: $TESTS_PASSED"
echo "Testy nieudane: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
  echo "Wszystkie testy zakończone sukcesem!"
  exit 0
else
  echo "Niektóre testy nie powiodły się. Sprawdź logi."
  exit 1
fi
