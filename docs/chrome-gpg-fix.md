# Instalacja Google Chrome w kontenerze (nowy sposób klucza GPG)

Na nowych systemach (np. Ubuntu 24.04+) stary sposób pobierania klucza GPG Google Chrome nie działa. Użyj poniższego fragmentu w Dockerfile:

```dockerfile
RUN set -eux; \
    mkdir -p /etc/apt/keyrings; \
    wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/keyrings/google-linux-signing-key.gpg; \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-linux-signing-key.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends google-chrome-stable; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*
```

Ten sposób jest już użyty w `containers/browser-service/Dockerfile`.

## Typowe błędy
- `NO_PUBKEY ...` lub błąd GPG przy apt update: oznacza, że klucz nie został poprawnie dodany lub użyto starej metody.

## Linki
- [Oficjalna dokumentacja Google Chrome](https://www.google.com/linuxrepositories/)
