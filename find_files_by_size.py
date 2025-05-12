import os
import argparse


def find_files_by_size(directory, min_size=0, max_size=float('inf')):
    """
    Wyszukuje pliki w podanym katalogu (i podkatalogach), które mieszczą się
    w określonym przedziale rozmiaru.

    Args:
        directory (str): Ścieżka do katalogu, który chcemy przeszukać
        min_size (int): Minimalny rozmiar pliku w bajtach (domyślnie 0)
        max_size (int): Maksymalny rozmiar pliku w bajtach (domyślnie nieskończoność)

    Returns:
        list: Lista znalezionych plików z ich rozmiarami
    """
    matches = []

    for root, _, files in os.walk(directory):
        for filename in files:
            filepath = os.path.join(root, filename)
            try:
                file_size = os.path.getsize(filepath)
                if min_size <= file_size <= max_size:
                    matches.append((filepath, file_size))
            except (OSError, FileNotFoundError):
                # Pomijamy pliki, do których nie mamy dostępu
                pass

    return matches


def main():
    parser = argparse.ArgumentParser(description='Wyszukaj pliki o określonym rozmiarze w folderach.')
    parser.add_argument('directories', nargs='+', help='Ścieżki do folderów do przeszukania')
    parser.add_argument('--min', type=int, default=0, help='Minimalny rozmiar pliku w bajtach')
    parser.add_argument('--max', type=int, default=float('inf'), help='Maksymalny rozmiar pliku w bajtach')
    parser.add_argument('--sort', choices=['name', 'size'], default='name',
                        help='Sortowanie wyników (według nazwy lub rozmiaru)')

    args = parser.parse_args()

    all_matches = []
    for directory in args.directories:
        if os.path.exists(directory) and os.path.isdir(directory):
            matches = find_files_by_size(directory, args.min, args.max)
            all_matches.extend(matches)
        else:
            print(f"Ostrzeżenie: Katalog '{directory}' nie istnieje lub nie jest katalogiem.")

    # Sortowanie wyników
    if args.sort == 'name':
        all_matches.sort(key=lambda x: x[0])
    else:  # sort by size
        all_matches.sort(key=lambda x: x[1])

    # Wyświetlenie wyników
    if all_matches:
        print(f"\nZnaleziono {len(all_matches)} plików spełniających kryteria:")
        for filepath, size in all_matches:
            print(f"{size:,} bajtów: {filepath}")
    else:
        print("Nie znaleziono plików spełniających podane kryteria.")


if __name__ == "__main__":
    main()

# python find_files_by_size.py ./ --min 1 --max 120