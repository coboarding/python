import os
import torch
from flask import Flask, request, jsonify
from transformers import AutoModelForCausalLM, AutoTokenizer

app = Flask(__name__)

# Ścieżka do modelu
MODEL_PATH = "/app/models/tinyllama"

# Konfiguracja optymalizacji
USE_INT8 = os.environ.get('USE_INT8', 'true').lower() == 'true'
DEVICE = "cpu"
# Konfiguracja portu API z możliwością zmiany przez zmienną środowiskową
API_PORT = int(os.environ.get('API_PORT', '5000'))

print("Ładowanie modelu TinyLlama-1.1B...")
print(f"Optymalizacje: USE_INT8={USE_INT8}, DEVICE={DEVICE}")
print(f"API będzie dostępne na porcie: {API_PORT}")

# Ładowanie tokenizera
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH)

# Ładowanie modelu z optymalizacjami
model = AutoModelForCausalLM.from_pretrained(
    MODEL_PATH,
    torch_dtype=torch.float32,  # Używamy float32 dla CPU
    low_cpu_mem_usage=True,
    load_in_8bit=USE_INT8,  # Kwantyzacja int8 dla mniejszego zużycia pamięci
    device_map=DEVICE
)

# Optymalizacja pamięci po załadowaniu modelu
torch.cuda.empty_cache() if torch.cuda.is_available() else None
print("Model załadowany i zoptymalizowany!")

@app.route('/api/generate', methods=['POST'])
def generate():
    try:
        data = request.json
        prompt = data.get('prompt', '')
        max_length = data.get('max_length', 256)
        temperature = data.get('temperature', 0.7)
        top_p = data.get('top_p', 0.9)
        
        # Formatowanie promptu dla modelu czatowego
        chat_prompt = f"<human>: {prompt}\n<assistant>:"
        
        # Generowanie odpowiedzi z optymalizacją pamięci
        with torch.no_grad():  # Wyłączamy gradient dla oszczędności pamięci
            inputs = tokenizer(chat_prompt, return_tensors="pt")
            outputs = model.generate(
                inputs.input_ids,
                max_length=max_length,
                temperature=temperature,
                top_p=top_p,
                do_sample=True
            )
        
        # Dekodowanie odpowiedzi
        response = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Wyodrębnienie odpowiedzi asystenta
        assistant_response = response.split("<assistant>:")[-1].strip()
        
        # Zwolnienie pamięci
        del inputs, outputs
        torch.cuda.empty_cache() if torch.cuda.is_available() else None
        
        return jsonify({
            "response": assistant_response,
            "success": True
        })
    except Exception as e:
        return jsonify({
            "error": str(e),
            "success": False
        }), 500

@app.route('/api/health', methods=['GET'])
def health():
    # Dodajemy informacje o zużyciu pamięci
    import psutil
    memory_info = {
        "total_memory_gb": round(psutil.virtual_memory().total / (1024**3), 2),
        "used_memory_gb": round(psutil.virtual_memory().used / (1024**3), 2),
        "percent_used": psutil.virtual_memory().percent
    }
    
    return jsonify({
        "status": "ok",
        "memory_info": memory_info
    })

if __name__ == '__main__':
    # Używamy threaded=False dla mniejszego zużycia pamięci w przypadku małych modeli
    app.run(host='0.0.0.0', port=API_PORT, threaded=False)
