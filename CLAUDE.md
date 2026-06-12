# Matematikcik — Proje Notları

## Genel Bilgi
- Flutter uygulaması, Android (Play Store'da yayında)
- Paket adı: `com.matematikcik.app` (build.gradle.kts'te doğrulandı)
- **Son yüklenen sürüm: `1.0.2+4`** — çocuk uyumu düzeltmesiyle Play Store'a gönderildi
- Play Store'da kullanılan version code'lar: 1, 2, 3, 4 — bir sonraki build için +5 veya üzeri kullanılmalı
- Uygulama Google Play'den "Inaccurate Target Audience" nedeniyle bir kez reddedildi; hedef kitle 13 yaş altı yapıldı ve AdMob child-directed ayarları eklendi

## AdMob Bilgileri
- Publisher ID: `pub-6470338276121414`
- **Android** App ID: `ca-app-pub-6470338276121414~5204339767`
- **iOS** App ID: `ca-app-pub-6470338276121414~6484112907`
- **Android** Interstitial Ad Unit ID: `ca-app-pub-6470338276121414/3561369465`
- **iOS** Interstitial Ad Unit ID: ⚠️ TEST ID (`ca-app-pub-3940256099942544/4411468910`) — AdMob'da iOS unit oluşturup `ad_service.dart`'ı güncelle
- AdMob'da reklam kimliği kullanım beyanı: **Reklam veya pazarlama** seçildi
- Reklam mantığı: her 3 yanlış cevapta 1 interstitial, kapatılana kadar beklenir (Completer kullanılır)
- **Çocuk uyumu (v1.0.2+4'te eklendi):** `ad_service.dart` içinde `initialize()` öncesinde:
  - `tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes`
  - `maxAdContentRating: MaxAdContentRating.g`

## Keystore / İmzalama
- Keystore: `C:/src/matematikcik/android/matematikcik-release.jks`
- key.properties: `C:/src/matematikcik/android/key.properties`
- Şifreler: `Mat3m4t1kc1k!` (store + key şifresi aynı)
- Alias: `matematikcik`
- **Worktree'de build yaparken**: key.properties ve .jks dosyasını worktree'nin android/ klasörüne kopyalamak gerekir; storeFile yolu absolute olmalı (`C:/src/matematikcik/android/matematikcik-release.jks`)

## Oyun Yapısı
- Toplam 6 harita (world), her haritada 10 bölüm = 60 bölüm
- `int get _world => (widget.level - 1) ~/ 10;` (0-5 arası)
- Giriş modu dünyaya göre:
  - World 0 (Harita 1): 2 büyük buton
  - World 1 (Harita 2): 3 buton
  - World 2 (Harita 3): 4 buton
  - World 3 (Harita 4): normal keypad, doğru cevap girilince otomatik ilerle
  - World 4 (Harita 5): normal keypad, otomatik ilerle
  - World 5 (Harita 6): karışık keypad, otomatik ilerle

## Ekranlar
- `lib/screens/quiz_screen.dart` — Ana oyun ekranı (en karmaşık)
- `lib/screens/menu_screen.dart` — Ana menü; "En yüksek: X. bölüm" ve "DEVAM ET (X)" gösterir
- `lib/screens/settings_screen.dart` — bg2.png arka plan, sarı "Ayarlar" başlığı, dikeyde ortada ses kartı

## Servisler
- `lib/services/ad_service.dart` — AdMob interstitial yönetimi
- `lib/services/audio_service.dart` — Ses yönetimi (audioplayers paketi)
- `lib/services/save_service.dart` — Oyun kaydı (shared_preferences)

## Sesler
- WAV dosyaları MP3'e dönüştürüldü (ffmpeg ile, -qscale:a 4):
  - `yol.wav` (33MB) → `yol.mp3` (2MB)
  - `oyunbitti.wav` (4.5MB) → `oyunbitti.mp3` (113KB)
  - `dogru.wav` (734KB) → `dogru.mp3` (17KB)
- audio_service.dart'ta referanslar güncellendi
- Diğer müzikler zaten MP3: menu.mp3, oyun1-4.mp3

## Görseller
- Büyük arka plan PNG'leri (orman1-6, marketkapak, bg2): RGBA→RGB dönüştürüldü, 1080px genişliğe ölçeklendi, PNG optimize edildi (~70% küçüldü)
- `matematikciikon.png`: 2048×2048 → 512×512 (%95 küçüldü)
- Tüm küçük PNG'ler: `optimize=True` ile yeniden kaydedildi
- Toplam varlık optimizasyonu: ~78MB tasarruf

## AAB Build Süreci
```bash
# Worktree'ye keystore kopyala
cp C:/src/matematikcik/android/key.properties android/
cp C:/src/matematikcik/android/matematikcik-release.jks android/

# key.properties içindeki storeFile yolunu absolute yap:
# storeFile=C:/src/matematikcik/android/matematikcik-release.jks

# Build
flutter build appbundle --release
# Çıktı: build/app/outputs/bundle/release/app-release.aab
```

## DevicePreview
- `lib/main.dart`'ta `enabled: false` olarak ayarlı — AÇMA
- Açık olduğunda adb tap koordinatları kayıyor (device_preview ekranı scale ediyor)

## Önemli Paketler
- `google_mobile_ads: ^5.1.0`
- `audioplayers`
- `shared_preferences`
- `device_preview` (disabled)

## GitHub
- Remote: `origin` → `https://github.com/anilgedikoglu/matematikcik`
- Worktree branch: `claude/gracious-borg-bd0353`

## app-ads.txt Kurulumu (TAMAMLANDI)
- **Doğru domain:** `https://anilgedikoglu.github.io/app-ads.txt` (kök dizin şart, alt klasör çalışmıyor)
- **GitHub repo:** `anilgedikoglu/anilgedikoglu.github.io` — bu özel user pages reposu, sadece bu repo kök domain'de yayınlanıyor
- **İçerik:** `google.com, pub-6470338276121414, DIRECT, f08c47fec0942fa0`
- **Play Console web sitesi (her iki uygulama için):** `https://anilgedikoglu.github.io`
- Bu tek dosya hem Matematikcik hem Oyuncu Dükkanı'nı kapsar — publisher ID bazlı çalışır, uygulama bazlı değil
- Matematikcik için ayrıca `github.com/anilgedikoglu/matematikcik` main branch'inde de app-ads.txt var (gereksiz ama zararsız)
- Oyuncu Dükkanı için `github.com/anilgedikoglu/oyuncu_dukkani` main branch'inde de var (aynı şekilde)
- AdMob doğrulaması 24-48 saat içinde otomatik tamamlanır

## iOS Yapılandırması (Codemagic)

- **Bundle ID**: `com.matematikcik.app` (Android ile aynı — project.pbxproj'te güncellendi)
- **Display Name**: `Matematikçik` (Info.plist `CFBundleDisplayName`)
- **Deployment Target**: 13.0 (AdMob için minimum)
- **Team ID**: `SN5Y726ZKF` (FUTURASTIC TEKNOLOJI...)
- **AdMob iOS App ID**: `ca-app-pub-6470338276121414~6484112907` (Info.plist `GADApplicationIdentifier`)
- **AdMob iOS Interstitial Unit ID**: ⚠️ TEST ID (`ca-app-pub-3940256099942544/4411468910`) — AdMob'da iOS unit oluşturup `lib/services/ad_service.dart`'ı güncelle
- **App Store Connect App ID** (numerik): `6779563082`
- **ITSAppUsesNonExemptEncryption**: `false`
- **NSUserTrackingUsageDescription**: "Bu izin, size daha alakalı reklamlar gösterilmesi için kullanılır."
- **SKAdNetworkItems**: 44 Google SKAN ID (Info.plist'e eklendi)
- **iOS App Icon**: `flutter_launcher_icons` ile `assets/matematikciikon.png`'den — `remove_alpha_ios: true` eklendi

### Codemagic Kurulum (oyuncu_dukkani'den paylaşımlı — YENİDEN KURMAYA GEREK YOK)
- App Store Connect API Key: **"Codemagic"** entegrasyonu (Key ID: `2M84B256CL`)
- iOS Distribution cert: Personal Account → Code signing identities → `ios_distribution`
- `CERTIFICATE_PRIVATE_KEY` env var: group `signing_credentials`'da (Magnus/oyuncu_dukkani ile aynı)
- Codemagic'te matematikcik reposu eklenmeli: https://codemagic.io → Add application → matematikcik

### Codemagic Workflow Tetikleme
```bash
# Tag ile (otomatik)
git tag v1.0.2-ios1
git push origin v1.0.2-ios1

# YA Codemagic UI'dan manuel: Applications → matematikcik → Start new build → claude/gracious-borg-bd0353 → ios-testflight
```

### ⚠️ ATT (App Tracking Transparency)
- `app_tracking_transparency: ^6.0.1` pubspec.yaml'a eklendi
- `main.dart`'ta AdMob `init()`'den ÖNCE `requestTrackingAuthorization()` çağrılıyor
- App Store Connect → Matematikçik → **App Privacy** formu doldurulmalı (oyuncu_dukkani ile aynı adımlar)

## Yapılacaklar / Hatırlatmalar
- AdMob "İnceleme gerekli" / "Doğrulanmadı" uyarıları normaldir, 1-3 gün içinde çözülür
- Bir sonraki Play Store yüklemesinde version code **+5 veya üzeri** kullanılmalı
- Play Console > Uygulama içeriği > Reklam kimliği: "Reklam veya pazarlama" seçili
- Play Console > Data Safety: AdMob'un Advertising ID topladığını beyan et
- flutter binary tam path: `C:/Users/AG/Documents/Downloads/urasokul/flutter_windows_3.29.2-stable/flutter/bin/flutter`
- **iOS TODO**: AdMob konsolunda iOS interstitial unit oluştur → `lib/services/ad_service.dart`'taki iOS TODO'yu gerçek ID ile güncelle
