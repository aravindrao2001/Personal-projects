import re


EMAIL_PATTERN = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")
PHONE_PATTERN = re.compile(r"\b(?:\+?\d[\d\s\-()]{7,}\d)\b")

PROFANITY_WORDS = {"damn", "hell"}


def redact_basic_pii(text: str) -> str:
    text = EMAIL_PATTERN.sub("[REDACTED_EMAIL]", text)
    text = PHONE_PATTERN.sub("[REDACTED_PHONE]", text)
    return text


def redact_profanity_stub(text: str) -> str:
    words = text.split()
    cleaned = []
    for w in words:
        if w.lower().strip(".,!?") in PROFANITY_WORDS:
            cleaned.append("[REDACTED_PROFANITY]")
        else:
            cleaned.append(w)
    return " ".join(cleaned)


def sanitize_user_input(text: str) -> str:
    text = redact_basic_pii(text)
    text = redact_profanity_stub(text)
    return text.strip()