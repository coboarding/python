import requests
import json

# Przykładowy test endpointu /fill-form
url = "http://llm-orchestrator:5000/fill-form"
payload = {
    "form_url": "https://example.com/form",
    "cv_path": "/app/cv/example_cv.pdf",
    "upload_files": {}
}

try:
    response = requests.post(url, json=payload, timeout=10)
    print("Status:", response.status_code)
    print("Response:", response.text)
except Exception as e:
    print("[ERROR] Test nie powiódł się:", e)
