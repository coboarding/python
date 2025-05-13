# browser-service/browsers/chrome-setup.sh
#!/bin/bash

# Instalacja Chrome
curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update -q
apt-get install -y google-chrome-stable

# Instalacja wtyczek Chrome
mkdir -p /opt/google/chrome/extensions

# Form Auto Fill - wtyczka do automatycznego wypełniania formularzy
# Kopiowanie pliku CRX (lub instalacja z Chrome Web Store)
echo '{
  "external_crx": "/app/extensions/chrome/form-auto-fill.crx",
  "external_version": "1.0.0"
}' > /opt/google/chrome/extensions/formautofill.json

# Password manager integration - wtyczka do integracji z menedżerami haseł
echo '{
  "external_crx": "/app/extensions/chrome/bitwarden.crx",
  "external_version": "1.0.0"
}' > /opt/google/chrome/extensions/bitwarden.json