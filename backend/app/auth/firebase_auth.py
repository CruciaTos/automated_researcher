"""
app/auth/firebase_auth.py — Firebase ID token verification.

IMPORTANT — Prerequisites before this module will work:
  1. Set the GOOGLE_APPLICATION_CREDENTIALS environment variable to the path
     of your Firebase service account JSON file, OR call
     firebase_admin.initialize_app() with explicit credentials before the
     first request.

  2. TODO_REQUIRED: FIREBASE_SERVICE_ACCOUNT_PATH
     Set env var GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
     OR set FIREBASE_PROJECT_ID and provide credentials another way.

Usage in a FastAPI route::

    from fastapi import Header, HTTPException, Depends
    from backend.app.auth.firebase_auth import verify_firebase_token

    def get_current_user(authorization: str = Header(...)):
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid auth header")
        token = authorization.removeprefix("Bearer ").strip()
        uid = verify_firebase_token(token)
        if not uid:
            raise HTTPException(status_code=401, detail="Invalid token")
        return uid
"""

import logging
import os

import firebase_admin
from firebase_admin import auth, credentials

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Initialise the Firebase Admin SDK once at module import time.
# Guard against double-initialisation (e.g. during hot-reload).
# ---------------------------------------------------------------------------
_app: firebase_admin.App | None = None


def _get_app() -> firebase_admin.App:
    global _app
    if _app is not None:
        return _app

    # Prefer an explicit service-account file path …
    sa_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if sa_path:
        cred = credentials.Certificate(sa_path)
        _app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialised from service account file.")
    else:
        # … fall back to Application Default Credentials (GCP / Cloud Run)
        # TODO_REQUIRED: GOOGLE_APPLICATION_CREDENTIALS or ADC must be configured
        logger.warning(
            "GOOGLE_APPLICATION_CREDENTIALS not set — "
            "attempting Application Default Credentials."
        )
        _app = firebase_admin.initialize_app()

    return _app


# Trigger initialisation at import time so failures surface early.
try:
    _get_app()
except Exception:
    logger.exception(
        "Firebase Admin SDK failed to initialise. "
        "Token verification will not work until credentials are provided."
    )


def verify_firebase_token(token: str) -> str:
    """
    Verify a Firebase ID token and return the authenticated user's UID.

    Args:
        token: A Firebase ID token string (JWT).

    Returns:
        The user's UID string, or an empty string if verification fails.

    Raises:
        firebase_admin.auth.InvalidIdTokenError: If the token is malformed
            or expired.
        firebase_admin.auth.RevokedIdTokenError: If the token has been
            revoked.
    """
    if not token:
        logger.warning("verify_firebase_token called with empty token")
        return ""

    decoded_token = auth.verify_id_token(token)
    uid: str = decoded_token.get("uid", "")
    logger.debug("Firebase token verified — uid=%s", uid)
    return uid
