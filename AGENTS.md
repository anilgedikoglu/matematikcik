# Matematikcik — Proje Notları

## Genel Bilgi
- Flutter uygulaması, Android (Play Store'da yayında), iOS (Codemagic ile TestFlight'a gönderilecek)
- Paket adı: `com.matematikcik.app` (build.gradle.kts'te doğrulandı)
- **Son yüklenen sürüm: `1.0.2+4`** — çocuk uyumu düzeltmesiyle Play Store'a gönderildi
- **Hazırlanan yeni sürüm: `1.0.3+6`** — 3 mod sistemi (Macera/Uzman/Çarpım), pubspec.yaml'da ayarlı (+5 Play Store'da "zaten kullanıldı" hatası verdi)
- Play Store'da kullanılan version code'lar: 1, 2, 3, 4, 5 — **bir sonraki build için +7 veya üzeri kullanılmalı**
- Uygulama Google Play'den "Inaccurate Target Audience" nedeniyle bir kez reddedildi; hedef kitle 13 yaş altı yapıldı ve AdMob child-directed ayarları eklendi

## Oyun Modları (v1.0.3'te eklendi)
- YENİ OYUN → `ModeSelectionScreen` açılır (düz pastel gradient arka plan, 3 mod butonuna ince kırmızı border + %10 transparan görsel), 3 mod sunulur:
  - **Macera Modu**: 60 bölüm, 6 harita arka planı. 60. bölüm bitince 1 ⭐ + save sıfırla
  - **Uzman Modu**: 50 bölüm, 5 harita arka planı. 50. bölüm bitince 1 ⭐ + save sıfırla
    - Levels 1-10: `uzmanmodubg.png`, 11-20: `uzmanmodubg2.png`, 21-30: `uzmanmodubg3.png`, 31-40: `uzmanmodubg4.png`, 41-50: `uzmanmodubg5.png`
    - Sorular: `lib/models/uzman_level_questions.dart` — 20 soru/bölüm, %80 (16/20) geçme eşiği
    - **Macera mekanikleri uygulandı**: 3 kalp, 60sn sayaç (macera'nın 2 katı), 🐰 ilerleme çubuğu, soru kartı dikeyde ortalı/büyük punto, ortada cocukgood/kirikkalp pop-up'ı, 3 can biterse oyun bitti ekranı (`bg.png` arka plan)
  - **Çarpım Tablosu**: 1×1 - 9×9, 20 soru, 2×2 seçenek, 20/20 tam doğru → 1 ⭐
    - **Macera mekanikleri uygulandı**: 3 kalp, 🐰 ilerleme çubuğu, ortada cocukgood/kirikkalp pop-up'ı, doğru cevapta doğru şık yeşil / yanlışta doğru şık kırmızı, 3 can biterse oyun bitti ekranı (`bg.png`)
    - Şıklar soru başına bir kez üretilir (state'te `_choices`), her şıkta `ValueKey('$_index-$value')` (renk taşmasını önler)
- **Quiz/oyun-bitti arka planı**: Uzman & Çarpım quiz ekranı düz pastel gradient; oyun bitti ekranları `bg.png` (harita/orman görseli kullanılmaz) — macera ile aynı
- DEVAM ET: macera/uzman'da ilerleme varsa aktif; ikisinde birden varsa popup gösterir
- **Reklam tüm modlarda aktif** — yanlış cevapta `AdService.onWrongAnswer()` çağrılır

## Mağaza Ekran Görüntüleri (Store Screenshots)
- Kaynak: `C:\Users\AG\Desktop\MARKETLER İÇİN\matematikciK\previewed` (7 adet 652×1413 telefon screenshot)
- Çıktı: `...\matematikciK\store_screenshots\` altında 4 klasör, oran korunarak (esnetmeden) dolgulu:
  - `ios_telefon`: **1242×2688** (iPhone 6.5"), pembe dolgu (RGB 255,240,245)
  - `ios_tablet`: **2048×2732** (iPad 12.9"), **beyaz** dolgu
  - `android_telefon`: **1080×2160** (2:1), pembe dolgu
  - `android_tablet`: **1280×2560** (2:1), pembe dolgu
- Üretim: PowerShell + System.Drawing (HighQualityBicubic, JPEG q92). iPhone oranı kaynakla birebir; Google Play 2:1 limiti, iPad 0.75 oranı zorunlu olduğu için dolgu gerekti

## AdMob Bilgileri
- Publisher ID: `pub-6470338276121414`
- **Android** App ID: `ca-app-pub-6470338276121414~5204339767`
- **iOS** App ID: `ca-app-pub-6470338276121414~6484112907`
- **Android** Interstitial Ad Unit ID: `ca-app-pub-6470338276121414/3561369465`
- **iOS** Interstitial Ad Unit ID: `ca-app-pub-6470338276121414/5375921075`
- **iOS** Rewarded Ad Unit ID: `ca-app-pub-6470338276121414/3292683216` (şimdilik kullanılmıyor)
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

## Macera Modu Oyun Yapısı
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
- `lib/screens/quiz_screen.dart` — Macera modu ana oyun ekranı (en karmaşık)
- `lib/screens/uzman_quiz_screen.dart` — Uzman modu quiz (keypad only, 20 soru, shake animasyonu)
- `lib/screens/uzman_map_screen.dart` — Uzman modu harita (50 bölüm, 5 arka plan)
- `lib/screens/carpim_tablosu_screen.dart` — Çarpım tablosu (20 soru, 2×2 seçenek, reklam destekli)
- `lib/screens/mode_selection_screen.dart` — Mod seçim ekranı (YENİ OYUN sonrası, bg2.png)
- `lib/screens/menu_screen.dart` — Ana menü; mod bazlı "En Yüksek Başarı" + DEVAM ET mantığı
- `lib/screens/map_screen.dart` — Macera modu harita
- `lib/screens/settings_screen.dart` — bg2.png arka plan, sarı "Ayarlar" başlığı

## Servisler
- `lib/services/ad_service.dart` — AdMob interstitial yönetimi
- `lib/services/audio_service.dart` — Ses yönetimi (audioplayers paketi)
- `lib/services/save_service.dart` — Oyun kaydı (shared_preferences)
  - Macera: `hasSave`, `load`, `save`, `deleteSave`
  - Uzman: `loadUzmanLevel`, `loadUzmanScores`, `saveUzmanProgress`, `deleteUzmanSave`
  - Yıldızlar: `loadCarpimStars`/`addCarpimStar`, `loadMaceraStars`/`addMacaraStar`, `loadUzmanStars`/`addUzmanStar`

## Modeller
- `lib/models/game_state.dart` — Macera modu durumu
- `lib/models/level_questions.dart` — Macera modu soru üretici
- `lib/models/uzman_level_questions.dart` — Uzman modu soru üretici (60 level tanımlı, 50 aktif)
- `lib/models/question.dart` — Soru modeli

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
- **Asset senkronizasyonu**: `C:\src\matematikcik\assets` kaynak dizindir. Worktree'ye güncellenmiş görseller için MD5 karşılaştırmalı kopyalama yapılmalı (PowerShell ile).

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
- AdMob doğrulaması 24-48 saat içinde otomatik tamamlanır

## iOS Yapılandırması (Codemagic)

- **Bundle ID**: `com.matematikcik.app` (Android ile aynı — project.pbxproj'te güncellendi)
- **Display Name**: `Matematikçik` (Info.plist `CFBundleDisplayName`)
- **Deployment Target**: 13.0 (AdMob için minimum)
- **Team ID**: `SN5Y726ZKF` (FUTURASTIC TEKNOLOJI...)
- **AdMob iOS App ID**: `ca-app-pub-6470338276121414~6484112907` (Info.plist `GADApplicationIdentifier`)
- **AdMob iOS Interstitial Unit ID**: ✅ GERÇEK ID `ca-app-pub-6470338276121414/5375921075` (Matgecis) — `lib/services/ad_service.dart:8`'de girili
- **AdMob iOS Rewarded Unit ID**: `ca-app-pub-6470338276121414/3292683216` (matrewarded — şimdilik kullanılmıyor)
- **App Store Connect App ID** (numerik): `6779563082`
- **ITSAppUsesNonExemptEncryption**: `false`
- **ATT kaldırıldı**: `app_tracking_transparency` paketi ve izin akışı çıkarıldı — çocuk uygulaması tracking yapmıyor
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
git tag v1.0.3-ios1
git push origin v1.0.3-ios1

# YA Codemagic UI'dan manuel: Applications → matematikcik → Start new build → claude/gracious-borg-bd0353 → ios-testflight
```

## Yapılacaklar / Hatırlatmalar
- AdMob "İnceleme gerekli" / "Doğrulanmadı" uyarıları normaldir, 1-3 gün içinde çözülür
- **Bir sonraki Play Store yüklemesinde version code +5 veya üzeri kullanılmalı**
- Play Console > Uygulama içeriği > Reklam kimliği: "Reklam veya pazarlama" seçili
- Play Console > Data Safety: AdMob'un Advertising ID topladığını beyan et
- flutter binary tam path: `C:/Users/AG/Documents/Downloads/urasokul/flutter_windows_3.29.2-stable/flutter/bin/flutter`
- ✅ iOS AdMob interstitial gerçek ID girildi (`5375921075`) — `ad_service.dart`'ta TODO kalmadı
