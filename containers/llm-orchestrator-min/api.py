import os
import torch
from flask import Flask, request, jsonify
from transformers import AutoModelForCausalLM, AutoTokenizer

app = Flask(__name__)

# Ścieżka do modelu
MODEL_PATH = "/app/models/tinyllama"

# Ładowanie modelu i tokenizera
print("Ładowanie modelu TinyLlama-1.1B...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH)
model = AutoModelForCausalLM.from_pretrained(
    MODEL_PATH,
    torch_dtype=torch.float32,  # Używamy float32 dla CPU
    low_cpu_mem_usage=True
)
print("Model załadowany!")

@app.route('/api/generate', methods=['POST'])
def generate():
    try:
        data = request.json
        prompt = data.get('prompt', '')
        max_length = data.get('max_length', 256)
        
        # Formatowanie promptu dla modelu czatowego
        chat_prompt = f"<human>: {prompt}\n<assistant>:"
        
        # Generowanie odpowiedzi
        inputs = tokenizer(chat_prompt, return_tensors="pt")
        outputs = model.generate(
            inputs.input_ids,
            max_length=max_length,
            temperature=0.7,
            top_p=0.9,
            do_sample=True
        )
        
        # Dekodowanie odpowiedzi
        response = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Wyodrębnienie odpowiedzi asystenta
        assistant_response = response.split("<assistant>:")[-1].strip()
        
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
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
