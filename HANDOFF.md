# HANDOFF — Matematikçik

Güncel: 2026-11-10

## Ne yapıldı
- **Güvenlik (kısmi):** İmza anahtarı şifresi `CLAUDE.md` + `AGENTS.md`'den silindi (master 8f86c76, push edildi). `.jks` ve `key.properties` ne tracked ne de geçmişte — doğrulandı. `.gitignore` eklendi: `key.properties`, `*.jks`, `*.keystore`, `*.p8` artık repoya giremez (f2ec8f7).
- **Ana menü (candy liquid-glass):** `lib/widgets/candy_glass_button.dart` eklendi (Magnus cam temasından: frosted blur + candy jöle tint + glossy üst cila + yanardöner kenar + çift renkli gölge + bas-küçül). `menu_screen.dart`'taki 3 buton bununla değişti; **alta "DİĞER OYUNLAR"** eklendi (url_launcher → geliştirici mağaza sayfası). `url_launcher: ^6.3.1` eklendi. `flutter analyze` temiz (3a109a2).
- `.metadata` takibe alındı, CLAUDE.md/AGENTS.md sürüm bilgisi 1.0.4+7'ye güncellendi (f2ec8f7).

## Güvenlik kararı (VERİLDİ — 2026-11-10)
- Anıl: **"şimdilik bırak".** `.jks` hiç sızmadığı için risk düşük; tip redaksiyonu + `.gitignore` koruması yeterli kabul edildi. Geçmiş temizleme ve upload key rotasyonu **yapılmayacak** (tekrar gündeme getirme). Şifre PUBLIC geçmişte (cc5db51'den beri) kalıyor — bilinçli kabul.

## Yarım kalan
- **Play inceleme sonucu:** Bekleniyor (Anıl'ın Play Console girişi gerek; ben giremiyorum). Politika durumu: Play Console → Matematikçik → Politika durumu.
- **Gizlilik politikası adresi:** Hâlâ `anilgedikoglu.github.io/matematikcik/privacy-policy.html` (kişisel ad içeriyor). Red tekrar gelirse stüdyo alanına (`futurastictech.github.io/play/matematikcik/`) taşı.
- **Büyüme (task 3):** Android 28g −%84 edinme, −%66 MAU; iOS 30g 6 indirme; AdMob −%66. Düşüş nedeni + büyüme planı henüz araştırılmadı.

## Denenip olmayan ve nedeni
- Play Console otomasyonu: giriş Google hesabı gerektiriyor, şifreyi ben giremem → Anıl yapıyor.
- Menü görseli cihazda değil HTML önizlemeyle doğrulandı (Flutter web build'i google_mobile_ads uyumu riskli).

## Sıradaki adım
1. Anıl güvenlik kararını versin (A/B) → uygula.
2. Play sonucu gelince: red ise gizlilik adresini taşı; kabul ise yeni sürümü yayınla.
3. Büyüme analizi + plan (task 3).
4. Candy menüyü gerçek cihazda/doğrulamada gör.
