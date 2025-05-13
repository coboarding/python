# containers/voice-interface/app.py
import speech_recognition as sr
import pyttsx3
import json
import requests
from flask import Flask, request, jsonify
try:
    import sounddevice as sd
except ImportError:
    sd = None

app = Flask(__name__)
recognizer = sr.Recognizer()
engine = pyttsx3.init()

# Podstawowe komendy głosowe i ich mapowanie na funkcje
VOICE_COMMANDS = {
    "wypełnij formularz": "fill_form",
    "uruchom test": "run_test",
    "pokaż status": "show_status",
    "lista formularzy": "list_forms",
    "wybierz model": "select_model"
}

def record_audio(duration=5, samplerate=16000):
    if not sd:
        raise ImportError("sounddevice is not installed!")
    import numpy as np
    print("Nagrywanie...")
    audio = sd.rec(int(duration * samplerate), samplerate=samplerate, channels=1, dtype='int16')
    sd.wait()
    return audio

@app.route('/listen', methods=['POST'])
def listen_command():
    """Nasłuchuje komend głosowych i przekształca je w akcje"""
    try:
        audio = record_audio()
        command = recognizer.recognize_google(audio, language="pl-PL")
        print(f"Usłyszano: {command}")

        # Próba dopasowania komendy
        action = None
        params = {}

        for key_phrase, action_name in VOICE_COMMANDS.items():
            if key_phrase in command.lower():
                action = action_name
                # Wyciągnij parametry z komendy
                if "formularz" in key_phrase and "na stronie" in command:
                    url_part = command.split("na stronie")[1].strip()
                    params["url"] = url_part

                break

        if action:
            # Wywołaj odpowiednią akcję
            response = requests.post(
                f"http://llm-orchestrator:5000/execute_command",
                json={"action": action, "params": params}
            )

            result = response.json()
            speak_response(result.get("message", "Zadanie wykonane"))
            return jsonify({"success": True, "action": action, "result": result})
        else:
            speak_response("Nie rozpoznałem komendy")
            return jsonify({"success": False, "error": "Command not recognized"})

    except Exception as e:
        speak_response(f"Wystąpił błąd: {str(e)}")
        return jsonify({"success": False, "error": str(e)})


def speak_response(text):
    """Odczytuje odpowiedź głosowo"""
    engine.say(text)
    engine.runAndWait()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=6000)