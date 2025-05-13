#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Kompleksowy skrypt testowy dla API LLM-Orchestrator-Min
Autor: Tom
Data: 2025-05-13
"""

import argparse
import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from typing import Dict, List, Optional, Tuple, Union

import requests
from requests.exceptions import RequestException

# Konfiguracja
DEFAULT_API_URL = "http://localhost:5000"
DEFAULT_TIMEOUT = 30  # sekundy
DEFAULT_CONCURRENCY = 2
DEFAULT_REQUESTS = 5


class ColorOutput:
    """Klasa do kolorowego wyświetlania tekstu w terminalu."""
    
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    
    @staticmethod
    def print_color(text: str, color: str) -> None:
        """Wyświetla tekst w kolorze."""
        print(f"{color}{text}{ColorOutput.ENDC}")
    
    @staticmethod
    def success(text: str) -> None:
        """Wyświetla komunikat sukcesu."""
        ColorOutput.print_color(f"✓ {text}", ColorOutput.GREEN)
    
    @staticmethod
    def error(text: str) -> None:
        """Wyświetla komunikat błędu."""
        ColorOutput.print_color(f"✗ {text}", ColorOutput.RED)
    
    @staticmethod
    def warning(text: str) -> None:
        """Wyświetla ostrzeżenie."""
        ColorOutput.print_color(f"! {text}", ColorOutput.YELLOW)
    
    @staticmethod
    def info(text: str) -> None:
        """Wyświetla informację."""
        ColorOutput.print_color(f"ℹ {text}", ColorOutput.BLUE)
    
    @staticmethod
    def header(text: str) -> None:
        """Wyświetla nagłówek."""
        print()
        ColorOutput.print_color(f"=== {text} ===", ColorOutput.HEADER + ColorOutput.BOLD)
        print()


class APITester:
    """Klasa do testowania API LLM-Orchestrator-Min."""
    
    def __init__(
        self,
        api_url: str = DEFAULT_API_URL,
        timeout: int = DEFAULT_TIMEOUT,
        verbose: bool = False
    ):
        """Inicjalizacja testera API."""
        self.api_url = api_url
        self.timeout = timeout
        self.verbose = verbose
        self.results = {
            "passed": 0,
            "failed": 0,
            "skipped": 0,
            "total": 0,
            "tests": []
        }
    
    def _make_request(
        self,
        endpoint: str,
        method: str = "GET",
        data: Optional[Dict] = None,
        expected_status: int = 200,
        description: str = ""
    ) -> Tuple[bool, Dict]:
        """Wykonuje żądanie HTTP do API."""
        url = f"{self.api_url}{endpoint}"
        result = {
            "endpoint": endpoint,
            "method": method,
            "data": data,
            "expected_status": expected_status,
            "description": description,
            "passed": False,
            "response": None,
            "error": None,
            "status_code": None,
            "response_time": 0
        }
        
        try:
            start_time = time.time()
            
            if method.upper() == "GET":
                response = requests.get(url, timeout=self.timeout)
            elif method.upper() == "POST":
                headers = {"Content-Type": "application/json"}
                response = requests.post(
                    url, json=data, headers=headers, timeout=self.timeout
                )
            else:
                result["error"] = f"Nieobsługiwana metoda: {method}"
                return False, result
            
            result["response_time"] = round((time.time() - start_time) * 1000, 2)  # ms
            result["status_code"] = response.status_code
            
            try:
                result["response"] = response.json()
            except ValueError:
                result["response"] = response.text
            
            result["passed"] = response.status_code == expected_status
            return result["passed"], result
        
        except RequestException as e:
            result["error"] = str(e)
            return False, result
    
    def run_test(
        self,
        endpoint: str,
        method: str = "GET",
        data: Optional[Dict] = None,
        expected_status: int = 200,
        description: str = ""
    ) -> bool:
        """Uruchamia pojedynczy test API."""
        self.results["total"] += 1
        
        if not description:
            description = f"{method} {endpoint}"
        
        if self.verbose:
            ColorOutput.info(f"Uruchamianie testu: {description}")
        
        passed, result = self._make_request(
            endpoint, method, data, expected_status, description
        )
        
        self.results["tests"].append(result)
        
        if passed:
            self.results["passed"] += 1
            if self.verbose:
                ColorOutput.success(
                    f"Test zaliczony: {description} ({result['response_time']} ms)"
                )
        else:
            self.results["failed"] += 1
            if self.verbose:
                ColorOutput.error(
                    f"Test niezaliczony: {description} "
                    f"(oczekiwano: {expected_status}, otrzymano: {result['status_code']})"
                )
                if result["error"]:
                    ColorOutput.error(f"Błąd: {result['error']}")
        
        return passed
    
    def run_load_test(
        self,
        endpoint: str,
        method: str = "POST",
        data: Dict = None,
        concurrency: int = DEFAULT_CONCURRENCY,
        num_requests: int = DEFAULT_REQUESTS
    ) -> Dict:
        """Uruchamia test obciążeniowy API."""
        ColorOutput.header(f"Test obciążeniowy: {concurrency} równoległych żądań, {num_requests} łącznie")
        
        if data is None:
            data = {"prompt": "Hello, how are you?", "max_length": 50}
        
        results = {
            "total_requests": num_requests,
            "successful_requests": 0,
            "failed_requests": 0,
            "avg_response_time": 0,
            "min_response_time": float("inf"),
            "max_response_time": 0,
            "response_times": []
        }
        
        def make_request(_):
            passed, result = self._make_request(endpoint, method, data)
            return passed, result
        
        start_time = time.time()
        
        with ThreadPoolExecutor(max_workers=concurrency) as executor:
            futures = [executor.submit(make_request, i) for i in range(num_requests)]
            for future in futures:
                passed, result = future.result()
                
                if passed:
                    results["successful_requests"] += 1
                else:
                    results["failed_requests"] += 1
                
                if "response_time" in result:
                    response_time = result["response_time"]
                    results["response_times"].append(response_time)
                    results["min_response_time"] = min(results["min_response_time"], response_time)
                    results["max_response_time"] = max(results["max_response_time"], response_time)
        
        total_time = time.time() - start_time
        
        if results["response_times"]:
            results["avg_response_time"] = sum(results["response_times"]) / len(results["response_times"])
        
        if results["min_response_time"] == float("inf"):
            results["min_response_time"] = 0
        
        ColorOutput.info(f"Całkowity czas testu: {round(total_time, 2)} s")
        ColorOutput.info(f"Średni czas odpowiedzi: {round(results['avg_response_time'], 2)} ms")
        ColorOutput.info(f"Min czas odpowiedzi: {round(results['min_response_time'], 2)} ms")
        ColorOutput.info(f"Max czas odpowiedzi: {round(results['max_response_time'], 2)} ms")
        
        success_rate = (results["successful_requests"] / results["total_requests"]) * 100
        ColorOutput.info(f"Współczynnik powodzenia: {round(success_rate, 2)}%")
        
        if success_rate >= 90:
            ColorOutput.success("Test obciążeniowy zaliczony")
        else:
            ColorOutput.error("Test obciążeniowy niezaliczony")
        
        return results
    
    def run_standard_tests(self) -> None:
        """Uruchamia standardowy zestaw testów API."""
        ColorOutput.header("Uruchamianie standardowych testów API")
        
        # Test 1: Endpoint zdrowia
        self.run_test(
            "/api/health",
            description="Sprawdzenie endpointu zdrowia"
        )
        
        # Test 2: Generowanie tekstu
        self.run_test(
            "/api/generate",
            method="POST",
            data={"prompt": "Hello, how are you?", "max_length": 50},
            description="Generowanie tekstu z prawidłowymi parametrami"
        )
        
        # Test 3: Generowanie tekstu z nieprawidłowymi danymi
        self.run_test(
            "/api/generate",
            method="POST",
            data={"invalid": "data"},
            expected_status=400,
            description="Generowanie tekstu z nieprawidłowymi parametrami"
        )
        
        # Test 4: Nieistniejący endpoint
        self.run_test(
            "/api/nonexistent",
            expected_status=404,
            description="Nieistniejący endpoint"
        )
        
        # Test 5: Generowanie tekstu z pustym promptem
        self.run_test(
            "/api/generate",
            method="POST",
            data={"prompt": "", "max_length": 50},
            expected_status=400,
            description="Generowanie tekstu z pustym promptem"
        )
        
        # Test 6: Generowanie tekstu z bardzo długim promptem
        long_prompt = "Hello " * 1000
        self.run_test(
            "/api/generate",
            method="POST",
            data={"prompt": long_prompt, "max_length": 50},
            description="Generowanie tekstu z bardzo długim promptem"
        )
    
    def print_summary(self) -> None:
        """Wyświetla podsumowanie testów."""
        ColorOutput.header("Podsumowanie testów")
        
        total = self.results["total"]
        passed = self.results["passed"]
        failed = self.results["failed"]
        
        if total == 0:
            ColorOutput.warning("Nie uruchomiono żadnych testów")
            return
        
        success_rate = (passed / total) * 100
        
        ColorOutput.info(f"Łącznie testów: {total}")
        ColorOutput.success(f"Zaliczonych: {passed}")
        ColorOutput.error(f"Niezaliczonych: {failed}")
        ColorOutput.info(f"Współczynnik powodzenia: {round(success_rate, 2)}%")
        
        if success_rate == 100:
            ColorOutput.success("Wszystkie testy zaliczone!")
        elif success_rate >= 80:
            ColorOutput.warning("Większość testów zaliczona, ale są problemy do naprawienia")
        else:
            ColorOutput.error("Znaczna liczba testów niezaliczona, wymagana naprawa API")
    
    def save_results(self, output_file: str) -> None:
        """Zapisuje wyniki testów do pliku JSON."""
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)
        
        ColorOutput.info(f"Wyniki zapisane do pliku: {output_file}")


def main():
    """Główna funkcja programu."""
    parser = argparse.ArgumentParser(description="Tester API LLM-Orchestrator-Min")
    parser.add_argument(
        "--url", default=DEFAULT_API_URL,
        help=f"URL bazowy API (domyślnie: {DEFAULT_API_URL})"
    )
    parser.add_argument(
        "--timeout", type=int, default=DEFAULT_TIMEOUT,
        help=f"Timeout żądań w sekundach (domyślnie: {DEFAULT_TIMEOUT})"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true",
        help="Tryb gadatliwy - wyświetla więcej informacji"
    )
    parser.add_argument(
        "--output", "-o",
        help="Plik wyjściowy do zapisania wyników testów w formacie JSON"
    )
    parser.add_argument(
        "--load-test", action="store_true",
        help="Uruchom test obciążeniowy"
    )
    parser.add_argument(
        "--concurrency", type=int, default=DEFAULT_CONCURRENCY,
        help=f"Liczba równoległych żądań w teście obciążeniowym (domyślnie: {DEFAULT_CONCURRENCY})"
    )
    parser.add_argument(
        "--requests", type=int, default=DEFAULT_REQUESTS,
        help=f"Liczba żądań w teście obciążeniowym (domyślnie: {DEFAULT_REQUESTS})"
    )
    
    args = parser.parse_args()
    
    tester = APITester(args.url, args.timeout, args.verbose)
    
    try:
        # Uruchomienie standardowych testów
        tester.run_standard_tests()
        
        # Uruchomienie testu obciążeniowego
        if args.load_test:
            tester.run_load_test(
                "/api/generate",
                method="POST",
                concurrency=args.concurrency,
                num_requests=args.requests
            )
        
        # Wyświetlenie podsumowania
        tester.print_summary()
        
        # Zapisanie wyników do pliku
        if args.output:
            tester.save_results(args.output)
        
        # Ustalenie kodu wyjścia
        if tester.results["failed"] > 0:
            return 1
        return 0
    
    except KeyboardInterrupt:
        ColorOutput.warning("\nPrzerwano przez użytkownika")
        return 130
    except Exception as e:
        ColorOutput.error(f"Wystąpił nieoczekiwany błąd: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
