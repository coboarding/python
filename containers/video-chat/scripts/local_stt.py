#!/usr/bin/env python3
"""
Skrypt do rozpoznawania mowy z pliku audio przy użyciu lokalnych narzędzi
Używa speech_recognition z modelem od Google (wymaga internetu)

Użycie:
    python local_stt.py /ścieżka/do/pliku.wav "pl-PL"
"""

import sys
import os
import speech_recognition as sr


def speech_to_text(audio_path, language):
    """Rozpoznaje mowę z pliku audio i zwraca rozpoznany tekst"""

    recognizer = sr.Recognizer()

    try:
        with sr.AudioFile(audio_path) as source:
            audio_data = recognizer.record(source)

            # Próbujemy rozpoznać mowę
            text = recognizer.recognize_google(audio_data, language=language)
            return text
    except sr.UnknownValueError:
        return "Nie rozpoznano mowy"
    except sr.RequestError as e:
        return f"Błąd API: {str(e)}"
    except Exception as e:
        return f"Błąd: {str(e)}"


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Użycie: python local_stt.py /ścieżka/do/pliku.wav \"pl-PL\"")
        sys.exit(1)

    audio_path = sys.argv[1]
    language = sys.argv[2]

    if not os.path.exists(audio_path):
        print(f"Plik {audio_path} nie istnieje")
        sys.exit(1)

    try:
        result = speech_to_text(audio_path, language)
        print(result)
        sys.exit(0)
    except Exception as e:
        print(f"Błąd: {str(e)}")
        sys.exit(1)