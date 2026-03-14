"""Configurare aplicație."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Setări din variabile de mediu."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # MySQL
    database_url: str = "mysql+pymysql://root@localhost:3306/itfest"

    # JWT
    jwt_secret: str = "itfest-secret-change-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 7  # 7 zile

    # Google OAuth – Client IDs acceptate (iOS, Android, Web), separate prin virgulă
    google_client_id: str = (
        "209952261016-aejhtho8mojmktlq7ke9nu2c6qapfnt2.apps.googleusercontent.com,"
        "209952261016-mn4ckiecftq0vnsj5nv5lrd60jp2vsd7.apps.googleusercontent.com"
    )


settings = Settings()
