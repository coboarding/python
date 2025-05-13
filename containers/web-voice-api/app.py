from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import json
import uuid
import time
import logging
import requests
import speech_recognition as sr
from pydub import AudioSegment
import io
import threading

# Konfiguracja logowania
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
)
logger = logging.getLogger("VoiceAPI")

app = Flask(__name__)
CORS(app)  # Włączenie Cross-Origin Resource Sharing

# Katalog do przechowywania plików audio
AUDIO_DIR = os.environ.get('AUDIO_DIR', '/app/audio')
os.makedirs(AUDIO_DIR, exist_ok=True)

# Adres API LLM Orchestrator
LLM_API_URL = "http://llm-orchestrator:5000"

# Podstawowe komendy głosowe i ich mapowanie na akcje
VOICE_COMMANDS = {
    "wypełnij formularz": "fill_form",
    "uruchom test": "run_test",
    "pokaż status": "show_status",
    "lista formularzy": "list_forms",
    "wybierz model": "select_model",
    "pomoc": "help"
}


@app.route('/health', methods=['GET'])
def health_check():
    """Endpoint sprawdzający zdrowie serwisu"""
    return jsonify({"status": "healthy", "service": "web-voice-api"})


@app.route('/process-audio', methods=['POST'])
def process_audio():
    """
    Proces plik audio i rozpoznaj mowę

    Obsługiwane formaty:
    - Base64 encoded audio data
    - Audio file upload
    """
    try:
        if 'audio' not in request.files and 'audio_data' not in request.json:
            return jsonify({"error": "No audio file or data provided"}), 400

        audio_data = None
        if 'audio' in request.files:
            # Obsługa przesłanego pliku
            audio_file = request.files['audio']
            audio_data = audio_file.read()
        elif 'audio_data' in request.json:
            # Obsługa danych base64
            import base64
            audio_data = base64.b64decode(request.json['audio_data'])

        # Zapisanie pliku audio do analizy
        audio_id = str(uuid.uuid4())
        audio_path = os.path.join(AUDIO_DIR, f"{audio_id}.wav")

        with open(audio_path, "wb") as f:
            f.write(audio_data)

        # Rozpoznawanie mowy
        recognizer = sr.Recognizer()
        with sr.AudioFile(audio_path) as source:
            audio = recognizer.record(source)

        # Próba rozpoznania mowy w różnych językach
        languages = ["pl-PL", "en-US", "de-DE"]
        recognized_text = None
        recognition_language = None

        for lang in languages:
            try:
                text = recognizer.recognize_google(audio, language=lang)
                recognized_text = text
                recognition_language = lang
                break
            except sr.UnknownValueError:
                continue
            except Exception as e:
                logger.error(f"Error recognizing speech in {lang}: {str(e)}")
                continue

        if not recognized_text:
            return jsonify({
                "success": False,
                "error": "Could not recognize speech in any supported language"
            }), 400

        # Analiza rozpoznanego tekstu pod kątem komend
        command_detected = False
        command_action = None
        command_params = {}

        for key_phrase, action in VOICE_COMMANDS.items():
            if key_phrase.lower() in recognized_text.lower():
                command_detected = True
                command_action = action

                # Ekstrakcja parametrów, np. URL dla "wypełnij formularz [URL]"
                if action == "fill_form" and "formularz" in recognized_text.lower():
                    # Spróbuj wyciągnąć URL
                    parts = recognized_text.lower().split("formularz", 1)
                    if len(parts) > 1 and parts[1].strip():
                        command_params["url"] = parts[1].strip()

                break

        # Przekazanie komendy do API LLM, jeśli wykryto
        execution_result = None
        if command_detected and command_action:
            try:
                response = requests.post(
                    f"{LLM_API_URL}/execute_command",
                    json={
                        "action": command_action,
                        "params": command_params
                    },
                    timeout=10
                )
                if response.status_code == 200:
                    execution_result = response.json()
                else:
                    logger.error(f"Error executing command: {response.text}")
            except Exception as e:
                logger.error(f"Error sending command to LLM API: {str(e)}")

        # Przygotowanie odpowiedzi
        result = {
            "success": True,
            "text": recognized_text,
            "language": recognition_language,
            "command_detected": command_detected,
            "command": command_action if command_detected else None,
            "params": command_params if command_detected else None,
            "execution_result": execution_result
        }

        # Usuwanie pliku audio po przetworzeniu (opcjonalnie)
        if os.path.exists(audio_path):
            # Pozostaw plik dla debugowania lub usuń po przetworzeniu
            # os.remove(audio_path)
            pass

        return jsonify(result)

    except Exception as e:
        logger.error(f"Error processing audio: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/text-to-speech', methods=['POST'])
def text_to_speech():
    """
    Konwertuje tekst na mowę (opcjonalnie)

    Jeśli chcemy zwrócić plik audio z odpowiedzią
    """
    try:
        if 'text' not in request.json:
            return jsonify({"error": "No text provided"}), 400

        text = request.json['text']
        language = request.json.get('language', 'pl-PL')

        # Tu można zaimplementować konwersję tekstu na mowę
        # Np. używając gTTS, pyttsx3 lub odpowiedniego API

        # Przykładowa implementacja z gTTS:
        # from gtts import gTTS
        # tts = gTTS(text=text, lang=language.split('-')[0])
        # audio_id = str(uuid.uuid4())
        # audio_path = os.path.join(AUDIO_DIR, f"{audio_id}.mp3")
        # tts.save(audio_path)

        # Zwracamy informację, że należy użyć Web Speech API w przeglądarce
        return jsonify({
            "success": True,
            "message": "Text-to-speech should be handled by Web Speech API in the browser"
        })

    except Exception as e:
        logger.error(f"Error in text-to-speech: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/execute-command', methods=['POST'])
def execute_command():
    """
    Wykonuje komendę głosową bezpośrednio (bez rozpoznawania mowy)

    Używane przez interfejs webowy, gdy rozpoznawanie jest już zrobione w przeglądarce
    """
    try:
        if 'command' not in request.json:
            return jsonify({"error": "No command provided"}), 400

        command = request.json['command']
        params = request.json.get('params', {})

        # Przekazanie komendy do API LLM
        try:
            response = requests.post(
                f"{LLM_API_URL}/execute_command",
                json={
                    "action": command,
                    "params": params
                },
                timeout=10
            )
            if response.status_code == 200:
                return jsonify({
                    "success": True,
                    "result": response.json()
                })
            else:
                logger.error(f"Error executing command: {response.text}")
                return jsonify({
                    "success": False,
                    "error": f"Error executing command: {response.text}"
                }), response.status_code
        except Exception as e:
            logger.error(f"Error sending command to LLM API: {str(e)}")
            return jsonify({
                "success": False,
                "error": f"Error sending command to LLM API: {str(e)}"
            }), 500

    except Exception as e:
        logger.error(f"Error in execute-command: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500


def create_app():
    return app


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=6000, debug=False)