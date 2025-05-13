# coBoarding – Dokumentacja Deweloperska

## Spis treści
- [Architektura systemu](#architektura-systemu)
- [Szybki start dla dewelopera](#szybki-start-dla-dewelopera)
- [Struktura repozytorium](#struktura-repozytorium)
- [Opis usług i API](#opis-uslug-i-api)
- [Integracja z bazą i email](#integracja-z-baza-i-email)
- [Testowanie i debugowanie](#testowanie-i-debugowanie)
- [Wskazówki bezpieczeństwa](#wskazowki-bezpieczenstwa)
- [FAQ dla deweloperów](#faq-dla-deweloperow)

---

## Architektura systemu
coBoarding to architektura mikroserwisowa oparta o Dockera, z usługami: browser-service, llm-orchestrator, web-interface, novnc i innymi.

## Szybki start dla dewelopera
1. Sklonuj repozytorium i przejdź do katalogu `python`.
2. Skonfiguruj `.env` według szablonu.
3. Uruchom środowisko przez `docker compose up` lub skrypty `dev.sh`/`run.sh`.

## Struktura repozytorium
- `containers/` – Dockerfile i kod usług
- `infra/` – ansible, playbooki
- `model-configs/`, `data/`, `output/` – modele, dane, wyniki

## Opis usług i API
- Szczegóły endpointów: `/fill-form`, `/get-email-token`, `/health`, `/api/health`
- Przykłady requestów i odpowiedzi w dokumentacji kodu

## Integracja z bazą i email
- Wysyłka emaili przez `send_email_utils.py` (SMTP, załączniki)
- Pobieranie kodów przez `email_utils.py` (IMAP)
- Logowanie statusów do SQLite (`form_status.db`)

## Testowanie i debugowanie
- Testy endpointów: `scripts/test_infra.sh`
- Logi kontenerów: `docker compose logs <usługa>`
- Debugowanie SMTP/IMAP: zmienne środowiskowe `.env`

## Wskazówki bezpieczeństwa
- Nigdy nie commituj danych z `.env`!
- Używaj kont testowych do developmentu

## FAQ dla deweloperów
**Jak dodać nowy endpoint?**
Dodaj funkcję w odpowiednim pliku API, zarejestruj trasę w Flask.

**Jak dodać nową usługę?**
Dodaj nowy katalog w `containers/` i Dockerfile, zarejestruj w docker-compose.
