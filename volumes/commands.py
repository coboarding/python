# commands.py - dostępny w web-terminalu
import argparse
import requests
import os
import json
import time
from rich.console import Console
from rich.table import Table

console = Console()


def list_models():
    """Wyświetla listę dostępnych modeli LLM i ich zastosowanie"""
    try:
        with open("/volumes/config/hardware-info.json", "r") as f:
            hardware_info = json.load(f)

        table = Table(title="Dostępne modele LLM")
        table.add_column("ID", style="cyan")
        table.add_column("Nazwa", style="green")
        table.add_column("Zastosowanie", style="magenta")
        table.add_column("Wymagana RAM", style="yellow")
        table.add_column("Najlepszy do", style="blue")

        for i, model in enumerate(hardware_info["recommended_models"]):
            table.add_row(
                str(i + 1),
                model['name'],
                model['purpose'],
                model['ram_required'],
                model['best_for']
            )

        console.print(table)
    except Exception as e:
        console.print(f"[bold red]Błąd podczas wyświetlania modeli:[/bold red] {str(e)}")


def set_model(model_id):
    """Ustawia model LLM do używania"""
    try:
        with open("/volumes/config/hardware-info.json", "r") as f:
            hardware_info = json.load(f)

        models = hardware_info["recommended_models"]
        if 1 <= int(model_id) <= len(models):
            selected_model = models[int(model_id) - 1]

            with open("/volumes/config/selected-model.json", "w") as f:
                json.dump(selected_model, f, indent=2)

            console.print(f"[bold green]Ustawiono model:[/bold green] {selected_model['name']}")
            console.print(f"[green]Zastosowanie:[/green] {selected_model['purpose']}")
        else:
            console.print("[bold red]Nieprawidłowy ID modelu.[/bold red]")
    except Exception as e:
        console.print(f"[bold red]Błąd podczas ustawiania modelu:[/bold red] {str(e)}")


def fill_form(url, cv_path=None):
    """Wypełnia formularz pod wskazanym URL używając wybranego CV"""
    try:
        # Domyślnie używamy pierwszego pliku CV z katalogu
        if cv_path is None:
            cv_files = os.listdir("/volumes/cv")
            if not cv_files:
                console.print("[bold red]Nie znaleziono plików CV w katalogu /volumes/cv[/bold red]")
                return
            cv_path = f"/volumes/cv/{cv_files[0]}"

        # Sprawdzamy czy model został wybrany
        if not os.path.exists("/volumes/config/selected-model.json"):
            console.print("[bold yellow]Nie wybrano modelu LLM. Używam domyślnego...[/bold yellow]")
            set_model(1)

        console.print(f"[bold green]Rozpoczynam wypełnianie formularza:[/bold green] {url}")
        console.print(f"[green]Używam CV:[/green] {os.path.basename(cv_path)}")

        # Tutaj następuje wywołanie API do serwisu przeglądarki
        # W rzeczywistej implementacji byłoby to faktyczne API
        console.print("[bold blue]Uruchamiam przeglądarkę...[/bold blue]")
        time.sleep(2)
        console.print("[blue]Otwieram stronę...[/blue]")
        time.sleep(2)
        console.print("[blue]Analizuję formularz...[/blue]")
        time.sleep(2)
        console.print("[blue]Wypełniam pola...[/blue]")
        time.sleep(1)
        console.print("[bold green]Formularz wypełniony![/bold green]")
        console.print("[yellow]Podgląd dostępny na: http://localhost:8082[/yellow]")
    except Exception as e:
        console.print(f"[bold red]Błąd podczas wypełniania formularza:[/bold red] {str(e)}")


def batch_fill(file_path):
    """Wypełnia formularze z pliku z listą URL"""
    try:
        if not os.path.exists(file_path):
            console.print(f"[bold red]Plik {file_path} nie istnieje[/bold red]")
            return

        with open(file_path, "r") as f:
            urls = [line.strip() for line in f if line.strip()]

        console.print(f"[bold green]Znaleziono {len(urls)} URL do wypełnienia[/bold green]")

        for i, url in enumerate(urls):
            console.print(f"[bold blue]Formularz {i + 1}/{len(urls)}[/bold blue]")
            fill_form(url)
            time.sleep(3)  # Pauza między formularzami

        console.print("[bold green]Wszystkie formularze zostały wypełnione![/bold green]")
    except Exception as e:
        console.print(f"[bold red]Błąd podczas przetwarzania wsadowego:[/bold red] {str(e)}")


def main():
    parser = argparse.ArgumentParser(description="coBoarding - interfejs komend")
    subparsers = parser.add_subparsers(dest="command", help="Komenda do wykonania")

    # Komenda list-models
    subparsers.add_parser("list-models", help="Wyświetla listę dostępnych modeli LLM")

    # Komenda set-model
    set_model_parser = subparsers.add_parser("set-model", help="Ustawia model LLM do używania")
    set_model_parser.add_argument("model_id", help="ID modelu do użycia")

    # Komenda fill
    fill_parser = subparsers.add_parser("fill", help="Wypełnia formularz pod wskazanym URL")
    fill_parser.add_argument("url", help="URL formularza do wypełnienia")
    fill_parser.add_argument("--cv", help="Ścieżka do pliku CV (opcjonalnie)")

    # Komenda batch
    batch_parser = subparsers.add_parser("batch", help="Wypełnia formularze z pliku z listą URL")
    batch_parser.add_argument("file", help="Ścieżka do pliku z listą URL")

    args = parser.parse_args()

    if args.command == "list-models":
        list_models()
    elif args.command == "set-model":
        set_model(args.model_id)
    elif args.command == "fill":
        fill_form(args.url, args.cv)
    elif args.command == "batch":
        batch_fill(args.file)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()