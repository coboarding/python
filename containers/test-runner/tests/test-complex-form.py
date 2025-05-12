# test-runner/tests/test-complex-form.py
import time
import os
import json
import random
import requests
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select


def fill_form_with_autofiller(form_url, cv_path):
    """Wywołuje API AutoFormFiller do wypełnienia formularza"""
    try:
        response = requests.post(
            "http://llm-orchestrator:5000/fill-form",
            json={
                "form_url": form_url,
                "cv_path": cv_path
            },
            timeout=120  # Dłuższy timeout dla złożonego formularza
        )
        return response.json()
    except Exception as e:
        print(f"Błąd podczas wywołania API AutoFormFiller: {str(e)}")
        return {"status": "error", "message": str(e)}


def validate_form_filling(form_url, cv_data):
    """Sprawdza czy złożony formularz został poprawnie wypełniony"""
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")

    driver = webdriver.Chrome(options=options)
    try:
        # Otwórz URL
        driver.get(form_url)

        # Poczekaj na załadowanie formularza
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "job-application-form"))
        )

        # Sprawdź oba języki - losowo wybierz jeden
        language = random.choice(["de", "en"])
        print(f"Testowanie formularza w języku: {language}")

        # Przełącz na wybrany język
        language_btn = driver.find_element(By.CSS_SELECTOR, f".language-btn[data-lang='{language}']")
        language_btn.click()
        time.sleep(1)  # Poczekaj na zmianę języka

        # Poczekaj dodatkowe 3 sekundy na działanie AutoFormFiller - złożony formularz
        time.sleep(3)

        # Zrób zrzut ekranu przed testami
        driver.save_screenshot(f"/volumes/test-results/complex-form-{language}-before.png")

        # Wypełnij formularz za pomocą AutoFormFiller
        result = fill_form_with_autofiller(form_url, "/volumes/test-data/test-cv.json")
        print(f"Wynik wywołania AutoFormFiller: {result['status']}")

        # Poczekaj na wypełnienie formularza
        time.sleep(5)

        # Sprawdź kluczowe pola na podstawie języka
        fields_to_check = [
            "name", "email", "phone", "address",  # dane osobowe
            "current-position", "current-company", "experience-years",  # doświadczenie
            "skills", "education", "languages",  # umiejętności
            "motivation", "salary"  # dodatkowe informacje
        ]

        validation_results = {}
        overall_success = True

        for field_id in fields_to_check:
            try:
                field = driver.find_element(By.ID, field_id)
                actual_value = field.get_attribute("value") or field.text

                # Sprawdź, czy pole jest wypełnione
                if field_id == "name":
                    expected = cv_data["personal_info"]["name"]
                    is_matching = actual_value == expected
                elif field_id == "email":
                    expected = cv_data["personal_info"]["email"]
                    is_matching = actual_value == expected
                else:
                    # Dla pozostałych pól wystarczy, że nie są puste
                    expected = "non-empty"
                    is_matching = len(actual_value.strip()) > 0

                validation_results[field_id] = {
                    "expected": expected if expected != "non-empty" else "Niepuste pole",
                    "actual": actual_value,
                    "is_matching": is_matching
                }

                if not is_matching:
                    overall_success = False
            except Exception as e:
                validation_results[field_id] = {
                    "error": str(e),
                    "is_matching": False
                }
                overall_success = False

        # Zrzut ekranu wypełnionego formularza
        driver.save_screenshot(f"/volumes/test-results/complex-form-{language}-after.png")

        return {
            "success": overall_success,
            "language": language,
            "field_validation": validation_results,
            "screenshot_path": f"/volumes/test-results/complex-form-{language}-after.png"
        }

    except Exception as e:
        driver.save_screenshot("/volumes/test-results/complex-form-error.png")
        return {
            "success": False,
            "error": str(e),
            "screenshot_path": "/volumes/test-results/complex-form-error.png"
        }
    finally:
        driver.quit()


def main():
    print("=== Test wypełniania złożonego formularza wielojęzycznego ===")

    # Załaduj dane testowe
    with open('/volumes/test-data/test-cv.json', 'r', encoding='utf-8') as f:
        cv_data = json.load(f)

    # Utwórz katalog na wyniki testów
    os.makedirs('/volumes/test-results', exist_ok=True)

    # Ścieżka do formularza
    form_url = "http://test-forms-server/forms/complex-form.html"

    print(f"Testowany formularz: {form_url}")
    print("Rozpoczynam test złożonego formularza wielojęzycznego...")

    # Weryfikacja wypełnienia formularza
    validation = validate_form_filling(form_url, cv_data)

    if validation["success"]:
        print(f"✅ Test zakończony sukcesem! Formularz w języku {validation['language']} został poprawnie wypełniony.")
    else:
        print(
            f"❌ Test zakończony niepowodzeniem. Wykryto problemy z wypełnieniem formularza w języku {validation.get('language', 'nieznany')}:")
        for field, result in validation.get("field_validation", {}).items():
            if not result.get("is_matching", False):
                print(f"  - Pole {field}:")
                if "expected" in result:
                    print(f"    Oczekiwano: {result['expected']}")
                    print(f"    Otrzymano: {result['actual']}")
                else:
                    print(f"    Błąd: {result.get('error', 'nieznany')}")

    print(f"Zrzut ekranu dostępny pod: {validation.get('screenshot_path', 'brak')}")
    return validation["success"]


if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)