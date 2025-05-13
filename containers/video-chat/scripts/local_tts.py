#!/usr/bin/env python3
"""
Skrypt do generowania mowy z tekstu z użyciem lokalnego TTS
Używa pyttsx3 jako silnika TTS

Użycie:
    python local_tts.py "Tekst do odczytania" "pl-PL" /ścieżka/do/pliku.mp3
"""

import sys
import os
import pyttsx3
from pydub import AudioSegment
import io
import tempfile


def text_to_speech(text, language, output_path):
    """Konwertuje tekst na mowę i zapisuje do pliku"""

    # Inicjalizacja silnika TTS
    engine = pyttsx3.init()

    # Ustawienie języka (jeśli dostępny)
    voices = engine.getProperty('voices')
    language_code = language.split('-')[0]

    # Próba dopasowania głosu do języka
    for voice in voices:
        # Sprawdzenie czy język głosu pasuje do żądanego języka
        if language_code.lower() in voice.languages[0].lower():
            engine.setProperty('voice', voice.id)
            break

    # Ustawienia parametrów głosu
    engine.setProperty('rate', 150)  # Szybkość mowy
    engine.setProperty('volume', 0.9)  # Głośność

    # Generacja mowy do pliku tymczasowego
    temp_file = tempfile.NamedTemporaryFile(suffix='.wav', delete=False)
    temp_file.close()

    engine.save_to_file(text, temp_file.name)
    engine.runAndWait()

    # Konwersja WAV do MP3
    audio = AudioSegment.from_wav(temp_file.name)
    audio.export(output_path, format="mp3")

    # Usunięcie pliku tymczasowego
    os.remove(temp_file.name)

    return True


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Użycie: python local_tts.py \"Tekst do odczytania\" \"pl-PL\" /ścieżka/do/pliku.mp3")
        sys.exit(1)

    text = sys.argv[1]
    language = sys.argv[2]
    output_path = sys.argv[3]

    try:
        result = text_to_speech(text, language, output_path)
        if result:
            print(f"Plik audio został wygenerowany: {output_path}")
            sys.exit(0)
        else:
            print("Błąd podczas generowania mowy")
            sys.exit(1)
    except Exception as e:
        print(f"Błąd: {str(e)}")
        sys.exit(1)