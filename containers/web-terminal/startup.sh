#!/bin/bash

# Funkcja inicjalizacji interfejsu coboarding
init_interface() {
    python3 -c "
import pyfiglet
from colorama import Fore, Style, init
init()
print(Fore.CYAN + pyfiglet.figlet_format('coboarding', font='slant') + Style.RESET_ALL)
print(Fore.GREEN + 'Terminal webowy gotowy. Wpisz \"help\" aby zobaczyć dostępne komendy.' + Style.RESET_ALL)
"
}

# Inicjalizacja interfejsu przy starcie
init_interface

# Kopiowanie skryptów komend do /usr/local/bin
if [ -d "/volumes/commands" ]; then
    for script in /volumes/commands/*.py; do
        if [ -f "$script" ]; then
            chmod +x "$script"
            ln -sf "$script" "/usr/local/bin/$(basename "$script" .py)"
        fi
    done
fi

# Uruchomienie ttyd z dostępem do poleceń bash
exec ttyd -p 7681 -t fontSize=14 -t theme={'background':'#1e1e1e'} /bin/bash