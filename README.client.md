# coBoarding – Dokumentacja Klienta

## Spis treści
- [Opis systemu](#opis-systemu)
- [Szybki start](#szybki-start)
- [Konfiguracja poczty email](#konfiguracja-poczty-email)
- [Wysyłanie zgłoszeń i powiadomień](#wysylanie-zgloszen-i-powiadomien)
- [FAQ](#faq)
- [Wsparcie i kontakt](#wsparcie-i-kontakt)

---

## Opis systemu
coBoarding to system automatyzujący wypełnianie formularzy rekrutacyjnych oraz wysyłanie powiadomień email. Umożliwia szybkie przesyłanie zgłoszeń, odbieranie kodów logowania i śledzenie statusów aplikacji.

## Szybki start
1. Skopiuj wybrany plik `.env.gmail`, `.env.ms` lub `.env.prv` do `.env` i uzupełnij swoimi danymi.
2. Uruchom system zgodnie z instrukcją od dostawcy.
3. Wysyłaj zgłoszenia przez interfejs lub API.

## Konfiguracja poczty email
- W pliku `.env` ustaw dane SMTP i IMAP zgodnie z Twoim dostawcą poczty (przykłady w repozytorium).
- Twoje dane są bezpieczne – nie są wysyłane do twórców systemu.

## Wysyłanie zgłoszeń i powiadomień
- Możesz otrzymywać podsumowania zgłoszeń na email (pole `notify_email` w zgłoszeniu).
- Możesz pobierać kody logowania (2FA) automatycznie przez `/get-email-token`.

## FAQ
**Czy moje dane są bezpieczne?**
Tak, dane logowania do poczty są trzymane wyłącznie lokalnie w pliku `.env`.

**Jak mogę uzyskać pomoc?**
Napisz do wsparcia technicznego lub sprawdź sekcję [Wsparcie i kontakt](#wsparcie-i-kontakt).

## Wsparcie i kontakt
- Kontakt: support@coboarding.com
- Dokumentacja online: [docs.coboarding.com](https://docs.coboarding.com)
