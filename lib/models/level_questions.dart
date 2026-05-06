import 'dart:math';
import 'question.dart';

const int questionsPerLevel = 30;

/// Her level için 30 soru üretir. Ardışık aynı soru çıkmaz.
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
  final a = b + r.nextInt(max - min + 1); // a ≥ b
  return Question(display: '$a − $b = ?', answer: a - b);
}

Question _mul(Random r, int min, int max) {
  final a = _r(r, min, max), b = _r(r, min, max);
  return Question(display: '$a × $b = ?', answer: a * b);
}

/// Bölen bölenMin..bölenMax, bölüm 1..bölümMax
Question _div(Random r, int divisorMin, int divisorMax, int quotientMax) {
  final d = _r(r, divisorMin, divisorMax);
  final q = _r(r, 1, quotientMax);
  return Question(display: '${d * q} ÷ $d = ?', answer: q);
}

Question _seq(List<int> items, int missing) {
  final parts = List.generate(
      items.length, (i) => i == missing ? '?' : '${items[i]}');
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

// ── Level seçici ───────────────────────────────────────────────────────────

Question _pick(Random r, int level) {
  switch (level) {

    // ─ 1: Yalnız tek haneli toplama ───────────────────────────────────
    case 1:
      return _add(r, 1, 9);

    // ─ 2: Tek haneli toplama + çıkarma ────────────────────────────────
    case 2:
      return r.nextBool() ? _add(r, 1, 9) : _sub(r, 1, 9);

    // ─ 3: Yalnız tek haneli çarpma ─────────────────────────────────────
    case 3:
      return _mul(r, 1, 9);

    // ─ 4: Tek haneli +, −, × karışık ──────────────────────────────────
    case 4: {
      final t = r.nextInt(3);
      if (t == 0) return _add(r, 1, 9);
      if (t == 1) return _sub(r, 1, 9);
      return _mul(r, 1, 9);
    }

    // ─ 5: Tek haneli +, −, ×, ÷ karışık ──────────────────────────────
    case 5: {
      final t = r.nextInt(4);
      if (t == 0) return _add(r, 1, 9);
      if (t == 1) return _sub(r, 1, 9);
      if (t == 2) return _mul(r, 1, 9);
      return _div(r, 1, 9, 9);
    }

    // ─ 6: Tek+çift haneli +/−, tek haneli ×, çift÷tek ────────────────
    case 6: {
      final t = r.nextInt(4);
      if (t == 0) return _add(r, 1, 20);
      if (t == 1) return _sub(r, 1, 20);
      if (t == 2) return _mul(r, 1, 9);
      return _div(r, 2, 9, 10); // bölüm max 10 → bölünen max 90
    }

    // ─ 7: Her şey çift haneli, sıralama YOK ──────────────────────────
    case 7: {
      final t = r.nextInt(6);
      if (t == 0) return _add(r, 1, 30);
      if (t == 1) return _sub(r, 1, 30);
      if (t == 2) return _mul(r, 1, 9);
      if (t == 3) return _div(r, 2, 9, 10);
      // Tamamlama soruları
      if (t == 4) {
        final ans = _r(r, 1, 15), a = _r(r, 5, 20);
        return Question(display: '$a + ? = ${a + ans}', answer: ans);
      }
      final ans = _r(r, 1, 15), c = _r(r, 5, 20);
      return Question(display: '${c + ans} − ? = $c', answer: ans);
    }

    // ─ 8: Çift haneli sıralama eklendi ────────────────────────────────
    case 8: {
      final t = r.nextInt(8);
      if (t == 0) return _add(r, 1, 50);
      if (t == 1) return _sub(r, 1, 50);
      if (t == 2) return _mul(r, 1, 9);
      if (t == 3) return _div(r, 2, 9, 10);
      if (t == 4) {
        final ans = _r(r, 1, 20), a = _r(r, 5, 40);
        return Question(display: '$a + ? = ${a + ans}', answer: ans);
      }
      if (t == 5) {
        final ans = _r(r, 1, 20), c = _r(r, 5, 40);
        return Question(display: '${c + ans} − ? = $c', answer: ans);
      }
      // Çift haneli aritmetik sıralama
      if (t == 6) return _arithmeticSeq(r, 70, 3, 10);
      return _descSeq(r, 90, 3, 10);
    }

    // ─ 9: Her şey karışık ─────────────────────────────────────────────
    case 9: {
      final t = r.nextInt(10);
      if (t == 0) return _add(r, 1, 50);
      if (t == 1) return _sub(r, 1, 50);
      if (t == 2) return _mul(r, 1, 12);
      if (t == 3) return _div(r, 2, 12, 12);
      if (t == 4) {
        final ans = _r(r, 1, 20), a = _r(r, 5, 50);
        return Question(display: '$a + ? = ${a + ans}', answer: ans);
      }
      if (t == 5) {
        final ans = _r(r, 1, 20), c = _r(r, 5, 50);
        return Question(display: '${c + ans} − ? = $c', answer: ans);
      }
      if (t == 6) {
        final a = _r(r, 2, 9), ans = _r(r, 2, 9);
        return Question(display: '$a × ? = ${a * ans}', answer: ans);
      }
      if (t == 7) return _arithmeticSeq(r, 80, 2, 10);
      if (t == 8) return _descSeq(r, 90, 2, 10);
      // Geometrik dizi ×2
      final b = _r(r, 1, 8);
      final items = [b, b * 2, b * 4, b * 8];
      return _seq(items, r.nextInt(4));
    }

    // ─ 10: Üç haneli yuvarlak sayılar + mix ──────────────────────────
    default: {
      final t = r.nextInt(8);
      // Yuvarlak üç haneli toplama: 50+50, 100+100, 150+50...
      if (t == 0) {
        final a = (_r(r, 1, 9)) * 50;
        final b = (_r(r, 1, 5)) * 50;
        return Question(display: '$a + $b = ?', answer: a + b);
      }
      // Yuvarlak üç haneli çıkarma
      if (t == 1) {
        final b = (_r(r, 1, 4)) * 50;
        final a = b + (_r(r, 1, 5)) * 50;
        return Question(display: '$a − $b = ?', answer: a - b);
      }
      // Yuvarlak çarpma: 100×3, 50×4...
      if (t == 2) {
        final a = (_r(r, 1, 5)) * 50;
        final b = _r(r, 2, 6);
        return Question(display: '$a × $b = ?', answer: a * b);
      }
      // Yuvarlak bölme: 300÷3, 400÷4...
      if (t == 3) {
        final d = _r(r, 2, 5);
        final q = _r(r, 2, 5);
        final dividend = d * q * 50;
        return Question(display: '$dividend ÷ $d = ?', answer: q * 50);
      }
      // Diğerleri orta zorluk (level 9 tarzı)
      if (t == 4) return _add(r, 10, 80);
      if (t == 5) return _sub(r, 10, 80);
      if (t == 6) return _mul(r, 2, 12);
      return _div(r, 2, 12, 12);
    }
  }
}
