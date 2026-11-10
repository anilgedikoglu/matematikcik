# HANDOFF — Matematikçik

Güncel: 2026-11-10

## Sürüm
- **1.0.4+7** yayında (eski sürüm). 10 Kasım'da web sitesi `futurastictech.github.io/play/matematikcik/` yapılıp Play'e yeniden gönderildi — **inceleme sonucu bekleniyor**.
- ⚠️ Aşağıdaki büyük UI/navigasyon değişiklikleri **henüz mağazaya gönderilmedi**; sonraki build +8 version code ister.

## Bu oturumda yapılan büyük yeniden-tasarım (hepsi master'da)
Candy / liquid-glass tema + navigasyon elden geçirildi:
- **Ana menü** (`menu_screen.dart`): sadece 3 **candy mod karesi** (Macera/Uzman/Çarpım, ikon+ad+ilerleme). Tıklayınca o moda girer (Macera/Uzman kaldığı yerden). Başarı kartı + eski butonlar kaldırıldı. Arka plan `assets/anamenubg.jpg` (başlık gömülü).
- **Alt kompartman** (`widgets/candy_bottom_bar.dart` + `global_bottom_bar.dart`): **her ekranda** altta — Ana Menü | **Play=devam** | Ayarlar. Köşe geri tuşları **tüm ekranlardan kaldırıldı**.
- **Ayarlar** (`settings_screen.dart`): gece bahçesi bg (`ayarlarbg.jpg`), **liquid-glass Ses Efektleri düğmesi** (`glass_toggle.dart`), **Diğer Oyunlar** kartı buraya taşındı (`services/diger_oyunlar.dart`).
- **Candy widget'lar**: `candy_glass_button.dart` (artık kullanılmıyor), `candy_mode_tile.dart`, `candy_bottom_bar.dart`, `glass_toggle.dart`.
- **Titreşim** (`services/haptic_service.dart`): menü/kompartman tuşları=orta, rakam/Tamam/şık=hafif, yanlış cevap=güçlü (quiz/uzman/çarpım).
- Oyun ekranlarında keypad, alt bar için 110px yukarı alındı.
- `url_launcher: ^6.3.1` eklendi. Tüm `flutter analyze` temiz (yalnız önceden var olan stil-info'ları).

## ⚠️ DOĞRULAMA DURUMU (önemli)
- Menü + Ayarlar görünümü **HTML önizlemeyle doğrulandı** (Anıl onayladı).
- **Oyun ekranları (map/quiz/uzman/çarpım) + alt bar yerleşimi CİHAZDA DOĞRULANMADI** — keypad/level düğümleriyle bar çakışması olabilir (örn. macera haritasında 1. bölüm düğümü altta, bar üstünde). "test çıkar" denince build alıp gerçek cihazda gözlemle; gerekirse 110px payı / düğüm konumları ayarla.
- `ModeSelectionScreen` artık erişilmiyor (ölü kod — silinebilir).

## Güvenlik kararı (VERİLDİ)
- Anıl: "şimdilik bırak". İmza şifresi redaksiyonu + `.gitignore` koruması yeterli; geçmiş temizleme / key rotasyonu yapılmayacak. Bkz. imza-şifresi memory.

## Yarım kalan / sıradaki
- Play inceleme sonucu (Anıl'ın Play Console girişiyle).
- Yeni UI'ı cihazda doğrula → "test çıkar" → +8 build → yükle.
- Büyüme analizi (task 3): Android 28g −%84 edinme; henüz araştırılmadı.
- Gizlilik politikası adresi hâlâ anilgedikoglu.github.io altında (ad içeriyor); red tekrar gelirse stüdyo alanına taşı.
