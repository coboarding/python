FROM alpine:3.16

# Instalacja zależności
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    python3 \
    py3-pip \
    git \
    nodejs \
    npm \
    ttyd \
    openssh-client \
    jq \
    make \
    gcc \
    g++ \
    libc-dev \
    python3-dev

# Instalacja zależności Python
VOLUME /root/.cache/pip
RUN pip3 install --cache-dir=/root/.cache/pip rich requests colorama tabulate pyfiglet argcomplete

# Kopiowanie skryptu startowego
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Ekspozycja portu ttyd
EXPOSE 7681

# Uruchomienie ttyd
ENTRYPOINT ["/usr/local/bin/startup.sh"]