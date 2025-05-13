import socket
import pytest

PORTS = [
    ("llm-orchestrator", "llm-orchestrator", 5000),
    ("browser-service", "browser-service", 3000),
    ("web-interface", "web-interface", 8080),
    ("novnc", "novnc", 6080),
    ("video-chat", "video-chat", 443),
    ("web-terminal", "web-terminal", 8081),
]

@pytest.mark.parametrize("service_name, host, port", PORTS)
def test_port_open(service_name, host, port):
    s = socket.socket()
    try:
        s.settimeout(4)
        s.connect((host, port))
    except Exception as e:
        pytest.fail(f"{service_name} port {port} not open: {e}")
    finally:
        s.close()
