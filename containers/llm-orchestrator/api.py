# Main API entry point for LLM Orchestrator
# llm-orchestrator/api.py (fragment)

from flask import Flask, request, jsonify
import requests
from email_utils import get_latest_token_from_email

app = Flask(__name__)

@app.route('/get-email-token', methods=['POST'])
def get_email_token():
    """
    Pobiera najnowszy token (np. kod 2FA) ze skrzynki email.
    Wymaga JSON z polami: imap_server, email_user, email_pass, optional: mailbox, search_subject, token_regex
    """
    data = request.json
    imap_server = data.get('imap_server')
    email_user = data.get('email_user')
    email_pass = data.get('email_pass')
    mailbox = data.get('mailbox', 'INBOX')
    search_subject = data.get('search_subject')
    token_regex = data.get('token_regex', r'\\b\d{6}\\b')
    if not (imap_server and email_user and email_pass):
        return jsonify({"error": "Brak wymaganych pól: imap_server, email_user, email_pass"}), 400
    try:
        token = get_latest_token_from_email(
            imap_server=imap_server,
            email_user=email_user,
            email_pass=email_pass,
            mailbox=mailbox,
            search_subject=search_subject,
            token_regex=token_regex
        )
        if token:
            return jsonify({"token": token})
        else:
            return jsonify({"error": "Nie znaleziono tokenu."}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- Lazy loading przykładowego modelu transformers ---
from transformers import AutoModelForCausalLM, AutoTokenizer

model = None
tokenizer = None

MODEL_NAME = "distilgpt2"  # Możesz tu podać dowolny model dostępny publicznie

def get_model():
    global model, tokenizer
    if model is None or tokenizer is None:
        model = AutoModelForCausalLM.from_pretrained(MODEL_NAME)
        tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    return model, tokenizer

@app.route('/use-llm', methods=['POST'])
def use_llm():
    """Przykładowy endpoint wykorzystujący lazy loading modelu LLM"""
    try:
        model, tokenizer = get_model()
        data = request.json
        prompt = data.get('prompt', "Hello, world!")
        inputs = tokenizer(prompt, return_tensors="pt")
        outputs = model.generate(**inputs, max_new_tokens=20)
        result = tokenizer.decode(outputs[0], skip_special_tokens=True)
        return jsonify({"result": result})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/', methods=['GET'])
def index():
    return jsonify({"message": "LLM Orchestrator API"}), 200

app = Flask(__name__)

@app.route('/api/health', methods=['GET'])
@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"}), 200

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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)



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