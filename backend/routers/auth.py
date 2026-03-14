"""Router autentificare: register, login, Google OAuth."""
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from database import get_db
from models import User
from schemas import (
    RegisterRequest,
    LoginRequest,
    GoogleAuthRequest,
    TokenResponse,
    UserResponse,
)
from auth_utils import (
    hash_password,
    verify_password,
    create_access_token,
    decode_token,
    verify_google_token,
)

router = APIRouter(prefix="/auth", tags=["auth"])
security = HTTPBearer(auto_error=False)


def _user_to_response(user: User) -> UserResponse:
    return UserResponse(
        id=user.id,
        name=user.name,
        email=user.email,
        auth_provider=user.auth_provider,
        created_at=user.created_at.isoformat() if user.created_at else "",
    )


@router.post("/register", response_model=TokenResponse)
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    """Înregistrare utilizator nou."""
    email = data.email.strip().lower()
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        raise HTTPException(status_code=400, detail="An account with this email already exists.")

    user = User(
        name=data.name.strip(),
        email=email,
        password_hash=hash_password(data.password),
        auth_provider="local",
        google_id=None,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(user.id)
    return TokenResponse(access_token=token, user=_user_to_response(user))


@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    """Login cu email și parolă."""
    email = data.email.strip().lower()
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=401, detail="No account found for this email.")
    if user.auth_provider == "google":
        raise HTTPException(
            status_code=400,
            detail="This account uses Google sign-in. Please use Login with Google.",
        )
    if not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Incorrect password.")

    token = create_access_token(user.id)
    return TokenResponse(access_token=token, user=_user_to_response(user))


@router.post("/google", response_model=TokenResponse)
async def google_auth(data: GoogleAuthRequest, db: Session = Depends(get_db)):
    """Login/register cu Google OAuth (id_token de la Flutter)."""
    payload = await verify_google_token(data.id_token)
    if not payload:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired Google token. Configure GOOGLE_CLIENT_ID in backend.",
        )

    google_id = payload.get("sub")
    email = (payload.get("email") or "").strip().lower()
    name = (payload.get("name") or "Google User").strip() or "Google User"

    # Caută user existent după google_id
    user = db.query(User).filter(User.google_id == google_id).first()
    if user:
        token = create_access_token(user.id)
        return TokenResponse(access_token=token, user=_user_to_response(user))

    # Caută după email - link account
    user = db.query(User).filter(User.email == email).first()
    if user:
        user.auth_provider = "google"
        user.google_id = google_id
        db.commit()
        db.refresh(user)
        token = create_access_token(user.id)
        return TokenResponse(access_token=token, user=_user_to_response(user))

    # User nou
    user = User(
        name=name,
        email=email,
        password_hash="",
        auth_provider="google",
        google_id=google_id,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(user.id)
    return TokenResponse(access_token=token, user=_user_to_response(user))


def _get_current_user(
    creds: HTTPAuthorizationCredentials | None,
    db: Session,
) -> User:
    """Extrage user din JWT Bearer token."""
    if not creds or not creds.credentials:
        raise HTTPException(status_code=401, detail="Missing or invalid token")
    user_id = decode_token(creds.credentials)
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user


@router.get("/me", response_model=UserResponse)
def get_me(
    creds: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(get_db),
):
    """Returnează utilizatorul curent din token."""
    user = _get_current_user(creds, db)
    return _user_to_response(user)
