# HANDOFF — Matematikçik

Güncel: 2026-11-10

## Ne yapıldı
- **1.0.4+7** (Android API 36 hedefi): `master` 5c314db. Play'e yüklendi.
- 8 Kasım: Play güncellemeyi **"Meta Veri: Birinci düzey bağlantılar"** gerekçesiyle reddetti. Google bağlantıyı belirtmedi.
  - Mağaza ayarlarındaki Web sitesi stüdyo sitesine (`futurastictech.github.io`) gidiyordu. Bu sitede fal, tarot ve aşk falı uygulamaları listeleniyor; uygulama ise 13 yaş altı.
  - 10 Kasım: Web sitesi `https://futurastictech.github.io/play/matematikcik/` yapıldı, 7 (1.0.4) yeniden incelemeye gönderildi. Kod değişmedi.
- Play'de eski sürüm yayında kalıyor.

## Yarım kalan
- Play incelemesinin sonucu bekleniyor. Politika durumu: Play Console → Matematikçik → Politika durumu.
- `.gitignore` ve `.metadata` takip dışı (untracked) duruyor; neden eklenmediği bilinmiyor.
- `CLAUDE.md` eski: "son yüklenen 1.0.2+4" diyor, güncel sürüm 1.0.4+7.

## Denenip olmayan ve nedeni
- Reddin kesin nedeni bilinmiyor; web sitesi bağlantısı bir çıkarım.

## Sıradaki adım
1. **Güvenlik (öncelikli):** `CLAUDE.md` ve `AGENTS.md` imza anahtarı şifresini açık metin içeriyor, repo PUBLIC. `.jks` dosyası hiç commit edilmemiş. Yapılacaklar:
   - Şifreyi bu dosyalardan sil.
   - Anıl ile geçmişi temizleme veya Play'den upload key sıfırlama kararını konuş.
2. Red tekrar gelirse gizlilik politikası adresini değiştir. Şu anki adres `anilgedikoglu.github.io/matematikcik/privacy-policy.html` kişisel ad içeriyor; stüdyo alanına taşı.
3. Büyüme:
   - Son 28 günde Android'de 158 edinme (-%84) ve 241 aylık aktif cihaz (-%66) var.
   - iOS'ta son 30 günde 6 indirme var.
   - AdMob'da son 28 günde 15 TL kazanç var (-%66).
   - Düşüşün nedenini bul: mağaza sayfası, sıralama, sezon.
