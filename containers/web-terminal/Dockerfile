# web-terminal/Dockerfile
FROM tsl0922/ttyd:latest

# Dodaj pomocnicze narzędzia
RUN apk add --no-cache bash curl jq python3 py3-pip

# Instalacja potrzebnych pakietów Pythona
RUN pip3 install --no-cache-dir requests pyfiglet colorama

# Kopiowanie skryptu startowego
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Ekspozycja portu
EXPOSE 7681

# Uruchomienie terminala z naszym interfejsem
ENTRYPOINT ["/usr/local/bin/startup.sh"]