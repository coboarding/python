# coBoarding

coBoarding to kompleksowy, kontenerowy system do automatycznego wypełniania formularzy rekrutacyjnych, kładący nacisk na prywatność, elastyczność oraz wsparcie wielojęzyczne.

## Główne cechy
- Architektura oparta na Docker (moduły: browser-service, llm-orchestrator, novnc, web-interface)
- 100% lokalne przetwarzanie danych (prywatność)
- Wykrywanie sprzętu (GPU/CPU, RAM) i automatyczny dobór modelu LLM
- Wielojęzyczność (PL, DE, EN) z automatyczną detekcją
- Nowoczesny web UI z HTTPS i sterowaniem głosowym
- Automatyczna generacja pipelines dla portali pracy
- Wizualizacja procesu przez noVNC
- Integracja z menedżerami haseł (Bitwarden, PassBolt)
- Kompletne środowisko testowe

## Szybki start

```bash
git clone ...
cd coBoarding
bash run.sh  # lub ./run.ps1 na Windows
```

Pierwsze uruchomienie automatycznie skonfiguruje środowisko (venv, zależności, kontenery).

## Struktura kontenerów
- **browser-service**: Selenium, Chrome/Firefox
- **llm-orchestrator**: API do analizy formularzy, wykrywanie sprzętu, zarządzanie modelami LLM (torch, transformers, langchain)
- **novnc**: Podgląd przeglądarki
- **web-interface**: React, HTTPS, Web Speech API

## Weryfikacja wdrożenia
- Czy docker-compose.yml zawiera wszystkie kontenery i wolumeny?
- Czy skrypty inicjalizacyjne wykrywają sprzęt?
- Czy web-interface jest dostępny przez HTTPS?
- Czy API llm-orchestrator działa?
- Czy testy przechodzą dla przykładowych formularzy?

## Scenariusze testowe
- Wypełnianie prostego i złożonego formularza
- Test wielojęzyczności
- Test podglądu przez noVNC
- Test integracji z menedżerem haseł

## Dokumentacja
Szczegółowe prompty i pytania weryfikacyjne znajdziesz w pliku `TODO.txt`.

## Kontakt i wsparcie
Projekt open-source. Wszelkie zgłoszenia błędów i propozycje zmian prosimy kierować przez Issues na GitHub.