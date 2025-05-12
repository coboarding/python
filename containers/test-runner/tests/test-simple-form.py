# test-runner/tests/test-simple-form.py
import time
import os
import json
import requests
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


# Pomocnicza funkcja wywołująca API AutoFormFiller
def fill_form_with_autofiller(form_url, cv_path):
    """Wywołuje API AutoFormFiller do wypełnienia formularza"""
    try:
        response = requests.post(
            "http://llm-orchestrator:5000/fill-form",
            json={
                "form_url": form_url,
                "cv_path": cv_path
            },
            timeout=60
        )
        return response.json()
    except Exception as e:
        print(f"Błąd podczas wywołania API AutoFormFiller: {str(e)}")
        return {"status": "error", "message": str(e)}


# Funkcja sprawdzająca poprawność wypełnienia formularza
def validate_form_filling(form_url, cv_data):
    """Sprawdza czy formularz został poprawnie wypełniony"""
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")

    driver = webdriver.Chrome(options=options)
    try:
        # Otwórz URL po wypełnieniu przez AutoFormFiller
        driver.get(form_url)

        # Poczekaj na załadowanie formularza
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.TAG_NAME, "form"))
        )

        # Poczekaj dodatkowe 2 sekundy na działanie AutoFormFiller
        time.sleep(2)

        # Sprawdź czy pola zostały wypełnione
        name_field = driver.find_element(By.ID, "name")
        email_field = driver.find_element(By.ID, "email")
        phone_field = driver.find_element(By.ID, "phone")
        message_field = driver.find_element(By.ID, "message")

        # Pobierz aktualne wartości pól
        actual_values = {
            "name": name_field.get_attribute("value"),
            "email": email_field.get_attribute("value"),
            "phone": phone_field.get_attribute("value"),
            "message": message_field.get_attribute("value")
        }

        # Oczekiwane wartości na podstawie danych CV
        expected_values = {
            "name": cv_data["personal_info"]["name"],
            "email": cv_data["personal_info"]["email"],
            "phone": cv_data["personal_info"]["phone"],
            "message": "To jest wiadomość wygenerowana przez AutoFormFiller w celach testowych."
        }

        # Sprawdź zgodność
        validation_results = {}
        overall_success = True

        for field, expected in expected_values.items():
            actual = actual_values.get(field, "")
            is_matching = actual == expected

            # Dla pola message sprawdzamy, czy zawiera jakikolwiek tekst
            if field == "message" and not is_matching:
                is_matching = len(actual) > 20  # Wystarczy, że jest jakiś sensowny tekst

            validation_results[field] = {
                "expected": expected,
                "actual": actual,
                "is_matching": is_matching
            }

            if not is_matching:
                overall_success = False

        # Zrzut ekranu wypełnionego formularza
        driver.save_screenshot("/volumes/test-results/simple-form-filled.png")

        return {
            "success": overall_success,
            "field_validation": validation_results,
            "screenshot_path": "/volumes/test-results/simple-form-filled.png"
        }

    except Exception as e:
        driver.save_screenshot("/volumes/test-results/simple-form-error.png")
        return {
            "success": False,
            "error": str(e),
            "screenshot_path": "/volumes/test-results/simple-form-error.png"
        }
    finally:
        driver.quit()

    def main():
        print("=== Test wypełniania prostego formularza ===")

        # Załaduj dane testowe
        with open('/volumes/test-data/test-cv.json', 'r', encoding='utf-8') as f:
            cv_data = json.load(f)

        # Utwórz katalog na wyniki testów
        os.makedirs('/volumes/test-results', exist_ok=True)

        # Ścieżka do formularza
        form_url = "http://test-forms-server/forms/simple-form.html"

        print(f"Testowany formularz: {form_url}")
        print("Rozpoczynam wypełnianie formularza za pomocą AutoFormFiller...")

        # Wywołaj AutoFormFiller
        result = fill_form_with_autofiller(form_url, "/volumes/test-data/test-cv.json")

        print(f"Wynik wywołania AutoFormFiller: {result['status']}")

        # Weryfikacja wypełnienia formularza
        print("Weryfikuję poprawność wypełnienia formularza...")
        validation = validate_form_filling(form_url, cv_data)

        if validation["success"]:
            print("✅ Test zakończony sukcesem! Formularz został poprawnie wypełniony.")
        else:
            print("❌ Test zakończony niepowodzeniem. Wykryto problemy z wypełnieniem formularza:")
            for field, result in validation.get("field_validation", {}).items():
                if not result.get("is_matching", False):
                    print(f"  - Pole {field}:")
                    print(f"    Oczekiwano: {result.get('expected', '')}")
                    print(f"    Otrzymano: {result.get('actual', '')}")

        print(f"Zrzut ekranu dostępny pod: {validation.get('screenshot_path', 'brak')}")
        return validation["success"]

    if __name__ == "__main__":
        success = main()
        exit(0 if success else 1)