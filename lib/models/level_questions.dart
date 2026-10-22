import 'dart:math';
import 'question.dart';

const int questionsPerLevel = 10;

List<Question> generateLevel(int level, Random rng) {
  final questions = <Question>[];
  String? lastDisplay;
  int attempts = 0;
  while (questions.length < questionsPerLevel && attempts < 500) {
    attempts++;
    final q = _pick(rng, level);
    if (q.display != lastDisplay) {
      questions.add(q);
      lastDisplay = q.display;
    }
  }
  return questions;
}

// ── Temel yardımcılar ───────────────────────────────────────────────────────

int _r(Random r, int lo, int hi) {
  if (hi < lo) return lo;
  return r.nextInt(hi - lo + 1) + lo;
}

Question _add(Random r, int lo, int hi) {
  final a = _r(r, lo, hi), b = _r(r, lo, hi);
  return Question(display: '$a + $b = ?', answer: a + b);
}

// a >= b garantili çıkarma
Question _sub(Random r, int lo, int hi) {
  final a = _r(r, lo, hi), b = _r(r, lo, a);
  return Question(display: '$a − $b = ?', answer: a - b);
}

Question _mul(Random r, int lo, int hi) {
  final a = _r(r, lo, hi), b = _r(r, lo, hi);
  return Question(display: '$a × $b = ?', answer: a * b);
}

Question _mulAB(Random r, int aLo, int aHi, int bLo, int bHi) {
  final a = _r(r, aLo, aHi), b = _r(r, bLo, bHi);
  return Question(display: '$a × $b = ?', answer: a * b);
}

// Tam bölünen: divisor × quotient
Question _div(Random r, int dLo, int dHi, int qLo, int qHi) {
  final d = _r(r, dLo, dHi), q = _r(r, qLo, qHi);
  return Question(display: '${d * q} ÷ $d = ?', answer: q);
}

// ── Eksik sayı soruları ─────────────────────────────────────────────────────

Question _missingAdd(Random r, int sumLo, int sumHi) {
  final c = _r(r, sumLo, sumHi);
  final b = _r(r, 1, c - 1);
  return Question(display: '${c - b} + ? = $c', answer: b);
}

Question _missingSub(Random r, int aLo, int aHi, int bLo, int bHi) {
  // a − ? = (a−b)
  final a = _r(r, max(aLo, bLo), aHi);
  final b = _r(r, bLo, min(bHi, a));
  return Question(display: '$a − ? = ${a - b}', answer: b);
}

Question _missingMul(Random r, int lo, int hi) {
  final a = _r(r, lo, hi), x = _r(r, lo, hi);
  return Question(display: '$a × ? = ${a * x}', answer: x);
}

Question _missingDiv(Random r, int dLo, int dHi, int qLo, int qHi) {
  // (d×q) ÷ ? = q
  final d = _r(r, dLo, dHi), q = _r(r, qLo, qHi);
  return Question(display: '${d * q} ÷ ? = $q', answer: d);
}

// ── Diziler ─────────────────────────────────────────────────────────────────

Question _seq(List<int> items, int missing) {
  final parts = List.generate(items.length, (i) => i == missing ? '?' : '${items[i]}');
  return Question(display: parts.join(', '), answer: items[missing]);
}

Question _arithSeq(Random r, int sLo, int sHi, int dLo, int dHi, {int len = 4}) {
  final s = _r(r, sLo, sHi), d = _r(r, dLo, dHi);
  final items = List.generate(len, (i) => s + i * d);
  return _seq(items, r.nextInt(len));
}

Question _descSeq(Random r, int dLo, int dHi, int sHi, {int len = 4}) {
  final d = _r(r, dLo, dHi);
  final s = _r(r, d * (len - 1) + 1, sHi);
  final items = List.generate(len, (i) => s - i * d);
  return _seq(items, r.nextInt(len));
}

Question _geoSeq(Random r, int bLo, int bHi, int ratio, {int len = 4}) {
  final b = _r(r, bLo, bHi);
  final items = List.generate(len, (i) {
    int v = b;
    for (int j = 0; j < i; j++) { v *= ratio; }
    return v;
  });
  return _seq(items, r.nextInt(len));
}

// ── Yüzde ───────────────────────────────────────────────────────────────────

Question _percent(Random r, List<int> percents, int baseLo, int baseHi) {
  final p = percents[r.nextInt(percents.length)];
  final div = 100 ~/ p;
  final base = _r(r, baseLo, baseHi) * div;
  return Question(display: "$base'in %$p'i = ?", answer: base * p ~/ 100);
}

Question _percentIncrease(Random r, List<int> percents, int baseLo, int baseHi) {
  final p = percents[r.nextInt(percents.length)];
  final base = _r(r, baseLo, baseHi) * 10;
  if (base * p % 100 != 0) return _percent(r, percents, baseLo, baseHi);
  return Question(display: '$base TL %$p artınca?', answer: base + base * p ~/ 100);
}

// ── İşlem önceliği ──────────────────────────────────────────────────────────

Question _orderOps(Random r) {
  final type = r.nextInt(4);
  if (type == 0) {
    final a = _r(r, 1, 20), b = _r(r, 2, 9), c = _r(r, 2, 9);
    return Question(display: '$a + $b × $c = ?', answer: a + b * c);
  } else if (type == 1) {
    final a = _r(r, 2, 9), b = _r(r, 2, 9), c = _r(r, 1, 20);
    return Question(display: '$a × $b + $c = ?', answer: a * b + c);
  } else if (type == 2) {
    final a = _r(r, 10, 50), b = _r(r, 2, 9), c = _r(r, 2, 9);
    return Question(display: '$a − $b × $c = ?', answer: a - b * c);
  } else {
    // parantezli
    final a = _r(r, 2, 9), b = _r(r, 2, 9), c = _r(r, 2, 5);
    return Question(display: '($a + $b) × $c = ?', answer: (a + b) * c);
  }
}

Question _orderOpsDiv(Random r) {
  final c = _r(r, 2, 9), q = _r(r, 2, 9), a = _r(r, 1, 30);
  return Question(display: '$a + ${c * q} ÷ $c = ?', answer: a + q);
}

// ── Doğrusal denklemler ─────────────────────────────────────────────────────

Question _linearOne(Random r, int aLo, int aHi, int xLo, int xHi) {
  final a = _r(r, aLo, aHi), x = _r(r, xLo, xHi);
  final t = r.nextInt(2);
  if (t == 0) return Question(display: 'x × $a = ${x * a}', answer: x);
  return Question(display: '$a × x = ${a * x}', answer: x);
}

Question _linearTwo(Random r, int aLo, int aHi, int bLo, int bHi, int xLo, int xHi) {
  final a = _r(r, aLo, aHi), b = _r(r, bLo, bHi), x = _r(r, xLo, xHi);
  return Question(display: '${a}x + $b = ${a * x + b}', answer: x);
}

Question _linearTwoSub(Random r, int aLo, int aHi, int bLo, int bHi, int xLo, int xHi) {
  final a = _r(r, aLo, aHi), b = _r(r, bLo, bHi), x = _r(r, xLo, xHi);
  final c = a * x - b;
  if (c <= 0) return _linearTwo(r, aLo, aHi, bLo, bHi, xLo, xHi);
  return Question(display: '${a}x − $b = $c', answer: x);
}

// ── Zihinden çarpma hileleri ────────────────────────────────────────────────

Question _mentalTrick(Random r) {
  final t = r.nextInt(4);
  switch (t) {
    case 0:
      final n = _r(r, 2, 20);
      return Question(display: '25 × $n = ?', answer: 25 * n);
    case 1:
      final n = _r(r, 2, 20);
      return Question(display: '50 × $n = ?', answer: 50 * n);
    case 2:
      final n = _r(r, 11, 89);
      return Question(display: '11 × $n = ?', answer: 11 * n);
    default:
      final n = _r(r, 3, 20);
      return Question(display: '9 × $n = ?', answer: 9 * n);
  }
}

// ── Negatif sayılar ─────────────────────────────────────────────────────────

Question _negMul(Random r, int lo, int hi) {
  final a = _r(r, lo, hi) * (r.nextBool() ? 1 : -1);
  final b = _r(r, lo, hi) * (r.nextBool() ? 1 : -1);
  if (a == 0 || b == 0) return _negMul(r, lo, hi);
  return Question(display: '$a × $b = ?', answer: a * b);
}

Question _negSub(Random r, int lo, int hi) {
  final a = _r(r, -hi, hi), b = _r(r, 1, hi);
  return Question(display: '$a − (−$b) = ?', answer: a + b);
}

// ── Kare ve karekök ─────────────────────────────────────────────────────────

Question _square(Random r, int lo, int hi) {
  final n = _r(r, lo, hi);
  return Question(display: '$n² = ?', answer: n * n);
}

const _perfectSquares = [4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144, 169, 196, 225];

Question _sqrt(Random r) {
  final n = _perfectSquares[r.nextInt(_perfectSquares.length)];
  return Question(display: '√$n = ?', answer: sqrt(n.toDouble()).round());
}

// ── Modüler aritmetik ────────────────────────────────────────────────────────

Question _powerMod2(Random r) {
  const data = [
    [1, 5, 2], [2, 5, 4], [3, 5, 3], [4, 5, 1],
    [5, 5, 2], [6, 5, 4], [8, 5, 1], [10, 5, 4],
    [1, 7, 2], [2, 7, 4], [3, 7, 1], [4, 7, 2],
    [1, 3, 2], [2, 3, 1], [3, 3, 2], [4, 3, 1],
  ];
  final d = data[r.nextInt(data.length)];
  return Question(display: '2^${d[0]} mod ${d[1]} = ?', answer: d[2]);
}

// ── Oran ─────────────────────────────────────────────────────────────────────

Question _ratioSimple(Random r, int ratioHi, int kHi) {
  final a = _r(r, 2, ratioHi), b = _r(r, 2, ratioHi), k = _r(r, 2, kHi);
  return Question(display: '$a : $b = ${a * k} : ?', answer: b * k);
}

Question _ratioWord(Random r) {
  final t = r.nextInt(2);
  if (t == 0) {
    final a = _r(r, 2, 5), b = _r(r, 2, 5), k = _r(r, 2, 6);
    final total = (a + b) * k;
    return Question(display: 'A:B=$a:$b, toplam $total. A?', answer: a * k);
  }
  final unitCost = _r(r, 2, 9), p = _r(r, 2, 6), q = _r(r, 2, 8);
  return Question(display: '$p elma ${p * unitCost} TL. $q elma?', answer: q * unitCost);
}

// ── İş-hız ve zaman ─────────────────────────────────────────────────────────

Question _obebQ(Random r) {
  const pairs = [
    [12, 18, 6], [24, 36, 12], [15, 25, 5], [20, 30, 10],
    [8, 12, 4], [16, 24, 8], [30, 45, 15], [42, 70, 14],
    [18, 27, 9], [100, 75, 25], [6, 9, 3],
  ];
  final p = pairs[r.nextInt(pairs.length)];
  return Question(display: 'OBEB(${p[0]}, ${p[1]}) = ?', answer: p[2]);
}

Question _okekQ(Random r) {
  const pairs = [
    [4, 6, 12], [3, 5, 15], [4, 10, 20], [6, 9, 18],
    [5, 8, 40], [6, 8, 24], [4, 7, 28], [3, 7, 21],
  ];
  final p = pairs[r.nextInt(pairs.length)];
  return Question(display: 'OKEK(${p[0]}, ${p[1]}) = ?', answer: p[2]);
}

Question _fromPool(Random r, List<Question> pool) => pool[r.nextInt(pool.length)];

// ── Sabit soru havuzları ─────────────────────────────────────────────────────

const _logic = [
  Question(display: 'Ali>Can, Can>Ece. En küçük? (1=Ali 2=Can 3=Ece)', answer: 3),
  Question(display: '3 ardışık sayı toplamı 24. Ortanca?', answer: 8),
  Question(display: '5 ardışık sayı toplamı 30. Ortanca?', answer: 6),
  Question(display: 'A=B+3, A+B=15. A?', answer: 9),
  Question(display: 'A+B=12, A-B=4. A?', answer: 8),
  Question(display: 'A×B=24, A+B=11. Küçük olan?', answer: 3),
  Question(display: 'Çift ve 3\'e bölünür, 20\'den küçük en büyük?', answer: 18),
  Question(display: '3 kutuda toplam 15, biri 7. Kalanların toplamı?', answer: 8),
  Question(display: 'A+B=20, A:B=3:2. A?', answer: 12),
];

const _seqAdv = [
  Question(display: '2, 3, 5, 8, 13, ?', answer: 21),
  Question(display: '1, 4, 9, 16, ?', answer: 25),
  Question(display: '2, 6, 12, 20, 30, ?', answer: 42),
  Question(display: '1, 2, 4, 7, 11, ?', answer: 16),
  Question(display: '3, 4, 6, 9, 13, ?', answer: 18),
  Question(display: '1, 1, 2, 3, 5, 8, ?', answer: 13),
  Question(display: '0, 1, 3, 6, 10, ?', answer: 15),
  Question(display: '2, 5, 10, 17, 26, ?', answer: 37),
];

const _probability = [
  Question(display: 'Zar atışında tek sayı olasılığı: %?', answer: 50),
  Question(display: '2 yazı-tura: en az 1 yazı olasılığı: %?', answer: 75),
  Question(display: '5 toptan 3 kırmızı. Kırmızı çekme: 5\'te kaç?', answer: 3),
  Question(display: 'Zardan çift gelme olasılığı: %?', answer: 50),
  Question(display: '4 toptan 1 mavi. Mavi çekme: 4\'te kaç?', answer: 1),
];

const _workRate = [
  Question(display: '4 işçi 6 günde bitirir. 8 işçi kaç günde?', answer: 3),
  Question(display: '2 musluk 10 saatte dolar. 5 musluk kaç saatte?', answer: 4),
  Question(display: '3 kişi 12 günde bitirir. 4 kişi kaç günde?', answer: 9),
  Question(display: '6 işçi 4 günde bitirir. 3 işçi kaç günde?', answer: 8),
  Question(display: '1 musluk 6 saatte dolar. 3 musluk kaç saatte?', answer: 2),
  Question(display: '5 işçi 8 günde bitirir. 10 işçi kaç günde?', answer: 4),
];

const _optimization = [
  Question(display: 'A: 5 TL/kg, B: 7 TL/kg. 3 kg en ucuz hangisi? (1=A 2=B)', answer: 1),
  Question(display: '3 rota: 12, 15, 9 dk. En kısa kaç dk?', answer: 9),
  Question(display: '2\'li paket 30 TL, 5\'li 70 TL. 10 adet en ucuz seçenek? (1=2li 2=5li)', answer: 1),
  Question(display: '3 kap: 2L, 5L, 8L. 1 litre ölçmek için kaç adım?', answer: 2),
];

const _combinatorics = [
  Question(display: '4 kişiden 2 kişi seçilir. Kaç yol?', answer: 6),
  Question(display: '3 kitap rafa kaç şekilde dizilir?', answer: 6),
  Question(display: '5 kişiden 1 başkan seçilir. Kaç seçim?', answer: 5),
  Question(display: '2 şapka 3 ceket, kaç kombinasyon?', answer: 6),
  Question(display: '3 renk 2 kutuya: kaç dağılım (tekrar olabilir)?', answer: 9),
  Question(display: '4 kitaptan 2 sıralı seçim: kaç yol?', answer: 12),
];

const _expectedValue = [
  Question(display: '%50 ile 10 kazan, yoksa 0. Ortalama kazanç?', answer: 5),
  Question(display: 'Zar: tek→6 puan, çift→0. Ortalama?', answer: 3),
  Question(display: '%25 ile 20 TL, yoksa 0. Beklenen değer?', answer: 5),
  Question(display: '%50 ile 8 kazan, %50 ile 4 kazan. Ortalama?', answer: 6),
];

const _systems = [
  Question(display: 'x+y=10, x-y=4. x?', answer: 7),
  Question(display: '2a+b=11, a=3. b?', answer: 5),
  Question(display: 'x+y=15, x=2y. y?', answer: 5),
  Question(display: 'a-b=3, a+b=11. a?', answer: 7),
  Question(display: 'x+y=18, x=2y. x?', answer: 12),
  Question(display: '3x-y=10, y=5. x?', answer: 5),
  Question(display: 'x+y=20, x=3y. y?', answer: 5),
];

const _constraint = [
  Question(display: '3 ardışık sayı toplamı 24. En büyük?', answer: 9),
  Question(display: 'A×B=36, A+B=13. Küçük olan?', answer: 4),
  Question(display: '5 ardışık tek sayı toplamı 35. Ortanca?', answer: 7),
  Question(display: 'A+B=20, A:B=3:2. A?', answer: 12),
  Question(display: 'A+B=10, A çift, B>A. En büyük A?', answer: 4),
  Question(display: '3 ardışık çift sayı toplamı 54. Ortanca?', answer: 18),
];

const _tricky = [
  Question(display: '1 + 1 × 0 + 1 = ?', answer: 2),
  Question(display: '100 ÷ 4 × 2 = ?', answer: 50),
  Question(display: '2 + 3 × 4 − 1 = ?', answer: 13),
  Question(display: '10 − 2 × 3 + 1 = ?', answer: 5),
  Question(display: '24 ÷ 6 × 2 + 1 = ?', answer: 9),
  Question(display: '5 × 0 + 5 = ?', answer: 5),
  Question(display: '8 + 4 ÷ 2 × 3 = ?', answer: 14),
];

const _hybrid = [
  Question(display: 'x çift, 3x+2=20. x?', answer: 6),
  Question(display: 'A:B=2:5, B−A=9. A?', answer: 6),
  Question(display: 'x asal, x+10=17. x?', answer: 7),
  Question(display: 'A+B=18, A=2B. B?', answer: 6),
  Question(display: 'x tek, x²=49. x?', answer: 7),
  Question(display: 'OBEB(a,6)=3, a<10. a?', answer: 9),
];

const _grandmaster = [
  Question(display: '2, 5, 10, 17, 26, ?', answer: 37),
  Question(display: 'x+y=18, x=2y. y?', answer: 6),
  Question(display: 'OBEB(42, 70) = ?', answer: 14),
  Question(display: '3 ardışık çift sayı toplamı 54. Ortanca?', answer: 18),
  Question(display: '2^8 mod 5 = ?', answer: 1),
  Question(display: 'A×B=48, A+B=14. Büyük olan?', answer: 8),
  Question(display: 'x+y=25, x:y=2:3. y?', answer: 15),
];

// ── Ana seçici ───────────────────────────────────────────────────────────────

Question _pick(Random r, int level) {
  switch (level) {

    // ══ DÜNYA 1 (1-10): 5-8 yaş ══════════════════════════════════════════════

    case 1: {
      // Tek haneli toplama, 0-5 ağırlıklı, sonuç ≤ 10
      final a = _r(r, 0, 5);
      final b = _r(r, 0, min(5, 10 - a));
      return Question(display: '$a + $b = ?', answer: a + b);
    }

    case 2: {
      // Toplama %70, çıkarma %30, 0-10
      if (r.nextInt(10) < 3) return _sub(r, 0, 10);
      return _add(r, 0, 5);
    }

    case 3: {
      // +/- 0-20, nadiren bilinmeyen
      final t = r.nextInt(10);
      if (t < 6) return _add(r, 0, 12);
      if (t < 9) return _sub(r, 0, 12);
      return _missingAdd(r, 5, 15);
    }

    case 4: {
      // Çarpma 1-5 × 1-5
      return _mul(r, 1, 5);
    }

    case 5: {
      // Toplama %45, çıkarma %35, çarpma %20
      final t = r.nextInt(20);
      if (t < 9) return _add(r, 0, 9);
      if (t < 16) return _sub(r, 0, 9);
      return _mul(r, 1, 5);
    }

    case 6: {
      // Dört işlem, bölme %20, 0-30 tam bölünen
      final t = r.nextInt(10);
      if (t < 2) return _div(r, 1, 5, 1, 5);
      if (t < 5) return _mul(r, 1, 5);
      if (t < 8) return _add(r, 0, 15);
      return _sub(r, 0, 15);
    }

    case 7: {
      // Eksik toplanan/çıkan, 0-20
      final t = r.nextInt(5);
      if (t == 0) return _missingAdd(r, 5, 20);
      if (t == 1) return _missingSub(r, 5, 20, 1, 10);
      if (t == 2) {
        // ? - b = c
        final b = _r(r, 1, 8), c = _r(r, 1, 10);
        return Question(display: '? − $b = $c', answer: b + c);
      }
      if (t == 3) return _add(r, 0, 20);
      return _sub(r, 0, 20);
    }

    case 8: {
      // Çarpım tablosu 1-6, çarpma %60 bölme %25 bilinmeyen %15
      final t = r.nextInt(20);
      if (t < 12) return _mul(r, 1, 6);
      if (t < 17) return _div(r, 1, 6, 1, 6);
      if (t < 19) return _missingMul(r, 1, 6);
      return _missingDiv(r, 1, 6, 1, 6);
    }

    case 9: {
      // Aritmetik diziler, artış 1-5
      final t = r.nextInt(4);
      if (t == 0) return _arithSeq(r, 2, 25, 1, 5);
      if (t == 1) return _descSeq(r, 1, 5, 30);
      if (t == 2) return _geoSeq(r, 1, 6, 2);
      return _arithSeq(r, 5, 40, 5, 10);
    }

    case 10: {
      // Dünya 1 final, 0-50 karışık
      final t = r.nextInt(10);
      if (t < 2) return _add(r, 0, 20);
      if (t < 4) return _sub(r, 0, 20);
      if (t < 6) return _mul(r, 1, 6);
      if (t == 6) return _div(r, 1, 6, 1, 6);
      if (t == 7) return _missingAdd(r, 5, 20);
      if (t == 8) return _arithSeq(r, 2, 30, 1, 5);
      return _geoSeq(r, 1, 8, 2);
    }

    // ══ DÜNYA 2 (11-20): 7-12 yaş ════════════════════════════════════════════

    case 11: {
      // 2-haneli +/-, 10-99
      if (r.nextInt(4) < 3) return _add(r, 10, 99);
      return _sub(r, 10, 99);
    }

    case 12: {
      // Çarpım tablosu 1-10
      return _mul(r, 1, 10);
    }

    case 13: {
      // Tam bölme 2-10
      return _div(r, 2, 10, 1, 10);
    }

    case 14: {
      // Dört işlem 0-100
      final t = r.nextInt(4);
      if (t == 0) return _add(r, 10, 99);
      if (t == 1) return _sub(r, 10, 99);
      if (t == 2) return _mul(r, 1, 10);
      return _div(r, 2, 10, 1, 10);
    }

    case 15: {
      // İki adımlı, işlem önceliği yok → (a+b)×c
      final t = r.nextInt(4);
      if (t == 0) {
        final a = _r(r, 1, 10), b = _r(r, 1, 10), c = _r(r, 2, 9);
        return Question(display: '($a + $b) × $c = ?', answer: (a + b) * c);
      }
      if (t == 1) {
        final a = _r(r, 5, 20), b = _r(r, 1, 5), c = _r(r, 2, 5);
        return Question(display: '($a − $b) × $c = ?', answer: (a - b) * c);
      }
      if (t == 2) return _mul(r, 1, 10);
      return _add(r, 10, 99);
    }

    case 16: {
      // Kısa problemler: para ve saat
      final t = r.nextInt(6);
      if (t == 0) {
        final p = _r(r, 2, 9), u = _r(r, 2, 9);
        return Question(display: '$p kalem ${p * u} TL ise 1 kalem?', answer: u);
      }
      if (t == 1) {
        final a = _r(r, 2, 8), b = _r(r, 2, 6);
        return Question(display: '$a kutuda $b kalem. Toplam?', answer: a * b);
      }
      if (t == 2) {
        final total = _r(r, 15, 50), take = _r(r, 1, 10);
        return Question(display: '$total elmadan $take alındı. Kalan?', answer: total - take);
      }
      if (t == 3) return _add(r, 10, 99);
      if (t == 4) return _mul(r, 1, 10);
      return _div(r, 2, 10, 1, 10);
    }

    case 17: {
      // 3-haneli +/-, keypad başlar, 100-999
      final t = r.nextInt(4);
      if (t < 2) return _add(r, 100, 700);
      if (t == 2) return _sub(r, 100, 700);
      return _mul(r, 1, 10);
    }

    case 18: {
      // 2-haneli × 1-haneli, 10-25 × 2-9
      final t = r.nextInt(4);
      if (t == 0) return _mulAB(r, 10, 20, 2, 9);
      if (t == 1) return _mulAB(r, 11, 25, 3, 9);
      if (t == 2) return _mul(r, 2, 12);
      return _missingMul(r, 2, 10);
    }

    case 19: {
      // 2-3 haneli ÷ 1-haneli, tam bölme
      final t = r.nextInt(4);
      if (t == 0) return _div(r, 2, 9, 10, 20);
      if (t == 1) return _div(r, 2, 9, 5, 15);
      if (t == 2) return _mulAB(r, 10, 25, 3, 9);
      return _missingDiv(r, 2, 9, 10, 20);
    }

    case 20: {
      // Dünya 2 final: okul dört işlemi
      final t = r.nextInt(8);
      if (t < 2) return _add(r, 50, 500);
      if (t < 4) return _sub(r, 50, 500);
      if (t == 4) return _mul(r, 2, 12);
      if (t == 5) return _div(r, 2, 9, 10, 20);
      if (t == 6) return _mulAB(r, 10, 25, 3, 9);
      return _arithSeq(r, 10, 90, 3, 15);
    }

    // ══ DÜNYA 3 (21-30): 12+ / yetişkin başlangıç ════════════════════════════

    case 21: {
      // Zihinden 2-haneli hızlı
      final t = r.nextInt(4);
      if (t < 2) return _add(r, 30, 150);
      if (t == 2) return _sub(r, 30, 150);
      return _mulAB(r, 10, 50, 2, 9);
    }

    case 22: {
      // İşlem önceliği: × önce, + sonra
      final t = r.nextInt(4);
      if (t < 2) return _orderOps(r);
      if (t == 2) return _orderOpsDiv(r);
      return _add(r, 20, 100);
    }

    case 23: {
      // Yüzde: 10, 20, 25, 50, 75
      return _percent(r, [10, 20, 25, 50, 75], 2, 20);
    }

    case 24: {
      // Basit kesir → tam sayı cevap
      final t = r.nextInt(4);
      if (t == 0) {
        final n = _r(r, 1, 20) * 2;
        return Question(display: '$n × 0.5 = ?', answer: n ~/ 2);
      }
      if (t == 1) {
        final n = _r(r, 1, 10) * 4;
        return Question(display: '$n × 0.25 = ?', answer: n ~/ 4);
      }
      if (t == 2) {
        final n = _r(r, 2, 20) * 2;
        return Question(display: '$n ÷ 2 = ?', answer: n ~/ 2);
      }
      return _percent(r, [50], 2, 20);
    }

    case 25: {
      // Oran-orantı basit
      final t = r.nextInt(4);
      if (t < 2) return _ratioWord(r);
      if (t == 2) return _ratioSimple(r, 6, 5);
      return _percent(r, [10, 25, 50], 2, 10);
    }

    case 26: {
      // Tek bilinmeyenli denklem
      final t = r.nextInt(4);
      if (t < 2) return _linearOne(r, 2, 15, 2, 20);
      if (t == 2) return _linearTwo(r, 2, 10, 1, 20, 2, 15);
      return _linearTwoSub(r, 2, 10, 1, 20, 2, 15);
    }

    case 27: {
      // Sayı dizileri orta
      final t = r.nextInt(4);
      if (t == 0) return _arithSeq(r, 2, 100, 5, 25);
      if (t == 1) return _descSeq(r, 5, 25, 200);
      if (t == 2) return _geoSeq(r, 1, 8, 2);
      return _geoSeq(r, 1, 5, 3);
    }

    case 28: {
      // 2 adımlı kısa problemler
      final t = r.nextInt(4);
      if (t == 0) {
        final boxes = _r(r, 2, 8), per = _r(r, 3, 9), taken = _r(r, 1, 5);
        return Question(display: '$boxes kutuda $per kalem, $taken alındı. Kalan?', answer: boxes * per - taken);
      }
      if (t == 1) {
        final price = _r(r, 2, 10) * 10;
        return Question(display: '$price TL, %10 indirim. Kalan?', answer: price - price ~/ 10);
      }
      if (t == 2) return _linearTwo(r, 2, 9, 1, 20, 2, 20);
      return _percent(r, [10, 20, 25, 50], 2, 20);
    }

    case 29: {
      // Modüler aritmetik başlangıç
      final t = r.nextInt(4);
      if (t < 2) {
        final a = _r(r, 20, 100), m = _r(r, 3, 9);
        return Question(display: '$a mod $m = ?', answer: a % m);
      }
      if (t == 2) return _obebQ(r);
      return _sub(r, 50, 300);
    }

    case 30: {
      // Dünya 3 final: günlük + cebir + örüntü
      final t = r.nextInt(8);
      if (t < 2) return _orderOps(r);
      if (t < 4) return _percent(r, [10, 20, 25, 50], 2, 20);
      if (t == 4) return _linearTwo(r, 2, 9, 1, 15, 2, 15);
      if (t == 5) return _arithSeq(r, 5, 100, 5, 20);
      if (t == 6) return _geoSeq(r, 1, 8, 2);
      {
        final a = _r(r, 20, 100), m = _r(r, 3, 9);
        return Question(display: '$a mod $m = ?', answer: a % m);
      }
    }

    // ══ DÜNYA 4 (31-40): Yetişkin ════════════════════════════════════════════

    case 31: return _mentalTrick(r);

    case 32: {
      final t = r.nextInt(4);
      if (t == 0) return _negMul(r, 1, 9);
      if (t == 1) return _negSub(r, 1, 15);
      if (t == 2) {
        final a = _r(r, -20, 20), b = _r(r, 1, 15);
        return Question(display: '$a + $b = ?', answer: a + b);
      }
      final a = _r(r, -50, 50), b = _r(r, -20, 20);
      return Question(display: '$a − ($b) = ?', answer: a - b);
    }

    case 33: {
      // 3 işlemli öncelikli ifadeler
      final t = r.nextInt(4);
      if (t < 2) return _orderOps(r);
      if (t == 2) return _orderOpsDiv(r);
      final a = _r(r, 2, 9), b = _r(r, 2, 9), c = _r(r, 2, 5), d = _r(r, 2, 5);
      return Question(display: '$a × $b + $c × $d = ?', answer: a * b + c * d);
    }

    case 34: {
      // Yüzde zinciri: artış/indirim
      final t = r.nextInt(4);
      if (t < 2) return _percentIncrease(r, [10, 20, 50], 2, 20);
      return _percent(r, [10, 20, 25, 50], 2, 20);
    }

    case 35: {
      // Oran ve karışım
      final t = r.nextInt(4);
      if (t < 2) return _ratioWord(r);
      if (t == 2) return _fromPool(r, _workRate);
      return _ratioSimple(r, 6, 8);
    }

    case 36: {
      // Kare ve karekök
      final t = r.nextInt(4);
      if (t < 2) return _square(r, 2, 20);
      return _sqrt(r);
    }

    case 37: {
      // Mantık hafif
      final t = r.nextInt(4);
      if (t < 2) return _fromPool(r, _logic);
      if (t == 2) return _square(r, 2, 15);
      return _obebQ(r);
    }

    case 38: {
      // Mod ve bölünebilirlik
      final t = r.nextInt(4);
      if (t < 2) {
        final a = _r(r, 100, 9999), m = _r(r, 3, 12);
        return Question(display: '$a mod $m = ?', answer: a % m);
      }
      if (t == 2) return _obebQ(r);
      return _okekQ(r);
    }

    case 39: {
      // Karışık cebir
      final t = r.nextInt(4);
      if (t < 2) return _linearTwo(r, 3, 12, 2, 30, 2, 20);
      if (t == 2) return _missingMul(r, 2, 15);
      return _orderOps(r);
    }

    case 40: {
      // Dünya 4 final
      final t = r.nextInt(8);
      if (t == 0) return _mentalTrick(r);
      if (t == 1) return _negMul(r, 1, 12);
      if (t == 2) return _percent(r, [10, 20, 25], 2, 20);
      if (t == 3) return _ratioWord(r);
      if (t == 4) return _linearTwo(r, 3, 12, 2, 30, 2, 20);
      if (t == 5) return _orderOps(r);
      if (t == 6) return _fromPool(r, _logic);
      return _obebQ(r);
    }

    // ══ DÜNYA 5 (41-50): İleri yetişkin ══════════════════════════════════════

    case 41: {
      // Cebir: 2-3 adımlı
      final t = r.nextInt(4);
      if (t < 2) return _linearTwo(r, 3, 20, 2, 50, 2, 25);
      if (t == 2) return _linearTwoSub(r, 3, 15, 1, 30, 2, 20);
      final a = _r(r, 2, 10), b = _r(r, 2, 8), x = _r(r, 5, 20);
      return Question(display: '(x − $a) × $b = ${(x - a) * b}', answer: x);
    }

    case 42: {
      // Karma örüntü
      final t = r.nextInt(4);
      if (t < 2) return _fromPool(r, _seqAdv);
      if (t == 2) return _geoSeq(r, 1, 5, 3, len: 5);
      return _arithSeq(r, 5, 100, 7, 30);
    }

    case 43: {
      // Asal ve çarpan: OBEB, OKEK
      final t = r.nextInt(4);
      if (t < 2) return _obebQ(r);
      if (t == 2) return _okekQ(r);
      // Kaç asal çarpanı var
      const data = [[12, 3], [18, 3], [20, 3], [24, 4], [30, 4], [36, 4], [48, 5], [60, 5]];
      final d = data[r.nextInt(data.length)];
      return Question(display: "${d[0]}'in asal çarpan sayısı?", answer: d[1]);
    }

    case 44: return _fromPool(r, _probability);

    case 45: {
      // Saat-takvim modüler
      final t = r.nextInt(4);
      if (t < 2) {
        const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        final start = r.nextInt(7), add = _r(r, 3, 20);
        return Question(display: '${days[start]}\'den $add gün sonra? (0=Pzt…6=Paz)', answer: (start + add) % 7);
      }
      if (t == 2) {
        final h = _r(r, 1, 22), add = _r(r, 1, 11);
        return Question(display: 'Saat $h:00, $add saat sonra?', answer: (h + add) % 24);
      }
      final a = _r(r, 20, 200), m = _r(r, 7, 12);
      return Question(display: '$a mod $m = ?', answer: a % m);
    }

    case 46: return _fromPool(r, _optimization);

    case 47: return _fromPool(r, _workRate);

    case 48: {
      // Parite ve mantık
      final t = r.nextInt(4);
      if (t < 2) return _fromPool(r, _logic);
      if (t == 2) return _powerMod2(r);
      return _fromPool(r, _seqAdv);
    }

    case 49: {
      // Bileşik: yüzde + oran + cebir
      final t = r.nextInt(4);
      if (t < 2) return _linearTwo(r, 3, 15, 5, 50, 2, 20);
      if (t == 2) return _ratioWord(r);
      return _percent(r, [10, 20, 25, 50], 2, 20);
    }

    case 50: {
      // Dünya 5 final
      final t = r.nextInt(8);
      if (t == 0) return _fromPool(r, _seqAdv);
      if (t == 1) return _obebQ(r);
      if (t == 2) return _fromPool(r, _probability);
      if (t == 3) return _linearTwo(r, 3, 15, 5, 50, 2, 20);
      if (t == 4) return _fromPool(r, _logic);
      if (t == 5) {
        const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        final start = r.nextInt(7), add = _r(r, 3, 20);
        return Question(display: '${days[start]}\'den $add gün sonra? (0=Pzt…6=Paz)', answer: (start + add) % 7);
      }
      if (t == 6) return _ratioWord(r);
      return _fromPool(r, _workRate);
    }

    // ══ DÜNYA 6 (51-60): Uzman ════════════════════════════════════════════════

    case 51: return _fromPool(r, _constraint);

    case 52: {
      final t = r.nextInt(4);
      if (t < 2) return _fromPool(r, _seqAdv);
      if (t == 2) return _geoSeq(r, 1, 4, 3, len: 5);
      return _powerMod2(r);
    }

    case 53: {
      // Modüler ustalık
      final t = r.nextInt(4);
      if (t < 2) return _powerMod2(r);
      if (t == 2) {
        const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        final start = r.nextInt(7), add = _r(r, 10, 100);
        return Question(display: '${days[start]}\'den $add gün sonra? (0=Pzt…6=Paz)', answer: (start + add) % 7);
      }
      final a = _r(r, 1000, 9999), m = _r(r, 3, 12);
      return Question(display: '$a mod $m = ?', answer: a % m);
    }

    case 54: return _fromPool(r, _combinatorics);

    case 55: return _fromPool(r, _expectedValue);

    case 56: {
      // Denklem sistemi
      final t = r.nextInt(4);
      if (t < 2) return _fromPool(r, _systems);
      if (t == 2) return _linearTwo(r, 3, 15, 5, 50, 2, 20);
      return _obebQ(r);
    }

    case 57: {
      // Strateji ve mantık
      const strategy = [
        Question(display: '1-2 taş alınır, 4 taşta kazanılır. Başlayan kaç almalı?', answer: 1),
        Question(display: 'Ali ve Buse sırayla taş alır. 7 taş kalınca kazanılır. Sıradaki?', answer: 1),
      ];
      final t = r.nextInt(4);
      if (t < 2) return _fromPool(r, strategy);
      if (t == 2) return _fromPool(r, _logic);
      return _fromPool(r, _constraint);
    }

    case 58: return _fromPool(r, _tricky);

    case 59: {
      // Hibrit expert
      final t = r.nextInt(6);
      if (t < 2) return _fromPool(r, _hybrid);
      if (t < 4) return _fromPool(r, _systems);
      if (t == 4) return _fromPool(r, _constraint);
      return _powerMod2(r);
    }

    default: {
      // Level 60: Grandmaster
      final t = r.nextInt(10);
      if (t < 2) return _fromPool(r, _grandmaster);
      if (t < 4) return _fromPool(r, _systems);
      if (t < 6) return _fromPool(r, _hybrid);
      if (t < 8) return _fromPool(r, _constraint);
      if (t == 8) return _fromPool(r, _seqAdv);
      return _powerMod2(r);
    }
  }
}
