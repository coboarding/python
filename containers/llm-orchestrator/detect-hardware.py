# llm-orchestrator/detect-hardware.py
import torch
import json
import os
import psutil
import GPUtil


def detect_hardware():
    """Wykrywa dostępny sprzęt i zwraca rekomendacje dla modeli LLM"""
    result = {
        "cpu": {
            "cores": psutil.cpu_count(logical=False),
            "threads": psutil.cpu_count(logical=True),
            "memory_gb": round(psutil.virtual_memory().total / (1024 ** 3), 2)
        },
        "gpu": [],
        "recommended_models": []
    }

    # Wykrywanie GPU
    if torch.cuda.is_available():
        for i in range(torch.cuda.device_count()):
            gpu_info = GPUtil.getGPUs()[i]
            result["gpu"].append({
                "name": torch.cuda.get_device_name(i),
                "memory_gb": round(gpu_info.memoryTotal / 1024, 2),
                "cuda_capability": torch.cuda.get_device_capability(i)
            })

    # Rekomendacje modeli
    if len(result["gpu"]) > 0:
        gpu_mem = result["gpu"][0]["memory_gb"]
        if gpu_mem >= 24:  # High-end GPU (24GB+)
            result["recommended_models"] = [
                {"name": "llama-3-70b-gguf", "purpose": "Zaawansowana analiza formularzy i tłumaczenia",
                 "ram_required": "32GB", "best_for": "Kompleksowe formularze i wielojęzyczność"},
                {"name": "mistral-large-gguf", "purpose": "Ogólna analiza formularzy", "ram_required": "16GB",
                 "best_for": "Wszystkie rodzaje formularzy"}
            ]
        elif gpu_mem >= 8:  # Mid-range GPU (8GB+)
            result["recommended_models"] = [
                {"name": "llama-3-8b-gguf", "purpose": "Dobra analiza formularzy i tłumaczenia", "ram_required": "8GB",
                 "best_for": "Większość formularzy i wielojęzyczność"},
                {"name": "mistral-7b-gguf", "purpose": "Analiza formularzy", "ram_required": "8GB",
                 "best_for": "Standardowe formularzy, szybkie działanie"}
            ]
        else:  # Basic GPU
            result["recommended_models"] = [
                {"name": "phi-2-gguf", "purpose": "Podstawowa analiza formularzy", "ram_required": "4GB",
                 "best_for": "Proste formularze, dobra wydajność"}
            ]
    else:  # CPU only
        cpu_mem = result["cpu"]["memory_gb"]
        if cpu_mem >= 16:
            result["recommended_models"] = [
                {"name": "mistral-7b-q4-gguf", "purpose": "Analiza formularzy (skwantyzowana)", "ram_required": "8GB",
                 "best_for": "Formularze wielojęzyczne, dobra jakość"},
                {"name": "phi-2-q4-gguf", "purpose": "Szybka analiza", "ram_required": "4GB",
                 "best_for": "Proste formularze, wysoka wydajność na CPU"}
            ]
        else:
            result["recommended_models"] = [
                {"name": "phi-2-q4-gguf", "purpose": "Minimalistyczna analiza", "ram_required": "4GB",
                 "best_for": "Podstawowe formularze"},
                {"name": "tiny-llama-1b-gguf", "purpose": "Bardzo szybka analiza", "ram_required": "2GB",
                 "best_for": "Najprostsze formularze, minimalne zasoby"}
            ]

    return result


if __name__ == "__main__":
    hardware_info = detect_hardware()
    with open("/app/config/hardware-info.json", "w") as f:
        json.dump(hardware_info, f, indent=2)

    print("Dostępne modele LLM dopasowane do Twojego sprzętu:")
    for i, model in enumerate(hardware_info["recommended_models"]):
        print(f"[{i + 1}] {model['name']}")
        print(f"    Przeznaczenie: {model['purpose']}")
        print(f"    Wymagana RAM: {model['ram_required']}")
        print(f"    Najlepszy do: {model['best_for']}")
        print()