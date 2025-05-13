# coBoarding

coBoarding to kompleksowy, kontenerowy system do automatycznego wypełniania formularzy rekrutacyjnych, kładący nacisk na prywatność, elastyczność oraz wsparcie wielojęzyczne.

<!-- coBoarding SVG Logo -->
<p align="center">
  <svg width="420" height="100" viewBox="0 0 420 100" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect x="2" y="10" width="95" height="80" rx="18" fill="#3498db"/>
    <text x="50" y="65" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="42" fill="#fff" font-weight="bold">co</text>
    <rect x="110" y="10" width="295" height="80" rx="18" fill="#222"/>
    <text x="260" y="65" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="42" fill="#fff" font-weight="bold">Boarding</text>
  </svg>
</p>

---

## Szybki start

### Wymagania wstępne
- Python 3.11+ lub 3.12
- Docker i Docker Compose v2

### Pierwsze uruchomienie na Ubuntu/Debian

```bash
git clone https://github.com/coboarding/python.git
cd python
bash install.sh  # automatyczna instalacja zależności i Docker Compose v2 (Ubuntu/Debian)
bash run.sh      # lub ./run.ps1 na Windows
```

> **WAŻNE:** Skrypt install.sh jest przeznaczony dla systemów Ubuntu/Debian (używa apt-get). Na innych dystrybucjach Linuksa (np. Fedora, Arch, CentOS, Alpine) należy samodzielnie zainstalować: Python 3.11+, pip, venv, Docker i Docker Compose v2.

### Pierwsze uruchomienie na Windows

```powershell
git clone https://github.com/coboarding/python.git
cd python
./install.ps1   # instalacja zależności i środowiska (PowerShell)
./run.ps1       # uruchomienie systemu (PowerShell)
```

Pierwsze uruchomienie automatycznie skonfiguruje środowisko (venv, zależności, kontenery, Docker Compose v2).

---

[Diagramy architektury i przepływu znajdziesz w dokumentacji online (docs/architecture.md)](docs/architecture.md)

## Jak to działa

coBoarding automatyzuje proces aplikowania na portale pracy:
1. **Wykrywa sprzęt** i dobiera model LLM
2. **Konfiguruje środowisko** (Docker, Python, cache pip)
3. **Uruchamia Web UI** (HTTPS, obsługa głosowa, noVNC)
4. **Wykrywa język formularza** (PL, DE, EN)
5. **Integruje się z menedżerami haseł** (Bitwarden/PassBolt)
6. **Generuje pipeline** do wypełnienia formularza
7. **Testuje i wizualizuje** proces przez noVNC
8. **Automatycznie pobiera tokeny z emaila** (np. 2FA) przez endpoint `/get-email-token`
9. **Wysyła podsumowania i załączniki na email** po złożeniu formularza (`/fill-form`)
10. **Loguje statusy zgłoszeń do bazy SQLite** i umożliwia rozbudowę usług podsumowań

System działa na architekturze mikroserwisowej (browser-service, llm-orchestrator, web-interface, novnc), komunikujących się przez sieć Docker.

---

## Nowe funkcje (2025):

### Pobieranie tokenów z emaila
- Endpoint `/get-email-token` umożliwia automatyczne pobieranie kodów (np. 2FA) z wybranej skrzynki email (IMAP, regex, wsparcie Gmail/MS/PRV)
- Przykład użycia:
  ```json
  POST /get-email-token
  {
    "imap_server": "imap.gmail.com",
    "email_user": "twoj_email@gmail.com",
    "email_pass": "app_password",
    "search_subject": "Twój kod logowania",
    "token_regex": "\\b\\d{6}\\b"
  }
  ```

### Wysyłanie podsumowań i załączników na email
- Endpoint `/fill-form` przyjmuje opcjonalne pole `notify_email` – jeśli podane, po złożeniu formularza wysyła podsumowanie oraz załącznik (np. CV) na ten adres
- Wysyłka obsługiwana przez `send_email_utils.py` (SMTP, TLS, załączniki)

### Baza statusów zgłoszeń
- Wszystkie zgłoszenia/formularze są logowane do bazy SQLite (`form_status.db` lub ścieżka z `FORMS_DB_PATH`)
- Dane: URL formularza, email do powiadomień, kod odpowiedzi, szczegóły, timestamp
- Możliwość rozbudowy o osobną usługę raportowania/przeglądania statusów

### Konfiguracja środowiska przez pliki .env
- W katalogu głównym znajdziesz szablony:
  - `.env.gmail` – Gmail
  - `.env.ms` – Microsoft/Outlook
  - `.env.prv` – prywatny serwer
- Skopiuj wybrany plik do `.env` i uzupełnij swoimi danymi:
  ```env
  SMTP_SERVER=smtp.gmail.com
  SMTP_PORT=587
  SMTP_USER=twoj_email@gmail.com
  SMTP_PASS=twoje_haslo
  EMAIL_FROM=twoj_email@gmail.com
  IMAP_SERVER=imap.gmail.com
  IMAP_USER=twoj_email@gmail.com
  IMAP_PASS=twoje_haslo
  FORMS_DB_PATH=form_status.db
  ```
- **Uwaga!** Nie commituj swoich danych dostępowych do repozytorium!

### Pliki narzędziowe
- `send_email_utils.py` – obsługa SMTP, wysyłka emaili z załącznikami
- `email_utils.py` – pobieranie tokenów z emaila (IMAP, regex)

### Wskazówki bezpieczeństwa
- Przechowuj dane dostępowe wyłącznie w `.env` (nie commituj do repo!)
- W przypadku testów na publicznych serwerach używaj kont tymczasowych
- Możesz zmienić nazwę bazy statusów przez `FORMS_DB_PATH`

---

## Przykłady zastosowań
- Automatyczne wypełnianie formularzy rekrutacyjnych (LinkedIn, Pracuj.pl, StepStone, Indeed)
- Masowe aplikowanie na wiele ogłoszeń z zachowaniem prywatności
- Wsparcie dla osób z niepełnosprawnościami (obsługa głosowa)
- Integracja z własnym ATS
- Testowanie formularzy webowych

## Główne cechy
- Architektura oparta na Docker (browser-service, llm-orchestrator, novnc, web-interface)
- 100% lokalne przetwarzanie danych (prywatność)
- Wykrywanie sprzętu (GPU/CPU, RAM) i automatyczny dobór modelu LLM
- Wielojęzyczność (PL, DE, EN) z automatyczną detekcją
- Nowoczesny web UI z HTTPS i sterowaniem głosowym
- Automatyczna generacja pipelines dla portali pracy
- Wizualizacja procesu przez noVNC
- Integracja z menedżerami haseł (Bitwarden, PassBolt)
- Kompletne środowisko testowe

## Porównanie rozwiązań do automatycznego wypełniania formularzy

| Cecha | coBoarding (Nasze rozwiązanie)                        | Manus AI | rtrvr.ai | Magical |
|-------|-------------------------------------------------------|----------|----------|---------|
| **Model wdrożenia** | Self-hosted Docker                                    | SaaS / cloud-based | Rozszerzenie Chrome | Rozszerzenie Chrome |
| **Koszt** | Darmowy (open source)                                 | Od 39$/mies. za 3900 kredytów | 10$/mies. (~10,000 akcji) | Od 10$/mies. |
| **Wymagania systemowe** | Docker, min. 8GB RAM (więcej dla lepszych modeli LLM) | Tylko przeglądarka | Tylko przeglądarka | Tylko przeglądarka |
| **Przetwarzanie danych** | 100% lokalne                                          | W chmurze | W przeglądarce | W przeglądarce |
| **Wielojęzyczność** | PL/DE/EN z auto-detekcją                              | Wiele języków | Ograniczone | Ograniczone |
| **Interfejs użytkownika** | Web UI + noVNC + sterowanie głosowe                   | Webowa aplikacja | Prosty UI w Chrome | Intuicyjny UI w Chrome |
| **Modele AI** | Lokalne LLM, wybór modeli wg. dostępnych zasobów      | GPT-4, Claude | Wbudowane AI | Wbudowane AI (API) |
| **Obsługa uploadów plików** | Pełna obsługa                                         | Pełna obsługa | Ograniczona | Ograniczona |
| **Wypełnianie złożonych formularzy** | Zaawansowana analiza i mapowanie                      | Zaawansowana analiza | Podstawowa analiza | Podstawowa analiza |
| **Integracja z hasłami** | Bitwarden, PassBolt                                   | Różne menedżery | Integracja z Chrome | Integracja z Chrome |
| **Nagrywanie sesji** | Wbudowane                                             | Wbudowane | Brak | Brak |
| **Automatyczna generacja pipeline'ów** | Z użyciem LLM                                         | Z użyciem GPT-4 | Brak | Brak |
| **Sterowanie głosowe** | Web Speech API                                        | Ograniczone | Brak | Brak |
| **Własne środowisko testowe** | Rozbudowane z różnymi typami formularzy               | Brak | Brak | Brak |
| **Skalowalność** | Ograniczona do zasobów lokalnych/serwera              | Chmurowa | Ograniczona do przeglądarki | Ograniczona do przeglądarki |
| **Łatwość instalacji** | Wymaga konfiguracji Docker                            | Bardzo łatwa | Bardzo łatwa | Bardzo łatwa |
| **Prywatność danych** | Pełna (wszystko lokalnie)                             | Dane w chmurze | W przeglądarce | W przeglądarce |
| **Wsparcie** | Społeczność, Komercyjne, Discord                      | Komercyjne, SLA | Komercyjne | Komercyjne |

## 📚 Spis treści / Menu
- [Szybki start](#szybki-start)
- [Obsługa Mermaid na GitHub Pages](#obsługa-mermaid-na-github-pages-htmljekyll)
- [Obsługa Mermaid na GitLab Pages](#obsługa-mermaid-na-gitlab-pages)
- [Jak to działa](#jak-to-działa)
- [Przykłady zastosowań](#przykłady-zastosowań)
- [Główne cechy](#główne-cechy)
- [FAQ](#faq)
- [Kontakt i wsparcie](#kontakt-i-wsparcie)

---

## Instalacja środowiska (Python 3.11+ / 3.12 na Ubuntu 24.10+)

Aby uniknąć problemów z kompatybilnością (np. PyAudio vs Python 3.12), zalecane jest użycie Pythona 3.11. **Na Ubuntu 24.10+ dostępny jest tylko Python 3.12 – patrz uwaga poniżej!**

```bash
# (Linux/Ubuntu) Instalacja wymaganych pakietów
sudo apt-get update && sudo apt-get install python3.11 python3.11-venv python3.11-dev
# Na Ubuntu 24.10+:
sudo apt-get install python3.12 python3.12-venv python3.12-dev

# Utworzenie i aktywacja środowiska wirtualnego
python3.11 -m venv venv-py311   # lub
python3.12 -m venv venv-py312   # na Ubuntu 24.10+
source venv-py311/bin/activate  # lub
source venv-py312/bin/activate

# Instalacja zależności
pip install --upgrade pip
pip install -r requirements.txt
```

Możesz także użyć skryptu:
```bash
bash install.sh  # automatyczna instalacja Docker Compose v2 (plugin CLI)
```

Po instalacji Compose v2 dostępne będzie jako polecenie:
```bash
docker compose version
```

> **Uwaga dot. PyAudio i Python 3.12:**
> PyAudio nie jest kompatybilne z Python 3.12 (błąd: `pkgutil.ImpImporter`).
> - Jeśli nie potrzebujesz funkcji audio, możesz usunąć PyAudio z `requirements.txt`.
> - Jeśli potrzebujesz PyAudio, spróbuj zainstalować [nieoficjalny wheel z https://www.lfd.uci.edu/~gohlke/pythonlibs/#pyaudio](https://www.lfd.uci.edu/~gohlke/pythonlibs/#pyaudio) (tylko Windows), lub rozważ alternatywę np. `sounddevice`.
> - Możesz też użyć środowiska z Pythonem 3.11 (np. Docker, starsze Ubuntu).

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

Masz pytania lub potrzebujesz pomocy? Oferujemy wsparcie społeczności/komercyjne oraz szybki kontakt przez kanał na Discord:

- [Kanał Discord](https://discord.gg/TwojLink)
- Email: coboarding@protonmail.com

Projekt open-source. Wszelkie zgłoszenia błędów i propozycje zmian prosimy kierować przez Issues na GitHub.

# coBoarding

System do automatycznego wypełniania formularzy internetowych wykorzystujący lokalne modele językowe (LLM) w trzech językach (polski, niemiecki, angielski) bazujący na danych z CV.

![coBoarding Logo](https://via.placeholder.com/800x200/3498db/ffffff?text=coBoarding)

## Funkcjonalności

- **Automatyczne wykrywanie formularzy** na stronach internetowych
- **Inteligentne dopasowywanie danych z CV** do pól formularza
- **Obsługa trzech języków**: polski, niemiecki, angielski - automatyczne wykrywanie języka formularza
- **Lokalna analiza językowa** z wykorzystaniem modeli LLM (bez wysyłania danych do zewnętrznych API)
- **Wsparcie dla różnych formatów CV**: HTML, PDF, DOCX
- **Pełna automatyzacja** procesu wypełniania formularzy rekrutacyjnych
- **Zrzuty ekranu** wypełnionych formularzy do weryfikacji

## Wymagania systemowe

- Docker i Docker Compose
- Minimum 8GB RAM (zalecane 16GB)
- Minimum 10GB wolnego miejsca na dysku
- Połączenie z internetem (tylko do pobierania modeli LLM przy pierwszym uruchomieniu)

## Szybki start

### 1. Sklonuj repozytorium

```bash
git clone https://github.com/coboarding/python.git
cd python
```

### 2. Przygotuj CV

Umieść swoje CV w katalogu `cv/` w jednym z obsługiwanych formatów (HTML, PDF, DOCX).

### 3. Utwórz plik z adresami URL

Utwórz plik `urls.txt` z adresami stron zawierających formularze rekrutacyjne:

```
https://example.com/job-application1
https://example.com/job-application2
```

### 4. Uruchom skrypt startowy

```bash
chmod +x run.sh
./run.sh
```

Skrypt przeprowadzi Cię przez proces uruchomienia systemu.

## Szczegółowa konfiguracja

Możesz dostosować działanie systemu edytując plik `config.ini`:

```ini
[CV]
path = /app/cv/cv_tom_sapletta_2025_de.html

[LLM]
model_path = /app/models/mistral.gguf
model_type = llama
device = cpu

[Browser]
type = chrome
headless = true

[Output]
directory = /app/output
```

### Dostępne modele LLM

System domyślnie używa modelu Mistral, ale możesz użyć jednego z następujących modeli:

- `mistral.gguf` - Mistral 7B (domyślny, dobry kompromis między jakością a wymaganiami)
- `llama-2-7b.gguf` - Llama 2 7B (alternatywa)
- `falcon-7b.gguf` - Falcon 7B (alternatywa)

Większe modele (13B, 70B) zapewniają lepszą jakość, ale wymagają więcej zasobów.

## Tryby działania

System można uruchomić w trzech trybach:

1. **Tryb wsadowy** - przetwarzanie wszystkich adresów URL z pliku:
   ```bash
   python main.py --config config.ini --urls-file urls.txt
   ```

2. **Tryb pojedynczego URL** - przetwarzanie pojedynczego adresu:
   ```bash
   python main.py --config config.ini --url https://example.com/job-application
   ```

3. **Tryb interaktywny** - do debugowania (tylko w Dockerze):
   ```bash
   # W docker-compose.yml zmień command: sleep infinity
   docker-compose up -d
   docker exec -it coBoarding bash
   ```

## Obsługa błędów

### Typowe problemy

1. **Problem:** Kontener Docker kończy działanie z błędem
   **Rozwiązanie:** Sprawdź logi: `docker-compose logs`

2. **Problem:** Formularze nie są poprawnie wykrywane
   **Rozwiązanie:** Niektóre strony używają niestandardowego JavaScript. Spróbuj uruchomić w trybie nieheadless.

3. **Problem:** Model LLM nie jest pobierany automatycznie
   **Rozwiązanie:** Pobierz model ręcznie i umieść go w katalogu `models/`

## Szczegółowe logowanie i debugowanie

W plikach Dockerfile, `install.sh` oraz `run.sh` zostały dodane szczegółowe komunikaty [DEBUG] oraz [INFO].

- Każdy kluczowy etap instalacji, budowy obrazu i uruchamiania usług jest logowany.
- Logi pomagają szybko zlokalizować miejsce, gdzie wystąpił problem.
- W terminalu zobaczysz wyraźne komunikaty o postępie i ewentualnych błędach.

**Wskazówka:**
Jeśli coś pójdzie nie tak, sprawdź logi [DEBUG] w konsoli — wskażą, na którym etapie pojawił się problem.

## Jak to działa

1. System analizuje CV użytkownika, parsując kluczowe informacje (doświadczenie, umiejętności, wykształcenie).
2. Dla każdego URL, system uruchamia zautomatyzowaną przeglądarkę i wykrywa formularze na stronie.
3. Lokalny model LLM analizuje strukturę formularza i jego pola.
4. System inteligentnie dopasowuje dane z CV do pól formularza, tłumacząc je na odpowiedni język.
5. Formularz jest automatycznie wypełniany, a zrzut ekranu jest zapisywany do weryfikacji.

## Bezpieczeństwo

- Wszystkie dane są przetwarzane lokalnie
- Żadne informacje nie są wysyłane do zewnętrznych API
- Lokalne modele LLM zapewniają prywatność danych
- System nie wysyła automatycznie formularzy - tylko je wypełnia

## Licencja

Ten projekt jest udostępniany na licencji MIT. Szczegółowe informacje można znaleźć w pliku LICENSE.

## Autor

Tom Sapletta

## Współpraca

Chętnie przyjmujemy Pull Requesty! Aby przyczynić się do rozwoju projektu:

1. Sforkuj repozytorium
2. Utwórz branch z nową funkcjonalnością (`git checkout -b feature/amazing-feature`)
3. Zatwierdź zmiany (`git commit -m 'Add amazing feature'`)
4. Wypchnij branch (`git push origin feature/amazing-feature`)
5. Otwórz Pull Request

# Struktura projektu coBoarding

```
coBoarding/
├── cv/                                 # Katalog na pliki CV
│   └── cv_tom_sapletta_2025_de.html    # Twoje CV w formacie HTML
│
├── models/                             # Katalog na modele LLM
│   └── mistral.gguf                    # Pobrany automatycznie przy pierwszym uruchomieniu
│
├── output/                             # Katalog na dane wyjściowe (zrzuty ekranu)
│
├── Dockerfile                          # Definicja obrazu Docker
├── docker-compose.yml                  # Konfiguracja Docker Compose
├── config.ini                          # Konfiguracja aplikacji
├── requirements.txt                    # Zależności Pythona
├── main.py                             # Główny skrypt aplikacji
├── run.sh                              # Skrypt do łatwego uruchamiania
├── urls.txt                            # Lista adresów URL do przetworzenia
└── README.md                           # Dokumentacja projektu
```

## Opis plików

### Główne pliki aplikacji

- **main.py**: Główny skrypt aplikacji zawierający całą logikę wypełniania formularzy.
- **config.ini**: Plik konfiguracyjny aplikacji.
- **requirements.txt**: Lista zależności Pythona potrzebnych do działania aplikacji.
- **urls.txt**: Plik z listą adresów URL stron z formularzami do wypełnienia.
- **run.sh**: Skrypt ułatwiający uruchamianie aplikacji.

### Pliki Docker

- **Dockerfile**: Definicja obrazu Docker z potrzebnymi zależnościami.
- **docker-compose.yml**: Konfiguracja Docker Compose do łatwego uruchamiania aplikacji.


### Katalogi danych

- **cv/**: Katalog zawierający pliki CV, z których aplikacja będzie czerpać dane do wypełniania formularzy.
- **models/**: Katalog zawierający modele LLM używane do analizy formularzy i generowania odpowiedzi.
- **output/**: Katalog przechowujący zrzuty ekranu wypełnionych formularzy.

## Kluczowe funkcjonalności

Aplikacja działa w następujący sposób:

1. Parsuje CV użytkownika, aby wydobyć kluczowe informacje.
2. Otwiera stronę internetową z formularzem w zautomatyzowanej przeglądarce.
3. Analizuje formularz za pomocą lokalnego modelu językowego (LLM).
4. Dopasowuje dane z CV do pól formularza, automatycznie tłumacząc je na odpowiedni język (polski, niemiecki, angielski).
5. Wypełnia formularz i wykonuje zrzut ekranu.

Całość działa w kontenerze Docker, co zapewnia łatwą instalację i uruchomienie na różnych systemach operacyjnych.

---

<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.esm.min.mjs';
  mermaid.initialize({ 
    startOnLoad: true,
    theme: 'default',
    securityLevel: 'loose'
  });
</script>
