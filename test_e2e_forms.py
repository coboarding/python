import requests
import pytest

def test_fill_simple_form():
    """Testuje wypełnianie prostego formularza przez API coBoarding."""
    payload = {
        "form_url": "http://localhost:8090/forms/simple-form.html",
        "cv_path": "/volumes/cv/example_cv.html"
    }
    r = requests.post("http://localhost:5000/fill-form", json=payload, timeout=30)
    assert r.status_code == 200
    data = r.json()
    assert data.get("status") == "success"
    assert "filled_form_url" in data

@pytest.mark.parametrize("form_url", [
    "http://localhost:8090/forms/complex-form.html",
    "http://localhost:8090/forms/file-upload-form.html"
])
def test_fill_other_forms(form_url):
    payload = {
        "form_url": form_url,
        "cv_path": "/volumes/cv/example_cv.html"
    }
    r = requests.post("http://localhost:5000/fill-form", json=payload, timeout=60)
    assert r.status_code == 200
    data = r.json()
    assert data.get("status") == "success"
    assert "filled_form_url" in data
