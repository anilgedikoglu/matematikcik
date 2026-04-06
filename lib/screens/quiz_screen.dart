import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/level_questions.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';

// ── Renkler ────────────────────────────────────────────────────────────────
class _C {
  static const purple      = Color(0xFF7C5CBF);
  static const purpleLight = Color(0xFFD4C5E2);
  static const pink        = Color(0xFFFF6B9D);
  static const green       = Color(0xFF56C068);
  static const red         = Color(0xFFFF5A5A);
  static const orange      = Color(0xFFFF9A3C);
  static const violet      = Color(0xFF9B6FE0);

  static const List<Color> keys = [
    Color(0xFF4BBEF5), // 0
    Color(0xFFFF6B9D), // 1
    Color(0xFFFFD93D), // 2
    Color(0xFFE05252), // 3
    Color(0xFFFF9A3C), // 4
    Color(0xFF9B6FE0), // 5
    Color(0xFF3EC9C0), // 6
    Color(0xFFFF5A5A), // 7
    Color(0xFF4BBEF5), // 8
    Color(0xFFFF6B9D), // 9
  ];
}

// ── Feedback enum ──────────────────────────────────────────────────────────
enum _FB { none, correct, wrong }

class QuizScreen extends StatefulWidget {
  final int level;
  final GameState state;
  const QuizScreen({super.key, required this.level, required this.state});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final _rng = Random();
  late List<Question> _questions;
  int  _index  = 0;
  int  _score  = 0;
  String _input = '';
  _FB  _fb     = _FB.none;
  bool _levelDone = false;
  bool _gameOver  = false;
  bool _timeUpGameOver = false; // true → süre bitti, false → yanlış cevap

  static const int _timerSec = 30;

  late AnimationController _fbCtrl, _shakeCtrl, _cardCtrl, _timerCtrl;
  late Animation<double>   _fbScale, _shakeAnim, _cardFade, _timerAnim;

  @override
  void initState() {
    super.initState();
    _questions = generateLevel(widget.level, _rng);
    AudioService.playGameMusic(); // bölüm başında random müzik seç

    _fbCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _fbScale = CurvedAnimation(parent: _fbCtrl, curve: Curves.elasticOut);

    _shakeCtrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0,  end: 8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0,   end: 0.0),  weight: 1),
    ]).animate(_shakeCtrl);

    _cardCtrl = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn);
    _cardCtrl.value = 1.0;

    _timerCtrl = AnimationController(
        duration: const Duration(seconds: _timerSec), vsync: this);
    _timerAnim = Tween<double>(begin: 1.0, end: 0.0).animate(_timerCtrl);
    _timerCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _onTimeUp();
    });
    _timerCtrl.forward();
  }

  @override
  void dispose() {
    _fbCtrl.dispose(); _shakeCtrl.dispose();
    _cardCtrl.dispose(); _timerCtrl.dispose();
    super.dispose();
  }

  Question get _current => _questions[_index];

  // ── Zaman doldu ────────────────────────────────────────────────────────
  void _onTimeUp() {
    if (_fb != _FB.none || _levelDone) return;
    _timeUpGameOver = true;
    _advanceAfterFeedback(correct: false);
  }

  void _onKey(String key) {
    if (_fb != _FB.none) return;
    if (key == 'backspace') {
      if (_input.isNotEmpty) setState(() => _input = _input.substring(0, _input.length - 1));
    } else if (key == 'check') {
      _submit();
    } else if (_input.length < 3) {
      setState(() => _input += key);
    }
  }

  Future<void> _submit() async {
    if (_input.isEmpty) return;
    final val = int.tryParse(_input);
    if (val == null) return;
    _timerCtrl.stop();
    final ok = val == _current.answer;
    await _advanceAfterFeedback(correct: ok);
  }

  Future<void> _advanceAfterFeedback({required bool correct}) async {
    setState(() => _fb = correct ? _FB.correct : _FB.wrong);
    _fbCtrl.forward(from: 0);
    if (correct) {
      AudioService.playCorrect(); // tik sesi
    } else {
      _shakeCtrl.forward(from: 0);
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (!correct) {
      // Tek hata → oyun bitti
      await AudioService.playGameOver(); // müzik durur, oyunbitti.wav çalar
      setState(() { _fb = _FB.none; _gameOver = true; });
      return;
    }

    _score++;
    await _cardCtrl.reverse();

    if (_index + 1 >= questionsPerLevel) {
      // Bölüm bitti
      setState(() { _fb = _FB.none; _levelDone = true; });
      await AudioService.playWin();
    } else {
      setState(() {
        _fb = _FB.none;
        _input = '';
        _index++;
      });
      _cardCtrl.forward(from: 0);
      _timerCtrl.forward(from: 0);
      AudioService.playTransition();
    }
  }

  void _finishLevel() {
    Navigator.of(context).pop(_score); // score'u MapScreen'e gönder
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [Color(0xFFFFF0F5), Color(0xFFEDF4FF), Color(0xFFFFF8E7)],
          ),
        ),
        child: SafeArea(
          child: _gameOver
              ? _buildGameOver()
              : _levelDone
                  ? _buildLevelComplete()
                  : _buildQuiz(),
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            _buildHeader(),
            const Spacer(),
            FadeTransition(opacity: _cardFade, child: _buildQuestionCard()),
            const Spacer(),
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) =>
                  Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
              child: FadeTransition(opacity: _cardFade, child: _buildAnswerBox()),
            ),
            const Spacer(),
            _buildNumpad(),
            const SizedBox(height: 20),
          ],
        ),
        if (_fb != _FB.none)
          ScaleTransition(scale: _fbScale, child: _buildFeedbackBadge()),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // Üst satır: geri | Bölüm X (orta) | ⭐ skor
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                      color: _C.purple.withValues(alpha: 0.15), blurRadius: 6)],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _C.purple, size: 18),
                ),
              ),
              const Spacer(),
              Text('Bölüm ${widget.level}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: _C.purple)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.pink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Text('⭐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text('$_score',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: _C.pink)),
                  Text('/$questionsPerLevel',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: _C.purple)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Alt satır: ilerlemeli tavşan barı | sayaç
          Row(
            children: [
              Expanded(child: _buildProgressBar()),
              const SizedBox(width: 10),
              _buildTimerCircle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LayoutBuilder(
      builder: (_, constraints) {
        final progress = (_index + 1) / questionsPerLevel;
        final barW = constraints.maxWidth;
        final fillW = (barW * progress).clamp(0.0, barW);

        return SizedBox(
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Arka plan bar
              Positioned(
                left: 0, right: 0, top: 10, bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: _C.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Dolu kısım
              Positioned(
                left: 0, width: fillW.clamp(8.0, barW), top: 10, bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_C.pink, _C.violet]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Tavşan — dolu kısmın ucunda
              Positioned(
                left: (fillW - 14).clamp(0.0, barW - 20),
                top: -4,
                child: const Text('🐰',
                    style: TextStyle(fontSize: 22)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerCircle() {
    return AnimatedBuilder(
      animation: _timerAnim,
      builder: (_, __) {
        final p = _timerAnim.value;
        final sec = (p * _timerSec).ceil();
        final Color color;
        if (p > 0.5) {
          color = Color.lerp(const Color(0xFFFFD93D), _C.green, (p - 0.5) * 2)!;
        } else {
          color = Color.lerp(_C.red, const Color(0xFFFFD93D), p * 2)!;
        }
        return SizedBox(
          width: 52, height: 52,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(52, 52),
              painter: _TimerPainter(progress: p, color: color),
            ),
            Text('$sec',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ]),
        );
      },
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: _C.pink.withValues(alpha: 0.18),
              blurRadius: 24, offset: const Offset(0, 10))
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(_current.display,
            maxLines: 1,
            style: const TextStyle(
                fontSize: 52, fontWeight: FontWeight.w900,
                color: _C.purple, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildAnswerBox() {
    final Color border;
    if (_fb == _FB.correct) border = _C.green;
    else if (_fb == _FB.wrong) border = _C.red;
    else border = _C.purpleLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 160, height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 3),
        boxShadow: [BoxShadow(
            color: _C.purple.withValues(alpha: 0.08),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: Text(
          _input.isEmpty ? '—' : _input,
          style: TextStyle(
              fontSize: 42, fontWeight: FontWeight.bold,
              color: _input.isEmpty ? _C.purpleLight : _C.purple),
        ),
      ),
    );
  }

  Widget _buildFeedbackBadge() {
    final ok = _fb == _FB.correct;
    final c = ok ? _C.green : _C.red;
    return Container(
      width: 110, height: 110,
      decoration: BoxDecoration(
        color: c, shape: BoxShape.circle,
        boxShadow: [BoxShadow(
            color: c.withValues(alpha: 0.45), blurRadius: 24, spreadRadius: 4)],
      ),
      child: Icon(ok ? Icons.check_rounded : Icons.close_rounded,
          color: Colors.white, size: 68),
    );
  }

  // ── Numpad ───────────────────────────────────────────────────────────

  static const _rows = [
    ['7','8','9'], ['4','5','6'], ['1','2','3'], ['backspace','0','check'],
  ];

  Widget _buildNumpad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _rows.map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map(_buildKey).toList(),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    final isCheck = key == 'check';
    final isBack  = key == 'backspace';
    final disabled = _fb != _FB.none;

    final Color bg;
    final Widget child;

    if (isCheck) {
      bg = _C.green;
      child = const Icon(Icons.check_rounded, color: Colors.white, size: 34);
    } else if (isBack) {
      bg = _C.orange;
      child = const Icon(Icons.backspace_rounded, color: Colors.white, size: 28);
    } else {
      bg = _C.keys[int.parse(key)];
      child = Text(key,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold,
              color: Colors.white));
    }

    return GestureDetector(
      onTap: disabled ? null : () => _onKey(key),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          width: 90, height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: bg.withValues(alpha: 0.38),
                blurRadius: 8, offset: const Offset(0, 5))],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  // ── Level tamamlandı ─────────────────────────────────────────────────

  // ── Oyun bitti (hata yapıldı) ────────────────────────────────────────────

  Widget _buildGameOver() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_timeUpGameOver ? '⏳' : '😞', style: const TextStyle(fontSize: 90)),
            const SizedBox(height: 20),
            const Text(
              'Oyun Bitti!',
              style: TextStyle(
                  fontSize: 38, fontWeight: FontWeight.w900, color: _C.red),
            ),
            const SizedBox(height: 12),
            Text(
              'Bölüm ${widget.level}',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600, color: _C.purple),
            ),
            const SizedBox(height: 8),
            Text(
              '$_score doğru cevap verdin',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w500, color: _C.pink),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF5A5A), Color(0xFFFF9A3C)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: _C.red.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Text(
                  'Tekrar Dene 🔄',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelComplete() {
    final pct = (_score / questionsPerLevel * 100).round();
    final emoji = pct >= 90 ? '🏆' : pct >= 70 ? '⭐' : '💪';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text('Bölüm ${widget.level} Bitti!',
                style: const TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w900, color: _C.purple)),
            const SizedBox(height: 12),
            Text('$_score / $questionsPerLevel doğru',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700, color: _C.pink)),
            const SizedBox(height: 4),
            Text('%$pct başarı',
                style: const TextStyle(
                    fontSize: 20, color: _C.purple, fontWeight: FontWeight.w500)),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _finishLevel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_C.pink, _C.violet]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(
                      color: _C.pink.withValues(alpha: 0.4),
                      blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Text(
                  widget.level < 10 ? 'Haritaya Dön 🗺️' : 'Oyunu Bitir 🎉',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timer Painter ─────────────────────────────────────────────────────────

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  static const double _stroke = 5.0;

  const _TimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - _stroke / 2;

    canvas.drawCircle(center, radius,
        Paint()
          ..color = const Color(0x22000000)
          ..strokeWidth = _stroke
          ..style = PaintingStyle.stroke);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2,
        2 * 3.14159 * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = _stroke
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.color != color;
}
