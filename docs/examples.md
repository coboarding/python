# Przykłady użycia coBoarding

Poniżej znajdziesz praktyczne scenariusze wykorzystania platformy coBoarding – zarówno dla użytkownika końcowego, jak i do automatyzacji/testów.

---

## 1. Automatyczne wypełnianie formularza rekrutacyjnego

1. Umieść swoje CV w katalogu `cv/` (np. `cv/moje-cv.pdf`).
2. Dodaj adres URL formularza do pliku `urls.txt`, np.:
   ```
   https://pracodawca.pl/formularz-aplikacyjny
   ```
3. Uruchom system:
   ```bash
   bash run.sh
   ```
4. Otwórz przeglądarkę i przejdź na `http://localhost:8082`.
5. Wybierz formularz z listy i kliknij „Wypełnij automatycznie”.

---

## 2. Integracja z API (np. testy E2E, automatyzacja)

Możesz programistycznie wywołać API do wypełniania formularzy:

```python
import requests

payload = {
    "form_url": "http://localhost:8090/forms/simple-form.html",
    "cv_path": "/volumes/cv/moje-cv.pdf"
}
r = requests.post("http://localhost:5000/fill-form", json=payload)
print(r.json())
```

---

## 3. Testowanie działania systemu (pytest E2E)

W katalogu głównym znajdziesz przykładowe testy E2E:
```bash
pytest test_e2e_smoke.py
pytest test_e2e_forms.py
pytest test_e2e_upload.py
```

---

## 4. Wypełnianie formularzy głosowo

1. Uruchom system z obsługą mikrofonu:
   ```bash
   bash run.sh
   ```
2. Na stronie UI kliknij ikonę mikrofonu i wydaj polecenie głosowe np. „Wypełnij formularz”.

---

## 5. Praca w trybie offline

coBoarding działa w pełni lokalnie – możesz uruchomić system bez połączenia z Internetem, a dane nie opuszczają Twojego komputera.

---

## 6. Zaawansowane: własne pipeline, integracja z Bitwarden/PassBolt

- Skonfiguruj integrację z menedżerem haseł w pliku `.env`.
- Dodaj własny pipeline lub test E2E w katalogu `containers/test-runner/tests/`.

---

Masz własny scenariusz? Dodaj go do tej dokumentacji lub zgłoś przez [GitHub Issues](https://github.com/coboarding/coboarding/issues).
