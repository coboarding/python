# Testy end-to-end (E2E)

## Jak uruchomić testy E2E?

1. Upewnij się, że wszystkie kontenery są uruchomione:
   ```bash
   bash run.sh
   ```
2. (Opcjonalnie) Aktywuj środowisko virtualenv:
   ```bash
   source venv-py311/bin/activate  # lub venv-py312
   ```
3. Uruchom testy:
   ```bash
   pytest test_e2e_*.py
   ```

## Przykładowe testy
- **test_e2e_smoke.py** – sprawdza, czy główne usługi odpowiadają (monitor, web, terminal)
- **test_e2e_forms.py** – testuje wypełnianie formularzy przez API
- **test_e2e_upload.py** – testuje upload plików CV i listu motywacyjnego

## Dodawanie własnych testów
- Utwórz plik `test_e2e_nazwa.py` w katalogu głównym.
- Używaj `requests`, `pytest` lub Selenium do automatyzacji testów.
- Przykład:
  ```python
  def test_api():
      r = requests.get("http://localhost:8082/health")
      assert r.status_code == 200
  ```

Przejdź do [FAQ](faq.md) lub [Struktura kontenerów](containers.md).
