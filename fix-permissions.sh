#!/bin/bash
# Skrypt do naprawy uprawnień w całym projekcie coBoarding
# Użycie: bash fix-permissions.sh [opcjonalnie: użytkownik]

PROJECT_ROOT="$(dirname "$0")"
USER_TO_FIX="${1:-$USER}"

# Zmień właściciela wszystkich plików i katalogów na wybranego użytkownika
echo "[INFO] Zmieniam właściciela wszystkich plików na $USER_TO_FIX..."
sudo chown -R "$USER_TO_FIX":"$USER_TO_FIX" "$PROJECT_ROOT"

# Ustaw prawa do zapisu dla właściciela wszędzie
echo "[INFO] Ustawiam prawa do zapisu dla właściciela..."
find "$PROJECT_ROOT" -type d -exec chmod u+rwx {} +
find "$PROJECT_ROOT" -type f -exec chmod u+rw {} +

# Ustaw prawo do wykonywania dla wszystkich skryptów .sh i .py
echo "[INFO] Ustawiam prawo do wykonywania dla .sh i .py..."
find "$PROJECT_ROOT" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod u+x {} +

# Dodatkowe zabezpieczenie: blokada zapisu dla grupy i innych (opcjonalnie)
# find "$PROJECT_ROOT" -type f -exec chmod go-w {} +
# find "$PROJECT_ROOT" -type d -exec chmod go-w {} +

echo "[OK] Uprawnienia w projekcie zostały naprawione."
