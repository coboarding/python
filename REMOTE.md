# Analiza rozwiązań VNC/RDP dla coboarding

Analizowa dostępnych rozwiązań, które zamieniają obraz sesji VNC/RDP na HTML i umożliwiają kontrolowanie ekranu w przeglądarce


## Najlepsze rozwiązania dla naszego projektu

### 1. noVNC

**Dlaczego pasuje do coboarding:**
- Jest już częściowo zintegrowany w naszym projekcie
- Lekki i open-source
- Działa bezpośrednio w przeglądarce bez dodatkowych pluginów
- Wykorzystuje WebSockety do komunikacji
- Doskonale integruje się z Dockerem
- Szeroka społeczność i aktywne wsparcie

**Implementacja:**
```
noVNC + websockify + TigerVNC (lub x11vnc)
```

### 2. Apache Guacamole

**Dlaczego warto rozważyć:**
- Obsługuje zarówno VNC, RDP i SSH w jednym rozwiązaniu
- Zapewnia wyższą jakość i wydajność niż podstawowy noVNC
- Architektura klient-serwer z serwerem proxy
- Możliwość skalowania dla wielu użytkowników
- Rozbudowane funkcje bezpieczeństwa

**Implementacja:**
```
Apache Guacamole + guacd + libguac + specyficzne biblioteki protokołów
```

## Porównanie rozwiązań dla coboarding

| Aspekt | noVNC | Apache Guacamole | xrdp + html5-client | NoMachine |
|--------|-------|------------------|-------------------|-----------|
| **Integracja z Docker** | ✅ Bardzo łatwa | ✅ Dobra | ⚠️ Średnia | ❌ Skomplikowana |
| **Wydajność** | ⚠️ Średnia | ✅ Dobra | ✅ Dobra | ✅ Bardzo dobra |
| **Złożoność implementacji** | ✅ Niska | ⚠️ Średnia | ⚠️ Średnia | ❌ Wysoka |
| **Obsługa protokołów** | ❌ Tylko VNC | ✅ VNC, RDP, SSH | ⚠️ Głównie RDP | ✅ Własny protokół NX, RDP, VNC |
| **Jakość obrazu** | ⚠️ Średnia | ✅ Dobra | ✅ Dobra | ✅ Bardzo dobra |
| **Przenośność** | ✅ Wysoka | ✅ Wysoka | ⚠️ Średnia | ❌ Niska |
| **Zgodność z naszą architekturą** | ✅ Wysoka | ✅ Dobra | ⚠️ Średnia | ❌ Niska |

## Rekomendowana implementacja

Biorąc pod uwagę naszą architekturę opartą na Dockerze i wymagania coboarding, rekomendujemy **rozszerzenie obecnego rozwiązania noVNC** z dodatkowymi optymalizacjami lub **migrację do Apache Guacamole** dla lepszej wydajności i dodatkowych funkcji.

### Optymalizacja noVNC dla coboarding:

1. **Konfiguracja TigerVNC zamiast x11vnc** dla lepszej wydajności:

```dockerfile
# containers/browser-service/Dockerfile (fragment)
RUN apt-get update && apt-get install -y \
    tigervnc-standalone-server \
    tigervnc-common \
    # ... inne pakiety

# Zmieniona konfiguracja
COPY tigervnc-config/xstartup /root/.vnc/xstartup
RUN chmod +x /root/.vnc/xstartup
```

2. **Optymalizacja parametrów noVNC** dla lepszej wydajności:

```yaml
# docker-compose.yml (fragment)
novnc:
  image: theasp/novnc:latest
  container_name: novnc
  environment:
    - DISPLAY_WIDTH=1920
    - DISPLAY_HEIGHT=1080
    - NOVNC_OPTS=--compression=9 --quality=3
    - VNC_OPTS=-quality 80 -encodings "copyrect tight zrle hextile"
  ports:
    - "8080:8080"
```

3. **Dodanie warstwy caching i kompresji** przed noVNC:

```nginx
# containers/novnc/nginx.conf (nowy plik)
server {
    listen 80;
    
    # Kompresja GZIP
    gzip on;
    gzip_comp_level 5;
    gzip_types text/plain text/css application/javascript application/json;
    
    # Buforowanie
    location ~* \.(html|js|css|png|jpg|jpeg|gif|ico)$ {
        expires 7d;
        add_header Cache-Control "public, max-age=604800";
    }
    
    # Proxy do noVNC
    location / {
        proxy_pass http://127.0.0.1:6080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

### Alternatywnie: Implementacja Apache Guacamole

```dockerfile
# containers/guacamole/Dockerfile
FROM guacamole/guacamole:latest

ENV GUACD_HOSTNAME=guacd
ENV GUACD_PORT=4822
ENV POSTGRES_HOSTNAME=postgres
ENV POSTGRES_DATABASE=guacamole
ENV POSTGRES_USER=guacamole
ENV POSTGRES_PASSWORD=guacamole_password

EXPOSE 8080
```

```yaml
# docker-compose.yml (fragment)
services:
  guacd:
    image: guacamole/guacd
    container_name: guacd
    networks:
      - auto-form-filler-network
  
  guacamole:
    build:
      context: ./containers/guacamole
    container_name: guacamole
    depends_on:
      - guacd
      - postgres
    ports:
      - "8080:8080"
    networks:
      - auto-form-filler-network
  
  postgres:
    image: postgres:13
    container_name: postgres
    environment:
      - POSTGRES_DB=guacamole
      - POSTGRES_USER=guacamole
      - POSTGRES_PASSWORD=guacamole_password
    volumes:
      - ./volumes/guacamole-db:/var/lib/postgresql/data
    networks:
      - auto-form-filler-network
```

## Zalecane podejście

Biorąc pod uwagę obecny stan projektu coboarding, zalecam **dwuetapowe podejście**:

1. **Krótkoterminowo**: Zoptymalizować obecne rozwiązanie noVNC zgodnie z powyższymi wskazówkami, co wymaga minimalnych zmian w architekturze.

2. **Długoterminowo**: Rozważyć migrację do Apache Guacamole dla lepszej skalowalności, wydajności i obsługi wielu protokołów, szczególnie jeśli planowane jest rozszerzenie projektu.

Takie podejście pozwoli na szybką poprawę obecnego rozwiązania przy minimalnym nakładzie pracy, jednocześnie otwierając drogę do bardziej zaawansowanego rozwiązania w przyszłości.