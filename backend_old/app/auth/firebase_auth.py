from firebase_admin import auth


def verify_firebase_token(token: str) -> str:
    """Verify a Firebase ID token and return the user ID."""
    decoded_token = auth.verify_id_token(token)
    return decoded_token.get("uid", "")