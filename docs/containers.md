# Struktura kontenerów

System coBoarding składa się z kilku kontenerów Docker, które komunikują się przez sieć lokalną:

| Kontener             | Port    | Opis                                      |
|----------------------|---------|-------------------------------------------|
| browser-service      | 8080    | Automatyzacja przeglądarki Chrome         |
| llm-orchestrator     | 5000    | Backend AI, API do wypełniania formularzy |
| novnc                | 8083    | Wizualizacja procesu przez przeglądarkę   |
| web-interface        | 8082    | Interfejs użytkownika (UI)                |
| web-terminal         | 8081    | Terminal przez przeglądarkę               |
| test-forms-server    | 8090    | Serwer formularzy testowych (E2E)         |
| voice-interface      | 5001    | API głosowe                               |

## Schemat

```
[UI] <---> [web-interface] <---> [llm-orchestrator] <---> [browser-service]
                                        |
                                   [test-forms-server]
```

## Pliki
- `docker-compose.yml` – główna konfiguracja
- `Dockerfile` – definicje obrazów

Przejdź do [Testy end-to-end](e2e-tests.md) lub [FAQ](faq.md).
