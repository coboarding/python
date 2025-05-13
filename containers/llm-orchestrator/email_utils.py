import imaplib
import email
from email.header import decode_header
import re
from typing import Optional
import os

def get_latest_token_from_email(
    imap_server: str,
    email_user: str,
    email_pass: str,
    mailbox: str = "INBOX",
    search_subject: Optional[str] = None,
    token_regex: str = r"\\b\d{6}\\b"
) -> Optional[str]:
    """
    Pobiera najnowszy token (np. kod 2FA) ze skrzynki email.
    :param imap_server: adres serwera IMAP
    :param email_user: login do skrzynki
    :param email_pass: hasło do skrzynki
    :param mailbox: skrzynka (domyślnie INBOX)
    :param search_subject: opcjonalny filtr po temacie
    :param token_regex: regex do wyłuskania tokenu (domyślnie 6-cyfrowy kod)
    :return: token lub None
    """
    mail = imaplib.IMAP4_SSL(imap_server)
    mail.login(email_user, email_pass)
    mail.select(mailbox)
    search_criteria = '(UNSEEN)'
    if search_subject:
        search_criteria = f'(UNSEEN SUBJECT "{search_subject}")'
    status, messages = mail.search(None, search_criteria)
    if status != 'OK':
        return None
    for num in reversed(messages[0].split()):
        status, data = mail.fetch(num, '(RFC822)')
        if status != 'OK':
            continue
        msg = email.message_from_bytes(data[0][1])
        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() == "text/plain":
                    body = part.get_payload(decode=True).decode(errors='ignore')
                    break
            else:
                continue
        else:
            body = msg.get_payload(decode=True).decode(errors='ignore')
        match = re.search(token_regex, body)
        if match:
            return match.group(0)
    return None
