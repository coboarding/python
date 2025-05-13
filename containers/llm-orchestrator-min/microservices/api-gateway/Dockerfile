FROM traefik:v2.9

# Kopiowanie konfiguracji
COPY traefik.yml /etc/traefik/traefik.yml
COPY dynamic_conf.yml /etc/traefik/dynamic_conf.yml

# Ekspozycja portów
EXPOSE 80
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ping || exit 1

# Uruchomienie Traefik
ENTRYPOINT ["traefik"]
