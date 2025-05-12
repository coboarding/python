#!/bin/bash
# web-terminal/startup.sh

# Funkcja inicjalizacji interfejsu AutoFormFiller
init_interface() {
    python3 -c "
import pyfiglet
from colorama import Fore, Style, init
init()
print(Fore.CYAN + pyfiglet.figlet_format('AutoFormFiller', font='slant') + Style.RESET_ALL)
print(Fore.GREEN + 'Terminal webowy gotowy. Wpisz \"help\" aby zobaczyć dostępne komendy.' + Style.RESET_ALL)
"
}

# Inicjalizacja interfejsu przy starcie
init_interface

# Uruchomienie ttyd z dostępem do poleceń bash
exec ttyd -p 7681 -t fontSize=14 -t theme={'background':'#1e1e1e'} /bin/bash