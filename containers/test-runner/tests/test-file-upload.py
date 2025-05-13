# test-runner/tests/test-file-upload.py
import time
import os
import json
import requests
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


def fill_form_with_autofiller(form_url, cv_path, upload_files):
    """Wywołuje API coBoarding do wypełnienia formularza z uploadem plików"""
    try:
        response = requests.post(
            "http://llm-orchestrator:5000/fill-form",
            json={
                "form_url": form_url,
                "cv_path": cv_path,
                "upload_files": upload_files
            },
            timeout=120
        )
        return response.json()
    except Exception as e:
        print(f"Błąd podczas wywołania API coBoarding: {str(e)}")
        return {"status": "error", "message": str(e)}


def validate_file_upload_form(form_url, cv_data, upload_files):
    """Sprawdza czy formularz z upload'em plików został poprawnie wypełniony"""
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
            EC.presence_of_element_located((By.ID, "application-form"))
        )

        # Zrzut ekranu pustego formularza
        driver.save_screenshot("/volumes/test-results/file-upload-form-before.png")

        # Wywołaj coBoarding
        print("Wywołuję coBoarding dla formularza z uploadem plików...")
        result = fill_form_with_autofiller(form_url, "/volumes/test-data/test-cv.json", upload_files)
        print(f"Wynik wywołania coBoarding: {result['status']}")

        # Poczekaj na wypełnienie formularza i upload plików
        time.sleep(5)

        # Sprawdź wypełnienie podstawowych pól
        text_fields = {
            "name": cv_data["personal_info"]["name"],
            "email": cv_data["personal_info"]["email"],
            "position": cv_data["experience"][0]["title"]
        }

        validation_results = {}
        overall_success = True

        # Sprawdź pola tekstowe
        for field_id, expected in text_fields.items():
            try:
                field = driver.find_element(By.ID, field_id)
                actual_value = field.get_attribute("value")
                is_matching = actual_value == expected

                validation_results[field_id] = {
                    "expected": expected,
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

        # Sprawdź informacje o plikach
        file_infos = {
            "cv-info": os.path.basename(upload_files["cv"]),
            "cover-letter-info": os.path.basename(upload_files["cover_letter"])
        }

        for info_id, expected_filename in file_infos.items():
            try:
                info_element = driver.find_element(By.ID, info_id)
                actual_text = info_element.text
                # Sprawdź czy nazwa pliku jest widoczna w elemencie informacyjnym
                is_matching = expected_filename in actual_text

                validation_results[info_id] = {
                    "expected": f"Zawiera '{expected_filename}'",
                    "actual": actual_text,
                    "is_matching": is_matching
                }

                if not is_matching:
                    overall_success = False
            except Exception as e:
                validation_results[info_id] = {
                    "error": str(e),
                    "is_matching": False
                }
                overall_success = False

        # Zrzut ekranu wypełnionego formularza
        driver.save_screenshot("/volumes/test-results/file-upload-form-after.png")

        return {
            "success": overall_success,
            "field_validation": validation_results,
            "screenshot_path": "/volumes/test-results/file-upload-form-after.png"
        }

    except Exception as e:
        driver.save_screenshot("/volumes/test-results/file-upload-form-error.png")
        return {
            "success": False,
            "error": str(e),
            "screenshot_path": "/volumes/test-results/file-upload-form-error.png"
        }
    finally:
        driver.quit()


def main():
    print("=== Test wypełniania formularza z uploadem plików ===")

    # Załaduj dane testowe
    with open('/volumes/test-data/test-cv.json', 'r', encoding='utf-8') as f:
        cv_data = json.load(f)

    # Utwórz katalog na wyniki testów
    os.makedirs('/volumes/test-results', exist_ok=True)

    # Ścieżka do formularza
    form_url = "http://test-forms-server/forms/file-upload-form.html"

    # Pliki do uploadowania
    upload_files = {
        "cv": "/volumes/test-data/test-cv.pdf",
        "cover_letter": "/volumes/test-data/test-letter.pdf"
    }

    print(f"Testowany formularz: {form_url}")
    print(f"Pliki do uploadowania: {', '.join(upload_files.values())}")

    # Weryfikacja wypełnienia formularza
    validation = validate_file_upload_form(form_url, cv_data, upload_files)

    if validation["success"]:
        print("✅ Test zakończony sukcesem! Formularz z uploadem plików został poprawnie wypełniony.")
    else:
        print("❌ Test zakończony niepowodzeniem. Wykryto problemy z wypełnieniem formularza:")
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