import 'dart:math';
import 'question.dart';

const int uzmanQuestionsPerLevel = 20;
const int uzmanPassThreshold = 16; // 80% of 20

List<Question> generateUzmanLevel(int level, Random rng) {
  final questions = <Question>[];
  String? lastDisplay;
  int attempts = 0;
  while (questions.length < uzmanQuestionsPerLevel && attempts < 800) {
    attempts++;
    final q = _pick(rng, level);
    if (q.display != lastDisplay) {
      questions.add(q);
      lastDisplay = q.display;
    }
  }
  return questions;
}

int _r(Random r, int lo, int hi) {
  if (hi <= lo) return lo;
  return lo + r.nextInt(hi - lo + 1);
}

Question _q(String display, int answer) => Question(display: display, answer: answer);

// ── Aritmetik ────────────────────────────────────────────────────────────────

Question _add(Random r, int aLo, int aHi, int bLo, int bHi) {
  final a = _r(r, aLo, aHi);
  final b = _r(r, bLo, bHi);
  return _q('$a + $b = ?', a + b);
}

Question _sub(Random r, int aLo, int aHi, int bLo, int bHi) {
  final a = _r(r, aLo, aHi);
  final b = _r(r, bLo, min(bHi, a - 1));
  return _q('$a - $b = ?', a - b);
}

Question _mul(Random r, int aLo, int aHi, int bLo, int bHi) {
  final a = _r(r, aLo, aHi);
  final b = _r(r, bLo, bHi);
  return _q('$a × $b = ?', a * b);
}

Question _div(Random r, int divLo, int divHi, int qLo, int qHi) {
  final d = _r(r, divLo, divHi);
  final q = _r(r, qLo, qHi);
  return _q('${d * q} ÷ $d = ?', q);
}

Question _missingAdd(Random r, int aLo, int aHi, int bLo, int bHi) {
  final a = _r(r, aLo, aHi);
  final b = _r(r, bLo, bHi);
  return _q('$a + X = ${a + b}', b);
}

Question _missingSub(Random r, int aLo, int aHi, int bLo, int bHi) {
  final a = _r(r, aLo, aHi);
  final b = _r(r, bLo, min(bHi, a - 1));
  return _q('$a - X = ${a - b}', b);
}

Question _missingMul(Random r, int aLo, int aHi, int bLo, int bHi) {
  final a = _r(r, aLo, aHi);
  final b = _r(r, bLo, bHi);
  return _q('$a × X = ${a * b}', b);
}

Question _missingDiv(Random r, int divLo, int divHi, int qLo, int qHi) {
  final d = _r(r, divLo, divHi);
  final q = _r(r, qLo, qHi);
  return _q('X ÷ $d = $q', d * q);
}

// ── İşlem önceliği ──────────────────────────────────────────────────────────

Question _orderOps(Random r) {
  // a + b × c
  final b = _r(r, 2, 15);
  final c = _r(r, 2, 12);
  final a = _r(r, 5, 50);
  return _q('$a + $b × $c = ?', a + b * c);
}

Question _orderOpsParen(Random r) {
  // (a + b) × c - d
  final a = _r(r, 5, 30);
  final b = _r(r, 2, 20);
  final c = _r(r, 2, 9);
  final d = _r(r, 1, 30);
  final res = (a + b) * c - d;
  if (res <= 0) return _orderOps(r);
  return _q('($a + $b) × $c - $d = ?', res);
}

Question _orderOpsComplex(Random r) {
  // (a + b) × (c ÷ d) - e²
  final d = _r(r, 2, 9);
  final q = _r(r, 2, 9);
  final c = d * q;
  final a = _r(r, 5, 20);
  final b = _r(r, 3, 15);
  final e = _r(r, 2, 7);
  final res = (a + b) * (c ~/ d) - e * e;
  if (res <= 0) return _orderOpsParen(r);
  return _q('($a+$b)×($c÷$d) - $e² = ?', res);
}

// ── Tahmin ──────────────────────────────────────────────────────────────────

Question _estimate100(Random r) {
  final a = _r(r, 100, 950);
  final b = _r(r, 100, 950);
  final sum = a + b;
  final rounded = ((sum + 50) ~/ 100) * 100;
  return _q('$a + $b ≈ ? (en yakın 100)', rounded);
}

Question _estimate10(Random r) {
  final a = _r(r, 10, 90);
  final b = _r(r, 10, 90);
  final sum = a + b;
  final rounded = ((sum + 5) ~/ 10) * 10;
  return _q('$a + $b ≈ ? (en yakın 10)', rounded);
}

// ── Diziler ──────────────────────────────────────────────────────────────────

Question _arithSeq(Random r, int startLo, int startHi, int diffLo, int diffHi) {
  final start = _r(r, startLo, startHi);
  final diff = _r(r, diffLo, diffHi);
  final len = _r(r, 4, 6);
  final terms = List.generate(len + 1, (i) => start + i * diff);
  final hide = r.nextInt(len) + 1;
  final shown = terms.map((t) => t == terms[hide] ? 'X' : '$t').toList()..removeLast();
  return _q(shown.join(', ') + ', ... → X = ?', terms[hide]);
}

Question _diffSeq(Random r) {
  // Farkların farkı = k (second difference)
  final first = _r(r, 1, 10);
  final d0 = _r(r, 2, 5);
  final dd = _r(r, 1, 3);
  final terms = <int>[first];
  int d = d0;
  for (int i = 0; i < 5; i++) {
    terms.add(terms.last + d);
    d += dd;
  }
  final shown = terms.sublist(0, 5).join(', ');
  return _q('$shown, X = ?', terms[5]);
}

Question _geoSeq(Random r, int baseLo, int baseHi, int ratio) {
  final b = _r(r, baseLo, baseHi);
  final terms = List.generate(5, (i) {
    int v = b;
    for (int j = 0; j < i; j++) { v *= ratio; }
    return v;
  });
  final shown = terms.sublist(0, 4).join(', ');
  return _q('$shown, X = ?', terms[4]);
}

Question _doubleAddSeq(Random r) {
  // a_n = 2*a_{n-1} + k
  final first = _r(r, 2, 8);
  final k = _r(r, 1, 5);
  final terms = <int>[first];
  for (int i = 0; i < 4; i++) { terms.add(terms.last * 2 + k); }
  final shown = terms.sublist(0, 4).join(', ');
  return _q('$shown, X = ?', terms[4]);
}

Question _fibLike(Random r) {
  final a = _r(r, 1, 5);
  final b = _r(r, 1, 5);
  final terms = [a, b];
  for (int i = 0; i < 4; i++) { terms.add(terms[terms.length - 1] + terms[terms.length - 2]); }
  final shown = terms.sublist(0, 5).join(', ');
  return _q('$shown, X = ?', terms[5]);
}

// ── Yüzde ──────────────────────────────────────────────────────────────────

Question _percentOf(Random r) {
  final pcts = [5, 10, 15, 20, 25, 30, 35, 40, 50, 60, 75, 80];
  final p = pcts[r.nextInt(pcts.length)];
  final base = _r(r, 2, 20) * 10;
  return _q('$base\'ın %$p\'i = ?', base * p ~/ 100);
}

Question _percentReverse(Random r) {
  final pcts = [20, 25, 40, 50, 60, 80];
  final p = pcts[r.nextInt(pcts.length)];
  final x = _r(r, 5, 30) * p ~/ 5;
  final base = x * 100 ~/ p;
  if (base * p ~/ 100 != x) return _percentOf(r);
  return _q('Bir sayının %$p\'i $x. Sayı = ?', base);
}

Question _percentIncrease(Random r) {
  final pcts = [10, 20, 25, 50];
  final p = pcts[r.nextInt(pcts.length)];
  final base = _r(r, 4, 20) * 10;
  return _q('$base, %$p artarsa = ?', base + base * p ~/ 100);
}

// ── Oran ────────────────────────────────────────────────────────────────────

Question _ratio(Random r) {
  final unit = _r(r, 3, 15);
  final a = _r(r, 3, 10);
  final b = _r(r, 3, 12);
  final price = unit * a;
  return _q('$a ürün $price TL ise $b ürün kaç TL?', unit * b);
}

Question _inverseProp(Random r) {
  final workers = _r(r, 2, 6);
  final days = _r(r, 3, 10);
  final moreWorkers = workers + _r(r, 1, 4);
  final result = workers * days ~/ moreWorkers;
  if (result <= 0 || workers * days % moreWorkers != 0) return _ratio(r);
  return _q('$workers işçi $days günde bitirir. $moreWorkers işçi kaç günde bitirir?', result);
}

// ── Denklem ────────────────────────────────────────────────────────────────

Question _linearEq(Random r, int aLo, int aHi, int xLo, int xHi, int bRange) {
  final a = _r(r, aLo, aHi);
  final x = _r(r, xLo, xHi);
  final b = _r(r, 1, bRange);
  final c = a * x + b;
  return _q('${a}X + $b = $c', x);
}

Question _linearEqParen(Random r, int xLo, int xHi, int bLo, int bHi, int cLo, int cHi) {
  final b = _r(r, bLo, bHi);
  final c = _r(r, cLo, cHi);
  final x = _r(r, xLo, xHi);
  final right = (x + b) * c;
  return _q('(X + $b) × $c = $right', x);
}

Question _negLinear(Random r) {
  // aX - b = c where x can be any integer
  final a = _r(r, 2, 9);
  final x = _r(r, -15, 25);
  final b = _r(r, 1, 30);
  final c = a * x - b;
  return _q('${a}X - $b = $c', x);
}

// ── Mod / Kalan ─────────────────────────────────────────────────────────────

Question _modQ(Random r, int nLo, int nHi, int mLo, int mHi) {
  final m = _r(r, mLo, mHi);
  final n = _r(r, nLo, nHi);
  return _q('$n mod $m = ?', n % m);
}

Question _missingMod(Random r) {
  final m = _r(r, 3, 12);
  final rem = _r(r, 1, m - 1);
  final base = _r(r, 5, 15) * m + rem;
  return _q('X mod $m = $rem, X > ${base - m}, en küçük X = ?', base);
}

// ── Üs / Kök ────────────────────────────────────────────────────────────────

Question _square(Random r, int lo, int hi) {
  final a = _r(r, lo, hi);
  return _q('$a² = ?', a * a);
}

Question _cube(Random r, int lo, int hi) {
  final a = _r(r, lo, hi);
  return _q('$a³ = ?', a * a * a);
}

Question _sqrt(Random r) {
  final squares = [4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144, 169, 196, 225, 256, 289, 324, 361, 400, 484, 529, 625, 784, 900, 1024, 1296, 1600];
  final sq = squares[r.nextInt(squares.length)];
  return _q('√$sq = ?', sqrt(sq.toDouble()).round());
}

Question _power2(Random r, int expLo, int expHi) {
  final exp = _r(r, expLo, expHi);
  final result = pow(2, exp).toInt();
  return _q('2^$exp = ?', result);
}

Question _powerMissExp(Random r) {
  final bases = [2, 3, 4, 5];
  final base = bases[r.nextInt(bases.length)];
  final exp = _r(r, 2, 7);
  final result = pow(base, exp).toInt();
  return _q('$base^X = $result', exp);
}

Question _squareMissBase(Random r, int lo, int hi) {
  final x = _r(r, lo, hi);
  return _q('X² = ${x * x}', x);
}

// ── Negatif ─────────────────────────────────────────────────────────────────

Question _negMul(Random r) {
  final a = _r(r, 2, 20);
  final b = _r(r, 2, 15);
  final sign = r.nextBool() ? -1 : 1;
  return _q('${sign == -1 ? '-' : ''}$a × $b = ?', sign * a * b);
}

Question _negSubEq(Random r) {
  final x = _r(r, -30, 30);
  final b = _r(r, 1, 40);
  final c = x - b;
  return _q('X - $b = $c', x);
}

// ── Kombinatorik ────────────────────────────────────────────────────────────

int _nCr(int n, int k) {
  if (k > n) return 0;
  if (k == 0 || k == n) return 1;
  int result = 1;
  for (int i = 0; i < k; i++) {
    result = result * (n - i) ~/ (i + 1);
  }
  return result;
}

int _nPr(int n, int k) {
  int result = 1;
  for (int i = 0; i < k; i++) { result *= (n - i); }
  return result;
}

Question _comb(Random r, int nLo, int nHi, int rLo, int rHi) {
  final n = _r(r, nLo, nHi);
  final k = _r(r, rLo, min(rHi, n - 1));
  return _q('C($n, $k) = ?', _nCr(n, k));
}

Question _perm(Random r, int nLo, int nHi, int rLo, int rHi) {
  final n = _r(r, nLo, nHi);
  final k = _r(r, rLo, min(rHi, n));
  return _q('P($n, $k) = ?', _nPr(n, k));
}

Question _combWord(Random r) {
  final people = [5, 6, 7, 8, 9, 10];
  final n = people[r.nextInt(people.length)];
  final k = _r(r, 2, min(4, n - 1));
  return _q('$n kişiden $k kişi kaç şekilde seçilir?', _nCr(n, k));
}

// ── Olasılık ────────────────────────────────────────────────────────────────

// Dice sum probabilities (count out of 36)
Question _diceSum(Random r) {
  final counts = {2: 1, 3: 2, 4: 3, 5: 4, 6: 5, 7: 6, 8: 5, 9: 4, 10: 3, 11: 2, 12: 1};
  final sums = counts.keys.toList();
  final s = sums[r.nextInt(sums.length)];
  return _q('2 zar atılır. Toplam $s gelme olasılığı: kaçta kaç? (pay/36)', counts[s]!);
}

Question _coinFlips(Random r) {
  // n kez para atılır, tam k yazı gelme: count
  final templates = [
    ('3 para atılır. Tam 2 yazı kaç olasılık (8 üzerinden)?', 3),
    ('3 para atılır. En az 2 yazı kaç olasılık (8 üzerinden)?', 4),
    ('4 para atılır. Tam 2 yazı kaç olasılık (16 üzerinden)?', 6),
  ];
  final t = templates[r.nextInt(templates.length)];
  return _q(t.$1, t.$2);
}

// ── Fonksiyon ───────────────────────────────────────────────────────────────

Question _funcEval(Random r) {
  // f(x) = ax² + bx + c, evaluate at x
  final a = _r(r, 1, 3);
  final b = _r(r, -5, 8);
  final c = _r(r, -10, 15);
  final x = _r(r, 2, 9);
  final res = a * x * x + b * x + c;
  final bStr = b < 0 ? '$b' : '+$b';
  final cStr = c < 0 ? '$c' : '+$c';
  return _q('f(x) = ${a}x²${bStr}x$cStr → f($x) = ?', res);
}

Question _funcCompose(Random r) {
  // f(x) = ax+b, g(x) = x², f(g(x0))
  final a = _r(r, 1, 4);
  final b = _r(r, -5, 10);
  final x0 = _r(r, 2, 7);
  final gx = x0 * x0;
  final bStr = b < 0 ? '$b' : '+$b';
  return _q('f(x) = ${a}x$bStr, g(x) = x²\nf(g($x0)) = ?', a * gx + b);
}

Question _funcEvalLinear(Random r) {
  final a = _r(r, 1, 5);
  final b = _r(r, -8, 12);
  final x = _r(r, 2, 12);
  final bStr = b < 0 ? '$b' : '+$b';
  return _q('f(x) = ${a}x$bStr → f($x) = ?', a * x + b);
}

// ── Logaritma ───────────────────────────────────────────────────────────────

Question _logQ(Random r) {
  // Perfect logarithms: log_base(value) = exp
  final logPairs = [
    (2, 4, 2), (2, 8, 3), (2, 16, 4), (2, 32, 5), (2, 64, 6), (2, 128, 7), (2, 256, 8),
    (3, 9, 2), (3, 27, 3), (3, 81, 4), (3, 243, 5),
    (4, 16, 2), (4, 64, 3), (4, 256, 4),
    (5, 25, 2), (5, 125, 3), (5, 625, 4), (5, 3125, 5),
    (10, 100, 2), (10, 1000, 3), (10, 10000, 4),
  ];
  final pair = logPairs[r.nextInt(logPairs.length)];
  return _q('log${pair.$1}(${pair.$2}) = ?', pair.$3);
}

Question _logExp(Random r) {
  // base^X = value
  final pairs = [
    (2, 32, 5), (2, 64, 6), (2, 128, 7), (2, 256, 8),
    (3, 81, 4), (3, 243, 5),
    (5, 125, 3), (5, 625, 4), (5, 3125, 5),
  ];
  final pair = pairs[r.nextInt(pairs.length)];
  return _q('${pair.$1}^X = ${pair.$2}', pair.$3);
}

// ── Matris ──────────────────────────────────────────────────────────────────

Question _matrixDet(Random r) {
  final a = _r(r, -6, 9);
  final b = _r(r, -6, 9);
  final c = _r(r, -6, 9);
  final d = _r(r, -6, 9);
  final det = a * d - b * c;
  return _q('det[[${_m(a)},${_m(b)}],[${_m(c)},${_m(d)}]] = ?', det);
}

String _m(int v) => '$v';

// ── Sayı Teorisi ─────────────────────────────────────────────────────────────

int _tau(int n) {
  int count = 0;
  for (int i = 1; i <= sqrt(n.toDouble()).floor(); i++) {
    if (n % i == 0) { count += (i == n ~/ i) ? 1 : 2; }
  }
  return count;
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
int _lcm(int a, int b) => a ~/ _gcd(a, b) * b;

Question _divisorCount(Random r) {
  final nums = [12, 18, 24, 30, 36, 48, 60, 72, 84, 100, 120, 144, 180, 210, 240, 360, 420, 504, 720, 840, 1260];
  final n = nums[r.nextInt(nums.length)];
  return _q('$n\'in pozitif bölen sayısı = ?', _tau(n));
}

Question _gcdQ(Random r) {
  final d = _r(r, 2, 15);
  final a = d * _r(r, 2, 12);
  final b = d * _r(r, 2, 12);
  if (_gcd(a, b) != d) return _gcdQ(r);
  return _q('EBOB($a, $b) = ?', d);
}

Question _lcmQ(Random r) {
  final a = _r(r, 4, 20);
  final b = _r(r, 4, 20);
  return _q('EKOK($a, $b) = ?', _lcm(a, b));
}

int _eulerPhi(int n) {
  int result = n;
  for (int p = 2; p * p <= n; p++) {
    if (n % p == 0) {
      while (n % p == 0) { n ~/= p; }
      result -= result ~/ p;
    }
  }
  if (n > 1) result -= result ~/ n;
  return result;
}

Question _phiQ(Random r) {
  final nums = [6, 8, 10, 12, 15, 18, 20, 24, 30, 36, 40, 48, 60, 72, 100];
  final n = nums[r.nextInt(nums.length)];
  return _q('φ($n) = ?', _eulerPhi(n));
}

// ── Optimizasyon ─────────────────────────────────────────────────────────────

Question _maxProduct(Random r, int sLo, int sHi) {
  final s = _r(r, sLo, sHi) * 2; // even sum for clean answer
  final max = (s ~/ 2) * (s - s ~/ 2);
  return _q('Toplamı $s olan iki pozitif tam sayının çarpımı en fazla kaçtır?', max);
}

// ── Graf ────────────────────────────────────────────────────────────────────

Question _graphEdges(Random r, int nLo, int nHi) {
  final n = _r(r, nLo, nHi);
  return _q('$n düğümlü tam graf kaç kenar içerir?', n * (n - 1) ~/ 2);
}

// ── CRT ─────────────────────────────────────────────────────────────────────

Question _crt(Random r) {
  // X ≡ a (mod m), X ≡ b (mod n), gcd(m,n)=1, find smallest positive X
  final mList = [3, 4, 5, 7];
  final nList = [5, 7, 8, 11];
  final mi = r.nextInt(mList.length);
  final ni = r.nextInt(nList.length);
  final m = mList[mi];
  final n = nList[ni];
  if (_gcd(m, n) != 1) return _crt(r);
  final a = _r(r, 0, m - 1);
  final b = _r(r, 0, n - 1);
  // Brute force smallest positive X
  for (int x = 1; x <= m * n; x++) {
    if (x % m == a && x % n == b) return _q('X ≡ $a (mod $m)\nX ≡ $b (mod $n)\nEn küçük pozitif X = ?', x);
  }
  return _q('X ≡ $a (mod $m)\nX ≡ $b (mod $n)\nEn küçük pozitif X = ?', a); // fallback
}

// ── Stars and Bars ──────────────────────────────────────────────────────────

Question _starsAndBars(Random r) {
  final balls = _r(r, 4, 7);
  final boxes = _r(r, 2, 4);
  final ans = _nCr(balls + boxes - 1, boxes - 1);
  return _q('$balls özdeş top $boxes kutuya (kutu boş kalabilir) kaç şekilde dağıtılır?', ans);
}

// ── Büyük aritmetik ──────────────────────────────────────────────────────────

Question _bigMul(Random r) {
  final a = _r(r, 100, 999);
  final b = _r(r, 11, 99);
  return _q('$a × $b = ?', a * b);
}

Question _bigDiv(Random r) {
  final d = _r(r, 8, 25);
  final q = _r(r, 50, 200);
  return _q('${d * q} ÷ $d = ?', q);
}

// ── Kısıtlı sayma ───────────────────────────────────────────────────────────

Question _restrictedPerm(Random r) {
  final n = _r(r, 4, 7);
  // n kişi sıralanır, A ve B yan yana olmaz
  final total = _factorial(n);
  final adjBad = 2 * _factorial(n - 1);
  return _q('$n kişi sıralanır. A ve B yan yana olmaz. Kaç farklı sıra?', total - adjBad);
}

int _factorial(int n) {
  int result = 1;
  for (int i = 2; i <= n; i++) { result *= i; }
  return result;
}

// ── Derangement ─────────────────────────────────────────────────────────────

Question _derangement(Random r) {
  final derangements = {3: 2, 4: 9, 5: 44, 6: 265};
  final n = [3, 4, 5, 6][r.nextInt(4)];
  return _q('$n elemanlı derangement sayısı (hiç kimse kendi yerine gelmiyor) = ?', derangements[n]!);
}

// ── Hardcoded pools ──────────────────────────────────────────────────────────

Question _fromPool(Random r, List<(String, int)> pool) {
  final t = pool[r.nextInt(pool.length)];
  return _q(t.$1, t.$2);
}

const _logicPool = [
  ('Ali 3. sırada değil. Veli son değil. Beraber 3 kişi var. En az kaç sıralama mümkün?', 4),
  ('5 kişi sıralanıyor. A en önde, B en arkada. Ortadaki 3 kaç sırada dizilir?', 6),
  ('4 kişiden başkan ve yardımcı seçilir (aynı kişi ikisi olamaz). Kaç seçenek?', 12),
  ('3 kırmızı, 2 mavi top. Torbadan 2 top çekilir. En az 1 kırmızı kaç yol?', 9),
  ('6 kişilik komiteden 4 kişi seçilir. A ve B birlikte seçilemez. Kaç yol?', 9),
];

const _modArithPool = [
  ('Bugün Pazartesi (1). 100 gün sonra haftanın kaçıncı günü? (1=Pzt, 7=Pz)', 2),
  ('Saat 10:00\'dan 250 saat sonra saat kaç? (saat)', 20),
  ('2^100 son rakamı nedir?', 6),
  ('3^50 son rakamı nedir?', 9),
  ('7^80 son rakamı nedir?', 1),
];

const _workRatePool = [
  ('A işi 6 günde, B işi 12 günde bitirir. Birlikte kaç günde bitirir?', 4),
  ('A işi 4 günde, B işi 6 günde bitirir. Birlikte kaç günde bitirir?', 2), // 12/5 → not integer
  ('A bir havuzu 3 saatte doldurur, B 6 saatte boşaltır. İkisi açıkken kaç saatte dolar?', 6),
  ('A işi 5 günde, B işi 10 günde bitirir. Birlikte kaç günde bitirir?', 3), // 10/3 not integer
  ('A yolu 8 saatte, B 12 saatte gider. Birlikte aynı yolu kaç saatte giderler?', 5), // 24/5 not int
];

// Fix work rate - only use integer answers
const _workRatePoolFixed = [
  ('A işi 6 günde, B işi 12 günde bitirir. Birlikte kaç günde bitirir?', 4),
  ('A işi 8 günde, B işi 8 günde bitirir. Birlikte kaç günde bitirir?', 4),
  ('A işi 4 günde, B işi 12 günde bitirir. Birlikte kaç günde bitirir?', 3),
  ('A havuzu 4 saatte doldurur, B 12 saatte doldurur. Birlikte kaç saatte dolar?', 3),
  ('A yolu 6 saatte, B 12 saatte gider. Ortak giderlerse kaç saatte?', 4),
];

const _expectedValuePool = [
  ('Adil zar atılır. Çıkan sayı kadar puan. Beklenen puan × 2 = ?', 7),
  ('1 ile 4 arası eşit olasılıklı. Beklenen değer × 2 = ?', 5),
  ('Para atılır. Yazı gelirse 4 puan, tura 2 puan. Beklenen puan = ?', 3),
  ('Zar atılır. Çift gelirse 6 puan, tek gelirse 2 puan. Beklenen puan = ?', 4),
];

const _grandmasterPool = [
  ('10! içindeki 2 çarpanlarının sayısı = ?', 8),
  ('100! içindeki 5 çarpanlarının sayısı = ?', 24),
  ('12 elemanlı kümede 3 elemanlı alt küme sayısı = ?', 220),
  ('C(10,3) + C(10,4) = ?', 330),
  ('P(5,3) - C(5,3) = ?', 50),
  ('EBOB(48, 36) × EKOK(4, 6) = ?', 144),
  ('(x+3)(x-3) x=17 için = ?', 280),
  ('f(x) = x²-1; f(f(3)) = ?', 63),
  ('log₂(32) + log₃(27) = ?', 8),
  ('2^10 - 2^9 = ?', 512),
];

// ── 60-Level dispatcher ───────────────────────────────────────────────────────

Question _pick(Random r, int level) {
  switch (level) {
    // ── D1: İki basamaklı aritmetik ───────────────────────────────────────
    case 1: return r.nextInt(3) == 0 ? _missingAdd(r, 20, 70, 10, 50) : _add(r, 15, 75, 10, 60);
    case 2: return r.nextInt(3) == 0 ? _arithSeq(r, 5, 30, 2, 8) : _sub(r, 30, 90, 10, 50);
    case 3: return r.nextInt(3) == 0 ? _missingAdd(r, 100, 700, 50, 400) : _add(r, 100, 800, 100, 700);
    case 4: return r.nextInt(3) == 0 ? _missingSub(r, 300, 900, 100, 500) : _sub(r, 300, 900, 100, 500);
    case 5: {
      final t = r.nextInt(4);
      if (t == 0) return _missingMul(r, 11, 25, 2, 9);
      if (t == 1) return _missingDiv(r, 2, 9, 10, 30);
      return _mul(r, 11, 35, 2, 9);
    }
    case 6: {
      final t = r.nextInt(4);
      if (t == 0) return _geoSeq(r, 2, 6, 2);
      if (t == 1) return _missingMul(r, 12, 25, 10, 25);
      return _mul(r, 20, 60, 10, 25);
    }
    case 7: {
      final t = r.nextInt(3);
      if (t == 0) return _missingDiv(r, 4, 25, 10, 60);
      return _div(r, 4, 25, 10, 60);
    }
    case 8: return r.nextInt(2) == 0 ? _orderOps(r) : _orderOpsParen(r);
    case 9: return r.nextInt(2) == 0 ? _estimate100(r) : _estimate10(r);
    case 10: {
      final t = r.nextInt(5);
      if (t == 0) return _add(r, 100, 800, 100, 700);
      if (t == 1) return _mul(r, 20, 75, 10, 25);
      if (t == 2) return _div(r, 4, 25, 20, 80);
      if (t == 3) return _orderOpsParen(r);
      return _arithSeq(r, 5, 50, 5, 20);
    }

    // ── D2: Lise seviyesi ────────────────────────────────────────────────
    case 11: return r.nextInt(3) == 0 ? _percentOf(r) : _percentReverse(r);
    case 12: return r.nextInt(2) == 0 ? _percentIncrease(r) : _percentOf(r);
    case 13: return r.nextInt(2) == 0 ? _ratio(r) : _inverseProp(r);
    case 14: return r.nextInt(2) == 0 ? _missingMul(r, 10, 99, 10, 99) : _missingDiv(r, 10, 50, 10, 60);
    case 15: return r.nextInt(2) == 0 ? _linearEq(r, 2, 12, 3, 20, 50) : _linearEqParen(r, 3, 20, 5, 20, 2, 8);
    case 16: return r.nextInt(2) == 0 ? _modQ(r, 50, 999, 3, 17) : _missingMod(r);
    case 17: return r.nextInt(3) == 0 ? _powerMissExp(r) : (r.nextInt(2) == 0 ? _square(r, 11, 20) : _sqrt(r));
    case 18: return r.nextInt(2) == 0 ? _negMul(r) : _negSubEq(r);
    case 19: {
      final t = r.nextInt(4);
      if (t == 0) return _linearEq(r, 2, 12, 5, 25, 80);
      if (t == 1) return _percentReverse(r);
      if (t == 2) return _ratio(r);
      return _modQ(r, 100, 999, 5, 15);
    }
    case 20: {
      final t = r.nextInt(5);
      if (t == 0) return _linearEqParen(r, 5, 30, 5, 25, 3, 8);
      if (t == 1) return _negLinear(r);
      if (t == 2) return _percentReverse(r);
      if (t == 3) return _missingMul(r, 20, 99, 10, 50);
      return _power2(r, 4, 8);
    }

    // ── D3: Lise üstü / TYT-AYT ─────────────────────────────────────────
    case 21: return r.nextInt(2) == 0 ? _orderOpsParen(r) : _orderOpsComplex(r);
    case 22: return r.nextInt(2) == 0 ? _diffSeq(r) : _doubleAddSeq(r);
    case 23: {
      // x² - y² = (x+y)(x-y)
      final x = _r(r, 15, 30);
      final y = _r(r, 5, min(x - 2, 20));
      return _q('x=$x, y=$y için x²-y² = ?', x * x - y * y);
    }
    case 24: return r.nextInt(2) == 0 ? _sqrt(r) : _powerMissExp(r);
    case 25: return r.nextInt(2) == 0 ? _combWord(r) : _comb(r, 5, 10, 2, 4);
    case 26: return r.nextInt(2) == 0 ? _diceSum(r) : _coinFlips(r);
    case 27: return _fromPool(r, _logicPool);
    case 28: return _fromPool(r, _modArithPool);
    case 29: return r.nextInt(2) == 0 ? _diffSeq(r) : _diceSum(r);
    case 30: {
      final t = r.nextInt(5);
      if (t == 0) return _orderOpsComplex(r);
      if (t == 1) return _diffSeq(r);
      if (t == 2) return _combWord(r);
      if (t == 3) return _diceSum(r);
      return _fromPool(r, _logicPool);
    }

    // ── D4: Üniversite başlangıcı ────────────────────────────────────────
    case 31: return r.nextInt(2) == 0 ? _funcEval(r) : _funcEvalLinear(r);
    case 32: return r.nextInt(2) == 0 ? _logQ(r) : _logExp(r);
    case 33: return _matrixDet(r);
    case 34: return r.nextInt(2) == 0 ? _comb(r, 6, 12, 2, 5) : _perm(r, 5, 10, 2, 4);
    case 35: return r.nextInt(2) == 0 ? _diceSum(r) : _coinFlips(r);
    case 36: return r.nextInt(3) == 0 ? _divisorCount(r) : (r.nextInt(2) == 0 ? _gcdQ(r) : _lcmQ(r));
    case 37: return r.nextInt(2) == 0 ? _doubleAddSeq(r) : _fibLike(r);
    case 38: return _maxProduct(r, 8, 20);
    case 39: {
      final t = r.nextInt(5);
      if (t == 0) return _funcEval(r);
      if (t == 1) return _logQ(r);
      if (t == 2) return _comb(r, 6, 10, 2, 4);
      if (t == 3) return _divisorCount(r);
      return _maxProduct(r, 8, 18);
    }
    case 40: {
      final t = r.nextInt(5);
      if (t == 0) return _matrixDet(r);
      if (t == 1) return _funcCompose(r);
      if (t == 2) return _gcdQ(r);
      if (t == 3) return _comb(r, 8, 12, 3, 5);
      return _logExp(r);
    }

    // ── D5: Üniversite ileri ─────────────────────────────────────────────
    case 41: return r.nextInt(2) == 0 ? _missingMod(r) : _modQ(r, 1000, 9999, 7, 23);
    case 42: return r.nextInt(2) == 0 ? _restrictedPerm(r) : _combWord(r);
    case 43: return _fromPool(r, _expectedValuePool);
    case 44: return _maxProduct(r, 10, 25);
    case 45: return r.nextInt(2) == 0 ? _fibLike(r) : _diffSeq(r);
    case 46: return _graphEdges(r, 5, 10);
    case 47: return _fromPool(r, _logicPool);
    case 48: return _coinFlips(r);
    case 49: return r.nextInt(2) == 0 ? _fromPool(r, _workRatePoolFixed) : _fromPool(r, _expectedValuePool);
    case 50: return r.nextInt(2) == 0 ? _derangement(r) : _restrictedPerm(r);

    // ── D6: Akademisyen / Master ─────────────────────────────────────────
    case 51: return r.nextInt(2) == 0 ? _bigMul(r) : _bigDiv(r);
    case 52: return _crt(r);
    case 53: return r.nextInt(2) == 0 ? _starsAndBars(r) : _comb(r, 8, 14, 3, 6);
    case 54: return _fromPool(r, _expectedValuePool);
    case 55: return r.nextInt(2) == 0 ? _funcCompose(r) : _funcEval(r);
    case 56: return r.nextInt(2) == 0 ? _phiQ(r) : _divisorCount(r);
    case 57: return _fromPool(r, _logicPool);
    case 58: return r.nextInt(2) == 0 ? _diffSeq(r) : _doubleAddSeq(r);
    case 59: return r.nextInt(2) == 0 ? _crt(r) : _fromPool(r, _grandmasterPool);
    case 60: return _fromPool(r, _grandmasterPool);

    default: return _add(r, 10, 99, 10, 99);
  }
}
