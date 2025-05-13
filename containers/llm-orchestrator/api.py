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



@app.route('/execute_command', methods=['POST'])
def execute_command():
    """Wykonuje komendę od interfejsu video-chat"""
    try:
        data = request.json
        action = data.get('action')
        params = data.get('params', {})

        if not action:
            return jsonify({
                "success": False,
                "message": "No action specified"
            }), 400

        response = {
            "success": True,
            "action": action,
            "message": f"Command {action} executed successfully"
        }

        # Obsługa różnych komend
        if action == 'fill_form':
            url = params.get('url')
            if url:
                # Wywołanie funkcji wypełniania formularza
                form_result = fill_form(url, params.get('cv_path'))
                response["details"] = form_result
                response["message"] = f"Form at {url} filled successfully"
            else:
                response["success"] = False
                response["message"] = "URL is required for fill_form action"

        elif action == 'run_test':
            # Wywołanie funkcji uruchamiania testów
            test_result = run_tests()
            response["details"] = test_result
            response["message"] = "Tests executed successfully"

        elif action == 'show_status':
            # Pobranie statusu systemu
            status = get_system_status()
            response["details"] = status
            response["message"] = f"System status: {status['status']}, active model: {status['active_model']}"

        elif action == 'generate_pipeline':
            # Generowanie pipeline dla URL (jeśli podano)
            url = params.get('url')
            if url:
                pipeline = generate_pipeline(url)
                response["pipeline"] = pipeline
                response["message"] = f"Pipeline generated for {url}"
            else:
                response["success"] = False
                response["message"] = "URL is required for generate_pipeline action"

        elif action == 'run_pipeline':
            # Uruchomienie istniejącego pipeline
            pipeline_id = params.get('pipeline_id')
            if pipeline_id:
                result = run_pipeline(pipeline_id)
                response["details"] = result
                response["message"] = f"Pipeline {pipeline_id} executed successfully"
            else:
                response["success"] = False
                response["message"] = "Pipeline ID is required"

        elif action == 'edit_pipeline':
            # Edycja istniejącego pipeline
            pipeline_id = params.get('pipeline_id')
            if pipeline_id:
                pipeline = get_pipeline(pipeline_id)
                response["pipeline"] = pipeline
                response["message"] = f"Pipeline {pipeline_id} loaded for editing"
            else:
                response["success"] = False
                response["message"] = "Pipeline ID is required"

        elif action == 'help':
            # Zwracanie listy dostępnych komend
            commands = [
                {"name": "fill_form", "description": "Fill a form at the specified URL", "params": ["url"]},
                {"name": "run_test", "description": "Run tests for the system"},
                {"name": "show_status", "description": "Show current system status"},
                {"name": "list_forms", "description": "List available forms/applications"},
                {"name": "select_model", "description": "Select LLM model to use"},
                {"name": "generate_pipeline", "description": "Generate a pipeline for a URL", "params": ["url"]},
                {"name": "run_pipeline", "description": "Execute an existing pipeline", "params": ["pipeline_id"]},
                {"name": "edit_pipeline", "description": "Edit an existing pipeline", "params": ["pipeline_id"]},
                {"name": "help", "description": "Show available commands"}
            ]
            response["commands"] = commands
            response["message"] = "Available commands"

        else:
            response["success"] = False
            response["message"] = f"Unknown action: {action}"

        return jsonify(response)

    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Error executing command: {str(e)}"
        }), 500