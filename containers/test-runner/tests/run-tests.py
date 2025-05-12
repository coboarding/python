# test-runner/tests/run-tests.py
import os
import time
import json
import random
import argparse
import subprocess
import requests
from bs4 import BeautifulSoup

# Konfiguracja
FORMS_SERVER = "http://test-forms-server"
TESTS = [
    "test-simple-form.py",
    "test-complex-form.py",
    "test-file-upload.py"
]


def generate_form_list():
    """Generuje listę testowych formularzy i zapisuje ją do pliku"""
    forms = []

    # Pobierz dostępne formularze
    try:
        response = requests.get(f"{FORMS_SERVER}/forms/")
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            for link in soup.find_all('a'):
                href = link.get('href')
                if href and href.endswith('.html'):
                    forms.append(f"{FORMS_SERVER}/forms/{href}")
    except Exception as e:
        print(f"Błąd podczas pobierania listy formularzy: {str(e)}")
        # Awaryjnie użyj domyślnej listy
        forms = [
            f"{FORMS_SERVER}/forms/simple-form.html",
            f"{FORMS_SERVER}/forms/complex-form.html",
            f"{FORMS_SERVER}/forms/file-upload-form.html"
        ]

    # Losowa kolejność formularzy dla realnych testów
    random.shuffle(forms)

    # Zapisz listę formularzy do pliku
    with open('/volumes/test-forms.txt', 'w') as f:
        for form in forms:
            f.write(f"{form}\n")

    print(f"Wygenerowano listę {len(forms)} formularzy testowych.")
    return forms


def prepare_test_data():
    """Przygotowuje dane testowe (CV, pliki do uploadowania)"""
    os.makedirs('/volumes/test-data', exist_ok=True)

    # Przykładowe CV w formacie JSON (zamiast rzeczywistego CV)
    test_cv_data = {
        "personal_info": {
            "name": "Jan Kowalski",
            "email": "jan.kowalski@example.com",
            "phone": "+48 123 456 789",
            "address": "ul. Przykładowa 123, 00-001 Warszawa, Polska",
            "linkedin": "https://linkedin.com/in/jankowalski",
            "github": "https://github.com/jankowalski"
        },
        "education": [
            {
                "degree": "Magister Informatyki",
                "institution": "Politechnika Warszawska",
                "location": "Warszawa",
                "graduation_date": "2019"
            },
            {
                "degree": "Licencjat Informatyki",
                "institution": "Uniwersytet Warszawski",
                "location": "Warszawa",
                "graduation_date": "2017"
            }
        ],
        "experience": [
            {
                "title": "Senior DevOps Engineer",
                "company": "TechCorp Sp. z o.o.",
                "location": "Warszawa",
                "start_date": "2020-03",
                "end_date": "Present",
                "description": "Zarządzanie infrastrukturą w chmurze AWS, wdrażanie CI/CD pipelines, automatyzacja procesów przy użyciu Terraform i Ansible."
            },
            {
                "title": "DevOps Engineer",
                "company": "StartupXYZ",
                "location": "Kraków",
                "start_date": "2019-01",
                "end_date": "2020-02",
                "description": "Implementacja konteneryzacji z Docker i Kubernetes, monitoring infrastruktury, automatyzacja deploymentów."
            }
        ],
        "skills": {
            "technical": ["Docker", "Kubernetes", "AWS", "Azure", "Terraform", "Ansible", "Python", "Bash", "Java",
                          "Git", "CI/CD", "Jenkins", "GitLab CI", "Prometheus", "Grafana"],
            "languages": [
                {"language": "Polski", "level": "Native"},
                {"language": "Angielski", "level": "C1"},
                {"language": "Niemiecki", "level": "B2"}
            ],
            "soft": ["Praca zespołowa", "Komunikacja", "Rozwiązywanie problemów", "Zarządzanie czasem"]
        }
    }

    # Zapisz dane testowe
    with open('/volumes/test-data/test-cv.json', 'w', encoding='utf-8') as f:
        json.dump(test_cv_data, f, ensure_ascii=False, indent=2)

    # Generowanie plików do testów upload
    with open('/volumes/test-data/test-cv.pdf', 'w') as f:
        f.write("To jest testowy plik CV.PDF\n")

    with open('/volumes/test-data/test-letter.pdf', 'w') as f:
        f.write("To jest testowy list motywacyjny.PDF\n")

    print("Przygotowano dane testowe.")


def run_test(test_script):
    """Uruchamia pojedynczy test"""
    print(f"\n=== Uruchamianie testu: {test_script} ===\n")
    result = subprocess.run(["python", f"/app/tests/{test_script}"], capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(f"Błędy:\n{result.stderr}")
    return result.returncode == 0


def main():
    parser = argparse.ArgumentParser(description="Runner testów coBoarding")
    parser.add_argument("--generate-only", action="store_true",
                        help="Tylko generuj dane testowe bez uruchamiania testów")
    args = parser.parse_args()

    print("=== Przygotowanie środowiska testowego ===")
    forms = generate_form_list()
    prepare_test_data()

    if args.generate_only:
        print("\nWygenerowano dane testowe. Zakończono.")
        return

    print("\n=== Uruchamianie testów coBoarding ===\n")

    successful_tests = 0
    for test in TESTS:
        if run_test(test):
            successful_tests += 1

    print(f"\n=== Podsumowanie testów: {successful_tests}/{len(TESTS)} testów zakończonych sukcesem ===")


if __name__ == "__main__":
    main()