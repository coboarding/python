import requests
import pytest

SERVICES = [
    ("llm-orchestrator", "http://llm-orchestrator:5000/health"),
    ("browser-service", "http://browser-service:3000/health"),
    ("web-interface", "http://web-interface:8080/"),
    ("novnc", "http://novnc:6080/"),
    ("video-chat", "http://video-chat:443/"),
    ("web-terminal", "http://web-terminal:8081/"),
]

@pytest.mark.parametrize("service_name, url", SERVICES)
def test_service_health(service_name, url):
    try:
        resp = requests.get(url, timeout=10, verify=False)
        assert resp.status_code in (200, 401, 403)
    except Exception as e:
        pytest.fail(f"{service_name} not healthy: {e}")
