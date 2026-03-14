"""Pydantic schemas pentru request/response."""
from pydantic import BaseModel, EmailStr


class UserResponse(BaseModel):
    """Răspuns utilizator."""

    id: int
    name: str
    email: str
    auth_provider: str
    created_at: str

    class Config:
        from_attributes = True


class RegisterRequest(BaseModel):
    """Request înregistrare."""

    name: str
    email: EmailStr
    password: str


class LoginRequest(BaseModel):
    """Request login."""

    email: EmailStr
    password: str


class GoogleAuthRequest(BaseModel):
    """Request Google OAuth - id_token de la Flutter."""

    id_token: str


class TokenResponse(BaseModel):
    """Răspuns cu JWT și user."""

    access_token: str
    token_type: str = "bearer"
    user: UserResponse
