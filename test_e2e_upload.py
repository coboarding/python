import requests
import os

def test_file_upload_form():
    """Testuje wypełnianie formularza z uploadem plików przez API coBoarding."""
    # Przygotuj pliki testowe (upewnij się, że istnieją)
    cv_path = "/volumes/test-data/test-cv.pdf"
    letter_path = "/volumes/test-data/test-letter.pdf"
    assert os.path.exists(cv_path), f"Brak pliku {cv_path}"
    assert os.path.exists(letter_path), f"Brak pliku {letter_path}"
    payload = {
        "form_url": "http://localhost:8090/forms/file-upload-form.html",
        "cv_path": cv_path,
        "upload_files": {
            "cv": cv_path,
            "cover_letter": letter_path
        }
    }
    r = requests.post("http://localhost:5000/fill-form", json=payload, timeout=60)
    assert r.status_code == 200
    data = r.json()
    assert data.get("status") == "success"
    assert "filled_form_url" in data
