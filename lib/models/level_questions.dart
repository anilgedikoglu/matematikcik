import 'dart:math';
import 'question.dart';

const int questionsPerLevel = 10;

/// Verilen level (1-60) için 10 soru üretir. Ardışık aynı soru çıkmaz.
List<Question> generateLevel(int level, Random rng) {
  final questions = <Question>[];
  String? lastDisplay;
  while (questions.length < questionsPerLevel) {
    final q = _pick(rng, level);
    if (q.display != lastDisplay) {
      questions.add(q);
      lastDisplay = q.display;
    }
  }
  return questions;
}

// ── Yardımcılar ────────────────────────────────────────────────────────────

int _r(Random r, int min, int max) => r.nextInt(max - min + 1) + min;

Question _add(Random r, int min, int max) {
  final a = _r(r, min, max), b = _r(r, min, max);
  return Question(display: '$a + $b = ?', answer: a + b);
}

Question _sub(Random r, int min, int max) {
  final b = _r(r, min, max);
  final a = b + r.nextInt(max - min + 1);
  return Question(display: '$a − $b = ?', answer: a - b);
}

Question _mul(Random r, int min, int max) {
  final a = _r(r, min, max), b = _r(r, min, max);
  return Question(display: '$a × $b = ?', answer: a * b);
}

Question _div(Random r, int divisorMin, int divisorMax, int quotientMax) {
  final d = _r(r, divisorMin, divisorMax);
  final q = _r(r, 1, quotientMax);
  return Question(display: '${d * q} ÷ $d = ?', answer: q);
}

Question _missingAdd(Random r, int ansMax, int baseMin, int baseMax) {
  final ans = _r(r, 1, ansMax), a = _r(r, baseMin, baseMax);
  return Question(display: '$a + ? = ${a + ans}', answer: ans);
}

Question _missingSub(Random r, int ansMax, int baseMin, int baseMax) {
  final ans = _r(r, 1, ansMax), c = _r(r, baseMin, baseMax);
  return Question(display: '${c + ans} − ? = $c', answer: ans);
}

Question _missingMul(Random r, int min, int max) {
  final a = _r(r, min, max), ans = _r(r, min, max);
  return Question(display: '$a × ? = ${a * ans}', answer: ans);
}

Question _seq(List<int> items, int missing) {
  final parts = List.generate(items.length, (i) => i == missing ? '?' : '${items[i]}');
  return Question(display: parts.join(', '), answer: items[missing]);
}

Question _arithmeticSeq(Random r, int startMax, int stepMin, int stepMax) {
  final s = _r(r, 5, startMax);
  final d = _r(r, stepMin, stepMax);
  final items = [s, s + d, s + 2 * d, s + 3 * d];
  return _seq(items, r.nextInt(4));
}

Question _descSeq(Random r, int startMax, int stepMin, int stepMax) {
  final d = _r(r, stepMin, stepMax);
  final s = _r(r, d * 3 + 1, startMax);
  final items = [s, s - d, s - 2 * d, s - 3 * d];
  return _seq(items, r.nextInt(4));
}

Question _geoSeq(Random r, int baseMin, int baseMax, int ratio) {
  final b = _r(r, baseMin, baseMax);
  final items = [b, b * ratio, b * ratio * ratio, b * ratio * ratio * ratio];
  return _seq(items, r.nextInt(4));
}

Question _percent(Random r, List<int> percents, int baseMin, int baseMax) {
  final p = percents[r.nextInt(percents.length)];
  final base = _r(r, baseMin, baseMax) * (100 ~/ p);
  return Question(display: '$base\'in %$p\'i = ?', answer: base * p ~/ 100);
}

// ── Level seçici ───────────────────────────────────────────────────────────

Question _pick(Random r, int level) {
  switch (level) {

    // ══ DÜNYA 1 (1-10): Temel İşlemler ════════════════════════════════════

    case 1: // Tek haneli toplama
      return _add(r, 1, 9);

    case 2: // Tek haneli toplama + çıkarma
      return r.nextBool() ? _add(r, 1, 9) : _sub(r, 1, 9);

    case 3: // Tek haneli çarpma
      return _mul(r, 1, 9);

    case 4: { // Tek haneli +, −, ×
      final t = r.nextInt(3);
      if (t == 0) return _add(r, 1, 9);
      if (t == 1) return _sub(r, 1, 9);
      return _mul(r, 1, 9);
    }

    case 5: { // Tek haneli +, −, ×, ÷
      final t = r.nextInt(4);
      if (t == 0) return _add(r, 1, 9);
      if (t == 1) return _sub(r, 1, 9);
      if (t == 2) return _mul(r, 1, 9);
      return _div(r, 1, 9, 9);
    }

    case 6: { // 20'ye kadar +/−, tek haneli ×
      final t = r.nextInt(4);
      if (t == 0) return _add(r, 1, 20);
      if (t == 1) return _sub(r, 1, 20);
      if (t == 2) return _mul(r, 1, 9);
      return _div(r, 2, 9, 10);
    }

    case 7: { // 30'a kadar, tamamlama soruları
      final t = r.nextInt(6);
      if (t == 0) return _add(r, 1, 30);
      if (t == 1) return _sub(r, 1, 30);
      if (t == 2) return _mul(r, 1, 9);
      if (t == 3) return _div(r, 2, 9, 10);
      if (t == 4) return _missingAdd(r, 15, 5, 20);
      return _missingSub(r, 15, 5, 20);
    }

    case 8: { // 50'ye kadar, sıralama
      final t = r.nextInt(8);
      if (t == 0) return _add(r, 1, 50);
      if (t == 1) return _sub(r, 1, 50);
      if (t == 2) return _mul(r, 1, 9);
      if (t == 3) return _div(r, 2, 9, 10);
      if (t == 4) return _missingAdd(r, 20, 5, 40);
      if (t == 5) return _missingSub(r, 20, 5, 40);
      if (t == 6) return _arithmeticSeq(r, 70, 3, 10);
      return _descSeq(r, 90, 3, 10);
    }

    case 9: { // Karışık + geometrik dizi
      final t = r.nextInt(10);
      if (t == 0) return _add(r, 1, 50);
      if (t == 1) return _sub(r, 1, 50);
      if (t == 2) return _mul(r, 1, 12);
      if (t == 3) return _div(r, 2, 12, 12);
      if (t == 4) return _missingAdd(r, 20, 5, 50);
      if (t == 5) return _missingSub(r, 20, 5, 50);
      if (t == 6) return _missingMul(r, 2, 9);
      if (t == 7) return _arithmeticSeq(r, 80, 2, 10);
      if (t == 8) return _descSeq(r, 90, 2, 10);
      return _geoSeq(r, 1, 8, 2); // ×2 dizisi
    }

    case 10: { // Yuvarlak üç haneli + karışık
      final t = r.nextInt(8);
      if (t == 0) {
        final a = _r(r, 1, 9) * 50, b = _r(r, 1, 5) * 50;
        return Question(display: '$a + $b = ?', answer: a + b);
      }
      if (t == 1) {
        final b = _r(r, 1, 4) * 50, a = b + _r(r, 1, 5) * 50;
        return Question(display: '$a − $b = ?', answer: a - b);
      }
      if (t == 2) {
        final a = _r(r, 1, 5) * 50, b = _r(r, 2, 6);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 3) {
        final d = _r(r, 2, 5), q = _r(r, 2, 5);
        return Question(display: '${d * q * 50} ÷ $d = ?', answer: q * 50);
      }
      if (t == 4) return _add(r, 10, 80);
      if (t == 5) return _sub(r, 10, 80);
      if (t == 6) return _mul(r, 2, 12);
      return _div(r, 2, 12, 12);
    }

    // ══ DÜNYA 2 (11-20): İlkokul Orta ═════════════════════════════════════

    case 11: // 100'e kadar toplama
      return _add(r, 10, 100);

    case 12: // 100'e kadar çıkarma
      return _sub(r, 10, 100);

    case 13: // 10'a kadar çarpım tablosu
      return _mul(r, 1, 10);

    case 14: // 10'a kadar bölme
      return _div(r, 2, 10, 10);

    case 15: { // 100'e kadar karışık
      final t = r.nextInt(4);
      if (t == 0) return _add(r, 10, 100);
      if (t == 1) return _sub(r, 10, 100);
      if (t == 2) return _mul(r, 1, 10);
      return _div(r, 2, 10, 10);
    }

    case 16: { // Eksik sayı (toplama/çıkarma, 100'e kadar)
      final t = r.nextInt(4);
      if (t == 0) return _missingAdd(r, 30, 10, 80);
      if (t == 1) return _missingSub(r, 30, 10, 80);
      if (t == 2) return _add(r, 10, 100);
      return _sub(r, 10, 100);
    }

    case 17: { // Eksik çarpan + 2-haneli × 1-haneli
      final t = r.nextInt(4);
      if (t == 0) return _missingMul(r, 2, 10);
      if (t == 1) {
        final a = _r(r, 11, 19), b = _r(r, 2, 5);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 2) return _mul(r, 1, 10);
      return _div(r, 2, 10, 10);
    }

    case 18: { // 2-haneli × 1-haneli geniş + bölme
      final t = r.nextInt(4);
      if (t == 0) {
        final a = _r(r, 11, 25), b = _r(r, 2, 6);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 1) return _div(r, 2, 12, 12);
      if (t == 2) return _missingMul(r, 2, 12);
      return _mul(r, 2, 12);
    }

    case 19: { // Aritmetik sıralama (iki haneli)
      final t = r.nextInt(4);
      if (t == 0) return _arithmeticSeq(r, 90, 3, 15);
      if (t == 1) return _descSeq(r, 99, 3, 15);
      if (t == 2) return _add(r, 20, 99);
      return _sub(r, 20, 99);
    }

    case 20: { // Karma orta zorluk
      final t = r.nextInt(6);
      if (t == 0) return _add(r, 20, 99);
      if (t == 1) return _sub(r, 20, 99);
      if (t == 2) return _mul(r, 2, 12);
      if (t == 3) return _div(r, 2, 12, 12);
      if (t == 4) return _arithmeticSeq(r, 90, 5, 20);
      return _geoSeq(r, 1, 10, 2);
    }

    // ══ DÜNYA 3 (21-30): Ortaokul Giriş ═══════════════════════════════════

    case 21: // 200'e kadar toplama
      return _add(r, 50, 200);

    case 22: // 200'e kadar çıkarma
      return _sub(r, 50, 200);

    case 23: // 12'ye kadar çarpım tablosu
      return _mul(r, 1, 12);

    case 24: // 12'ye kadar bölme
      return _div(r, 2, 12, 12);

    case 25: { // 2-haneli × 1-haneli (büyük)
      final t = r.nextInt(4);
      if (t == 0) {
        final a = _r(r, 12, 20), b = _r(r, 3, 9);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 1) return _div(r, 3, 12, 15);
      if (t == 2) return _mul(r, 3, 12);
      return _add(r, 50, 200);
    }

    case 26: { // 10'lar ve 100'ler ile çarpma + karışık
      final t = r.nextInt(4);
      if (t == 0) {
        final a = _r(r, 1, 9) * 10, b = _r(r, 2, 9);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 1) {
        final a = _r(r, 1, 5) * 100, b = _r(r, 2, 9);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 2) return _missingMul(r, 2, 12);
      return _missingAdd(r, 50, 50, 150);
    }

    case 27: { // Karma + eksik işlemler
      final t = r.nextInt(6);
      if (t == 0) return _missingAdd(r, 50, 50, 150);
      if (t == 1) return _missingSub(r, 50, 50, 150);
      if (t == 2) return _missingMul(r, 3, 12);
      if (t == 3) return _add(r, 50, 200);
      if (t == 4) return _sub(r, 50, 200);
      return _mul(r, 3, 12);
    }

    case 28: { // Aritmetik sıralama (üç haneli)
      final t = r.nextInt(4);
      if (t == 0) return _arithmeticSeq(r, 200, 5, 25);
      if (t == 1) return _descSeq(r, 250, 5, 25);
      if (t == 2) return _add(r, 50, 200);
      return _sub(r, 50, 200);
    }

    case 29: { // Geometrik sıralama (×2, ×3)
      final t = r.nextInt(4);
      if (t == 0) return _geoSeq(r, 1, 12, 2);
      if (t == 1) return _geoSeq(r, 1, 6, 3);
      if (t == 2) return _arithmeticSeq(r, 200, 5, 25);
      return _mul(r, 3, 15);
    }

    case 30: { // Karma orta-zor
      final t = r.nextInt(6);
      if (t == 0) return _add(r, 50, 200);
      if (t == 1) return _sub(r, 50, 200);
      if (t == 2) return _mul(r, 3, 15);
      if (t == 3) return _div(r, 3, 15, 15);
      if (t == 4) return _geoSeq(r, 1, 10, 2);
      return _missingMul(r, 3, 15);
    }

    // ══ DÜNYA 4 (31-40): İleri Seviye ═════════════════════════════════════

    case 31: // 500'e kadar toplama
      return _add(r, 100, 500);

    case 32: // 500'e kadar çıkarma
      return _sub(r, 100, 500);

    case 33: // 15'e kadar çarpım tablosu
      return _mul(r, 2, 15);

    case 34: // 15'e kadar bölme
      return _div(r, 3, 15, 15);

    case 35: { // 2-haneli × 2-haneli (basit: 11-20 × 11-20)
      final t = r.nextInt(4);
      if (t == 0) {
        final a = _r(r, 11, 20), b = _r(r, 11, 20);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 1) {
        final a = _r(r, 12, 30), b = _r(r, 4, 9);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 2) return _mul(r, 4, 15);
      return _div(r, 4, 15, 15);
    }

    case 36: { // Karma + tamamlama büyük sayılar
      final t = r.nextInt(6);
      if (t == 0) return _missingAdd(r, 100, 100, 400);
      if (t == 1) return _missingSub(r, 100, 100, 400);
      if (t == 2) return _missingMul(r, 4, 15);
      if (t == 3) return _add(r, 100, 500);
      if (t == 4) return _sub(r, 100, 500);
      return _mul(r, 4, 15);
    }

    case 37: // Yüzde (10%, 25%, 50%)
      return _percent(r, [10, 25, 50], 1, 10);

    case 38: { // Aritmetik sıralama (büyük adımlar)
      final t = r.nextInt(4);
      if (t == 0) return _arithmeticSeq(r, 400, 10, 50);
      if (t == 1) return _descSeq(r, 500, 10, 50);
      if (t == 2) return _add(r, 100, 500);
      return _sub(r, 100, 500);
    }

    case 39: { // Geometrik sıralama (×2, ×3, ×4)
      final t = r.nextInt(4);
      if (t == 0) return _geoSeq(r, 1, 15, 2);
      if (t == 1) return _geoSeq(r, 1, 8, 3);
      if (t == 2) return _geoSeq(r, 1, 5, 4);
      return _mul(r, 5, 15);
    }

    case 40: { // Karma zor
      final t = r.nextInt(6);
      if (t == 0) return _add(r, 100, 500);
      if (t == 1) return _sub(r, 100, 500);
      if (t == 2) return _mul(r, 5, 15);
      if (t == 3) return _div(r, 5, 15, 15);
      if (t == 4) return _percent(r, [10, 25, 50], 1, 10);
      return _geoSeq(r, 1, 12, 3);
    }

    // ══ DÜNYA 5 (41-50): Çok Zorlu ════════════════════════════════════════

    case 41: // 999'a kadar toplama
      return _add(r, 200, 999);

    case 42: // 999'a kadar çıkarma
      return _sub(r, 200, 999);

    case 43: // 20'ye kadar çarpım tablosu
      return _mul(r, 3, 20);

    case 44: // 20'ye kadar bölme
      return _div(r, 4, 20, 20);

    case 45: { // 2-haneli × 2-haneli (11-25 arası)
      final t = r.nextInt(4);
      if (t == 0) {
        final a = _r(r, 11, 25), b = _r(r, 11, 25);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 1) {
        final a = _r(r, 15, 35), b = _r(r, 5, 9);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 2) return _mul(r, 5, 20);
      return _div(r, 5, 20, 20);
    }

    case 46: { // 3-haneli karma
      final t = r.nextInt(6);
      if (t == 0) return _add(r, 200, 999);
      if (t == 1) return _sub(r, 200, 999);
      if (t == 2) return _mul(r, 5, 20);
      if (t == 3) return _div(r, 5, 20, 20);
      if (t == 4) return _missingAdd(r, 200, 200, 700);
      return _missingSub(r, 200, 200, 700);
    }

    case 47: // Yüzde (10%, 20%, 25%, 50%, 75%)
      return _percent(r, [10, 20, 25, 50, 75], 1, 8);

    case 48: { // Karma sıralama zorlu
      final t = r.nextInt(6);
      if (t == 0) return _arithmeticSeq(r, 700, 15, 75);
      if (t == 1) return _descSeq(r, 900, 15, 75);
      if (t == 2) return _geoSeq(r, 1, 10, 3);
      if (t == 3) return _geoSeq(r, 1, 6, 4);
      if (t == 4) return _add(r, 200, 999);
      return _sub(r, 200, 999);
    }

    case 49: { // Karma çok zor
      final t = r.nextInt(6);
      if (t == 0) return _add(r, 200, 999);
      if (t == 1) return _sub(r, 200, 999);
      if (t == 2) return _mul(r, 6, 20);
      if (t == 3) return _div(r, 6, 20, 20);
      if (t == 4) return _percent(r, [10, 20, 25, 50], 1, 10);
      return _geoSeq(r, 1, 8, 4);
    }

    case 50: { // Dünya 5 final
      final t = r.nextInt(8);
      if (t == 0) return _add(r, 200, 999);
      if (t == 1) return _sub(r, 200, 999);
      if (t == 2) {
        final a = _r(r, 11, 25), b = _r(r, 11, 25);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 3) return _div(r, 6, 20, 20);
      if (t == 4) return _percent(r, [10, 20, 25, 50, 75], 1, 10);
      if (t == 5) return _missingMul(r, 5, 20);
      if (t == 6) return _geoSeq(r, 1, 8, 3);
      return _arithmeticSeq(r, 900, 20, 100);
    }

    // ══ DÜNYA 6 (51-60): Usta Seviyesi ════════════════════════════════════

    case 51: { // 3-haneli toplama/çıkarma (büyük)
      return r.nextBool() ? _add(r, 300, 999) : _sub(r, 300, 999);
    }

    case 52: { // 3-haneli × 1-haneli
      final a = _r(r, 100, 500), b = _r(r, 2, 9);
      return Question(display: '$a × $b = ?', answer: a * b);
    }

    case 53: { // 3-haneli ÷ 1-haneli (tam bölünebilir)
      final b = _r(r, 2, 9), q = _r(r, 10, 99);
      return Question(display: '${b * q} ÷ $b = ?', answer: q);
    }

    case 54: { // 2-haneli × 2-haneli (büyük)
      final t = r.nextInt(4);
      if (t == 0) {
        final a = _r(r, 11, 30), b = _r(r, 11, 30);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 1) {
        final a = _r(r, 20, 50), b = _r(r, 6, 9);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 2) return _mul(r, 8, 20);
      return _div(r, 8, 20, 20);
    }

    case 55: { // 3-haneli karma
      final t = r.nextInt(6);
      if (t == 0) return _add(r, 300, 999);
      if (t == 1) return _sub(r, 300, 999);
      if (t == 2) {
        final a = _r(r, 100, 500), b = _r(r, 2, 9);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 3) {
        final b = _r(r, 2, 9), q = _r(r, 10, 99);
        return Question(display: '${b * q} ÷ $b = ?', answer: q);
      }
      if (t == 4) return _missingAdd(r, 300, 300, 699);
      return _missingSub(r, 300, 300, 699);
    }

    case 56: // Yüzde (5%, 10%, 20%, 25%, 50%)
      return _percent(r, [5, 10, 20, 25, 50], 2, 10);

    case 57: { // Karma zor işlemler
      final t = r.nextInt(6);
      if (t == 0) return _add(r, 300, 999);
      if (t == 1) return _sub(r, 300, 999);
      if (t == 2) {
        final a = _r(r, 11, 30), b = _r(r, 11, 30);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 3) return _percent(r, [5, 10, 20, 25, 50], 2, 10);
      if (t == 4) return _geoSeq(r, 1, 6, 4);
      return _missingMul(r, 8, 20);
    }

    case 58: { // Üstel/kuvvet dizileri
      final t = r.nextInt(6);
      if (t == 0) return _geoSeq(r, 1, 8, 3);
      if (t == 1) return _geoSeq(r, 1, 5, 4);
      if (t == 2) return _geoSeq(r, 1, 4, 5);
      if (t == 3) return _arithmeticSeq(r, 900, 25, 100);
      if (t == 4) return _descSeq(r, 999, 25, 100);
      return _add(r, 300, 999);
    }

    case 59: { // Karma en zor
      final t = r.nextInt(8);
      if (t == 0) return _add(r, 300, 999);
      if (t == 1) return _sub(r, 300, 999);
      if (t == 2) {
        final a = _r(r, 15, 35), b = _r(r, 15, 35);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 3) {
        final b = _r(r, 3, 9), q = _r(r, 20, 99);
        return Question(display: '${b * q} ÷ $b = ?', answer: q);
      }
      if (t == 4) return _percent(r, [5, 10, 20, 25, 50], 2, 12);
      if (t == 5) return _geoSeq(r, 1, 6, 4);
      if (t == 6) return _missingMul(r, 10, 25);
      return _arithmeticSeq(r, 999, 25, 100);
    }

    default: { // Level 60 — tüm zorluklar maksimum
      final t = r.nextInt(10);
      if (t == 0) return _add(r, 300, 999);
      if (t == 1) return _sub(r, 300, 999);
      if (t == 2) {
        final a = _r(r, 15, 40), b = _r(r, 15, 40);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 3) {
        final b = _r(r, 3, 9), q = _r(r, 20, 99);
        return Question(display: '${b * q} ÷ $b = ?', answer: q);
      }
      if (t == 4) {
        final a = _r(r, 100, 500), b = _r(r, 3, 9);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      if (t == 5) return _percent(r, [5, 10, 20, 25, 50], 2, 12);
      if (t == 6) return _missingMul(r, 10, 25);
      if (t == 7) return _geoSeq(r, 1, 6, 4);
      if (t == 8) return _arithmeticSeq(r, 999, 30, 100);
      return _descSeq(r, 999, 30, 100);
    }
  }
}
