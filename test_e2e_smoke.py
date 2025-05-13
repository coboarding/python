import requests

def test_monitor_health():
    """Sprawdza, czy monitor odpowiada na /health."""
    r = requests.get("http://localhost:8082/health", timeout=5)
    assert r.status_code == 200
    assert r.json().get("status") == "ok"

def test_web_interface():
    """Sprawdza, czy web-interface odpowiada na stronie głównej."""
    r = requests.get("http://localhost:8082", timeout=5)
    assert r.status_code == 200
    assert "coBoarding" in r.text or "html" in r.text.lower()

def test_terminal_interface():
    """Sprawdza, czy web-terminal odpowiada na stronie głównej."""
    r = requests.get("http://localhost:8081", timeout=5)
    assert r.status_code == 200
    assert "Terminal" in r.text or "html" in r.text.lower()

# Dodaj więcej testów e2e w razie potrzeby (np. logowanie, API, upload CV, itp.)
