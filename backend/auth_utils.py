"""Utilitare autentificare: JWT, hash parolă, verificare Google token."""
import hashlib
from datetime import datetime, timedelta
from typing import Optional

from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session
import httpx

from config import settings
from models import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Hash parolă - compatibil cu Flutter (SHA256) sau bcrypt."""
    # Flutter folosește SHA256; backend poate folosi bcrypt pentru securitate mai bună
    # Pentru compatibilitate cu app-ul existent, folosim SHA256
    return hashlib.sha256(password.encode()).hexdigest()


def verify_password(plain: str, hashed: str) -> bool:
    """Verifică parola."""
    return hash_password(plain) == hashed


def create_access_token(user_id: int) -> str:
    """Creează JWT."""
    expire = datetime.utcnow() + timedelta(minutes=settings.jwt_expire_minutes)
    payload = {"sub": str(user_id), "exp": expire}
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> Optional[int]:
    """Decodează JWT și returnează user_id."""
    try:
        payload = jwt.decode(
            token, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
        )
        return int(payload.get("sub"))
    except JWTError:
        return None


def _get_allowed_google_client_ids() -> list[str]:
    """Client IDs acceptate (iOS, Android, Web) – separate prin virgulă în env."""
    raw = (settings.google_client_id or "").strip()
    if not raw:
        return []
    return [x.strip() for x in raw.split(",") if x.strip()]


async def verify_google_token(id_token: str) -> Optional[dict]:
    """Verifică id_token de la Google și returnează payload."""
    allowed = _get_allowed_google_client_ids()
    if not allowed:
        return None
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(
                "https://www.googleapis.com/oauth2/v3/tokeninfo",
                params={"id_token": id_token},
            )
            if resp.status_code != 200:
                return None
            data = resp.json()
            if data.get("aud") not in allowed:
                return None
            return data
        except Exception:
            return None
