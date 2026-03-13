# FitLingo - Setup Flutter (Android + iOS)

**100% on-device** – Procesarea pose/joint detection rulează local pe telefon. Zero date trimise extern. GDPR compliant.

## 1. Instalare Flutter

### macOS (Homebrew)
```bash
brew install --cask flutter
```

### Manual
1. Descarcă de la https://docs.flutter.dev/get-started/install
2. Extrage în `~/development/flutter` (sau alt path)
3. Adaugă în `~/.zshrc`:
```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```
4. Rulează `flutter doctor`

## 2. Platformă

### Android
1. Instalează Android Studio: https://developer.android.com/studio
2. Instalează **Android SDK** (Tools → SDK Manager)
3. Acceptă licențele: `flutter doctor --android-licenses`

### iOS (doar pe Mac)
1. Instalează **Xcode** din App Store
2. Deschide Xcode o dată și acceptă licența
3. Instalează CocoaPods: `brew install cocoapods`
4. Rulează: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

## 3. Conectare dispozitiv

### Android
1. Setări → Despre telefon → Apasă de 7 ori pe "Număr compilare"
2. Setări → Opțiuni dezvoltator → USB debugging ON
3. Conectează prin USB

### iOS (iPhone fizic)
1. Conectează iPhone prin cablu
2. Pe iPhone: Trust this computer
3. **iOS 16+**: Setări → Privacy & Security → Developer Mode → ON (restart)
4. În Xcode: Window → Devices → verifică că apare device-ul

## 4. Rulare proiect

```bash
cd mobile
flutter pub get
```

**Pentru instalare pe telefon care merge fără calculator** (fără ecran alb/crash):

```bash
# iOS – folosește RELEASE, nu debug
flutter run --release

# Android – la fel
flutter run --release
```

Build-ul debug (`flutter run` fără --release) se conectează la calculator și poate da crash/ecran alb când deconectezi.

### Rulare pe iOS Simulator
```bash
# Deschide un simulator
open -a Simulator

# Alege device-ul iOS
flutter run -d "iPhone 16"
# sau: flutter devices  (pentru lista)
```

### Rulare pe iPhone fizic
```bash
flutter run -d <id-iphone>
# sau doar: flutter run  (dacă e singurul device)
```

### Permisiune cameră (iOS)
După `flutter create`, adaugă în `ios/Runner/Info.plist` (în interiorul `<dict>`):

```xml
<key>NSCameraUsageDescription</key>
<string>FitLingo folosește camera pentru detectarea pose-ului la exerciții</string>
```

## 5. Dacă apar erori

### "flutter: command not found"
Adaugă Flutter la PATH (vezi pasul 1).

### "No devices found"
- **Android**: USB debugging activat, cablu bun
- **iOS**: Trust computer pe iPhone, Developer Mode ON (iOS 16+)
- **Simulator**: `open -a Simulator` înainte de `flutter run`

### Eroare la build Android
```bash
cd android && ./gradlew clean && cd ..
flutter clean && flutter pub get
flutter run
```

### Eroare la build iOS
```bash
cd ios && pod install && cd ..
flutter clean && flutter pub get
flutter run
```

### Model ML Kit se descarcă prima dată
La prima rulare, ML Kit poate descărca modelul (~5MB) o singură dată. După aceea totul rulează 100% offline.

---

## Instalare pe telefon (fără calculator)

### Android

1. **Generează APK:**
   ```bash
   cd mobile
   flutter build apk --release
   ```

2. **Fișierul APK** se află în: `build/app/outputs/flutter-apk/app-release.apk`

3. **Transferă pe telefon:**
   - Conectează telefonul prin USB și copiază APK-ul
   - Sau trimite prin email/WhatsApp/Google Drive
   - Sau folosește `adb install build/app/outputs/flutter-apk/app-release.apk` (cu telefon conectat)

4. **Instalare pe telefon:**
   - Deschide fișierul APK pe telefon
   - Dacă cere: Setări → Securitate → Permite instalare din surse necunoscute
   - Apasă Instalare

### iOS

**IMPORTANT – Ecran alb / crash când deconectezi:**  
Build-ul **debug** (`flutter run`) depinde de calculator. Pentru app care merge **fără cablu**, folosește **release**:

```bash
flutter run --release
```

Sau instalează din Xcode: `flutter build ios` apoi deschide `ios/Runner.xcworkspace` în Xcode și apasă Run (selectează Release).

**Opțiunea 1 – Release build (recomandat)**  
`flutter run --release` – instalează o versiune care rulează standalone. Cu cont Apple gratuit, expiră după ~7 zile.

**Opțiunea 2 – TestFlight (recomandat pentru distribuție)**  
- Cont Apple Developer (99 USD/an)
- Încarcă build-ul în App Store Connect
- Adaugă testeri și trimite link TestFlight
- Se instalează din app-ul TestFlight, fără calculator

**Opțiunea 3 – Build IPA pentru instalare manuală**  
```bash
flutter build ipa
```  
Fișierul va fi în `build/ios/ipa/`. Pentru instalare pe device fără App Store ai nevoie de cont Apple Developer și de configurat signing/provisioning.
