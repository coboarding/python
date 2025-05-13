#!/usr/bin/env python3
"""
Model Service - Mikrousługa odpowiedzialna za obsługę modelu LLM
"""
import os
import json
import logging
from typing import Dict, Any, Optional

from flask import Flask, request, jsonify
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

# Konfiguracja logowania
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("model-service")

# Inicjalizacja Flask
app = Flask(__name__)

# Konfiguracja z zmiennych środowiskowych
MODEL_PATH = os.environ.get("MODEL_PATH", "/app/models/tinyllama")
USE_INT8 = os.environ.get("USE_INT8", "true").lower() == "true"
PORT = int(os.environ.get("MODEL_SERVICE_PORT", 5000))
MAX_LENGTH = int(os.environ.get("MAX_LENGTH", 512))
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# Globalne zmienne dla modelu i tokenizera
model = None
tokenizer = None


def load_model():
    """Ładuje model i tokenizer."""
    global model, tokenizer
    
    logger.info(f"Ładowanie modelu z {MODEL_PATH}...")
    logger.info(f"Optymalizacje: USE_INT8={USE_INT8}, DEVICE={DEVICE}")
    
    # Ładowanie tokenizera
    tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH)
    
    # Ładowanie modelu z optymalizacjami
    if USE_INT8:
        model = AutoModelForCausalLM.from_pretrained(
            MODEL_PATH,
            device_map=DEVICE,
            load_in_8bit=True,
            torch_dtype=torch.float16
        )
    else:
        model = AutoModelForCausalLM.from_pretrained(
            MODEL_PATH,
            device_map=DEVICE,
            torch_dtype=torch.float16
        )
    
    logger.info("Model załadowany pomyślnie")


@app.route('/health', methods=['GET'])
def health_check():
    """Endpoint do sprawdzania stanu usługi."""
    if model is None or tokenizer is None:
        return jsonify({"status": "error", "message": "Model not loaded"}), 503
    
    return jsonify({"status": "ok", "model": MODEL_PATH}), 200


@app.route('/predict', methods=['POST'])
def predict():
    """Endpoint do generowania tekstu."""
    if model is None or tokenizer is None:
        return jsonify({"error": "Model not loaded"}), 503
    
    # Pobieranie danych z żądania
    data = request.json
    if not data or "prompt" not in data:
        return jsonify({"error": "No prompt provided"}), 400
    
    prompt = data["prompt"]
    max_length = data.get("max_length", MAX_LENGTH)
    temperature = data.get("temperature", 0.7)
    
    try:
        # Tokenizacja i generowanie
        inputs = tokenizer(prompt, return_tensors="pt").to(DEVICE)
        
        # Generowanie tekstu
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_length=max_length,
                temperature=temperature,
                do_sample=True,
                pad_token_id=tokenizer.eos_token_id
            )
        
        # Dekodowanie wyniku
        generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Zwracanie wyniku
        return jsonify({
            "generated_text": generated_text,
            "prompt": prompt
        }), 200
    
    except Exception as e:
        logger.error(f"Error during prediction: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/model-info', methods=['GET'])
def model_info():
    """Endpoint do pobierania informacji o modelu."""
    if model is None:
        return jsonify({"error": "Model not loaded"}), 503
    
    info = {
        "model_path": MODEL_PATH,
        "device": DEVICE,
        "int8_enabled": USE_INT8,
        "max_length": MAX_LENGTH,
        "parameters": sum(p.numel() for p in model.parameters())
    }
    
    return jsonify(info), 200


if __name__ == '__main__':
    # Ładowanie modelu przy starcie
    load_model()
    
    # Uruchomienie serwera Flask
    logger.info(f"Uruchamianie serwisu modelu na porcie {PORT}...")
    app.run(host='0.0.0.0', port=PORT)
