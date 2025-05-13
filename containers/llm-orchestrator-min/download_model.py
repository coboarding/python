#!/usr/bin/env python3

import os
import sys
from transformers import AutoTokenizer, AutoModelForCausalLM

def download_model(model_name, output_dir):
    """
    Pobiera model i tokenizer z Hugging Face Hub i zapisuje je lokalnie.
    
    Args:
        model_name: Nazwa modelu na Hugging Face Hub
        output_dir: Katalog docelowy do zapisania modelu
    """
    print(f"Pobieranie modelu {model_name}...")
    
    # Tworzenie katalogu docelowego, jeśli nie istnieje
    os.makedirs(output_dir, exist_ok=True)
    
    # Pobieranie tokenizera
    print("Pobieranie tokenizera...")
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    tokenizer.save_pretrained(output_dir)
    print("Tokenizer został pobrany i zapisany.")
    
    # Pobieranie modelu
    print("Pobieranie modelu (to może potrwać kilka minut)...")
    model = AutoModelForCausalLM.from_pretrained(model_name)
    model.save_pretrained(output_dir)
    print("Model został pobrany i zapisany.")
    
    # Sprawdzenie, czy wszystkie pliki zostały pobrane
    print("\nSprawdzanie pobranych plików:")
    files = os.listdir(output_dir)
    for file in files:
        file_path = os.path.join(output_dir, file)
        file_size = os.path.getsize(file_path)
        print(f"- {file}: {file_size} bajtów")
    
    print(f"\nModel został pomyślnie pobrany do katalogu: {output_dir}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Użycie: python download_model.py <model_name> <output_dir>")
        print("Przykład: python download_model.py TinyLlama/TinyLlama-1.1B-Chat-v1.0 ./models/tinyllama")
        sys.exit(1)
    
    model_name = sys.argv[1]
    output_dir = sys.argv[2]
    
    download_model(model_name, output_dir)
