# Google Sign-In pe Android – dacă dă crash

## Cauza

Google Sign-In pe Android necesită un **OAuth Client (tip Android)** în Google Cloud Console cu:
- **Package name** exact: `com.fitlingo.fitlingo`
- **SHA-1 fingerprint** al cheii de semnare

## Pași

### 1. Obține SHA-1

```bash
cd mobile
cd android && ./gradlew signingReport
```

Caută `SHA1:` sub **Variant: debug** și copiază valoarea (ex: `AA:BB:CC:DD:EE:...`).

### 2. Creează OAuth Client în Google Console

1. https://console.cloud.google.com/apis/credentials
2. **Create Credentials** → **OAuth client ID**
3. Application type: **Android**
4. **Package name:** `com.fitlingo.fitlingo`
5. **SHA-1:** lipește valoarea de la pasul 1
6. **Create**

### 3. Rebuild app

```bash
cd mobile
flutter clean
flutter pub get
flutter run -d <android_device_id>
```
