# Main API entry point for LLM Orchestrator
# llm-orchestrator/api.py (fragment)

@app.route('/fill-form', methods=['POST'])
def fill_form():
    """Endpoint do wypełniania formularzy (używany przez testy)"""
    try:
        data = request.json
        form_url = data.get('form_url')
        cv_path = data.get('cv_path')
        upload_files = data.get('upload_files', {})

        # Sprawdź wymagane pola
        if not form_url or not cv_path:
            return jsonify({
                "status": "error",
                "message": "Brak wymaganych pól: form_url, cv_path"
            }), 400

        # Rozpocznij wypełnianie formularza w przeglądarce
        response = requests.post(
            "http://browser-service:5001/fill-form",
            json={
                "form_url": form_url,
                "cv_path": cv_path,
                "upload_files": upload_files
            },
            timeout=60
        )

        if response.status_code == 200:
            return jsonify({
                "status": "success",
                "message": "Formularz został wypełniony pomyślnie",
                "details": response.json()
            })
        else:
            return jsonify({
                "status": "error",
                "message": f"Błąd podczas wypełniania formularza: {response.text}"
            }), response.status_code
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Wystąpił błąd: {str(e)}"
        }), 500