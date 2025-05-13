# Funkcja do mówienia komunikatów głosowych (TTS)
say() {
  if command -v espeak >/dev/null 2>&1; then
    espeak "$1" 2>/dev/null &
  else
    echo "[WARN] espeak (TTS) nie jest zainstalowany. Komunikaty głosowe są wyłączone."
  fi
}
