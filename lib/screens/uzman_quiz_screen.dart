import 'dart:math';
import 'package:flutter/material.dart';
import '../models/uzman_level_questions.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../services/ad_service.dart';

enum _FB { none, correct, wrong }

const int _uzmanTimerSec = 60;

class UzmanQuizScreen extends StatefulWidget {
  final int level;
  final String bgAsset;
  const UzmanQuizScreen({super.key, required this.level, required this.bgAsset});
  @override
  State<UzmanQuizScreen> createState() => _UzmanQuizScreenState();
}

class _UzmanQuizScreenState extends State<UzmanQuizScreen> with TickerProviderStateMixin {
  final _rng = Random();
  late List<Question> _questions;
  int _index = 0;
  int _score = 0;
  int _lives = 3;
  int _durusIndex = 1;
  int _childIndex = 1;
  String _input = '';
  _FB _fb = _FB.none;
  bool _levelDone = false;
  bool _gameOver = false;

  late AnimationController _fbCtrl, _shakeCtrl, _cardCtrl, _timerCtrl;
  late Animation<double> _fbScale, _shakeAnim, _cardFade, _timerAnim;

  @override
  void initState() {
    super.initState();
    _questions = generateUzmanLevel(widget.level, _rng);
    _childIndex = _rng.nextInt(4) + 1;

    _fbCtrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fbScale = CurvedAnimation(parent: _fbCtrl, curve: Curves.elasticOut);

    _shakeCtrl = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0,  end: 8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0,   end: 0.0),  weight: 1),
    ]).animate(_shakeCtrl);

    _cardCtrl = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn);
    _cardCtrl.value = 1.0;

    _timerCtrl = AnimationController(
        duration: const Duration(seconds: _uzmanTimerSec), vsync: this);
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
  bool get _passed => _score >= uzmanPassThreshold;

  void _onKey(String key) {
    if (_fb != _FB.none || _levelDone || _gameOver) return;
    setState(() {
      if (key == '⌫') {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
      } else if (key == '-') {
        _input = _input.isEmpty ? '-' : (_input == '-' ? '' : _input);
      } else if (_input.length < 8) {
        _input += key;
      }
    });
  }

  Future<void> _onSubmit() async {
    if (_fb != _FB.none || _levelDone || _gameOver) return;
    final val = int.tryParse(_input);
    if (val == null) return;
    _timerCtrl.stop();
    await _advanceAfterFeedback(correct: val == _current.answer);
  }

  void _onTimeUp() {
    if (_fb != _FB.none || _levelDone || _gameOver) return;
    _advanceAfterFeedback(correct: false);
  }

  Future<void> _advanceAfterFeedback({required bool correct}) async {
    _childIndex = _rng.nextInt(4) + 1;
    setState(() => _fb = correct ? _FB.correct : _FB.wrong);
    _fbCtrl.forward(from: 0);

    if (correct) {
      AudioService.playCorrect();
    } else {
      _shakeCtrl.forward(from: 0);
      setState(() => _lives--);
    }

    await Future.delayed(Duration(milliseconds: correct ? 900 : 1500));
    if (!mounted) return;

    if (!correct) {
      await AdService.onWrongAnswer();
      if (!mounted) return;
      if (_lives <= 0) {
        _durusIndex = _rng.nextInt(4) + 1;
        setState(() { _fb = _FB.none; _gameOver = true; });
        AudioService.playGameOver();
        return;
      }
    } else {
      _score++;
    }

    if (_index + 1 >= _questions.length) {
      setState(() { _fb = _FB.none; _levelDone = true; });
      AudioService.playWin();
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return Scaffold(body: _buildGameOver());
    if (_levelDone) return Scaffold(body: _buildLevelComplete());

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
        child: SafeArea(child: _buildQuiz()),
      ),
    );
  }

  Widget _buildQuiz() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(_shakeAnim.value, 0),
                        child: child,
                      ),
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: _buildQuestionCard(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildAnswerBox(),
                  ],
                ),
              ),
            ),
            _buildKeypad(),
            const SizedBox(height: 12),
          ],
        ),
        if (_fb != _FB.none)
          Center(
            child: ScaleTransition(scale: _fbScale, child: _buildFeedbackBadge()),
          ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(null),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF7C5CBF), size: 18),
                ),
              ),
              const Spacer(),
              Text(
                'Bölüm ${widget.level}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    color: Color(0xFF7C5CBF)),
              ),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildProgressBar()),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Text('⭐', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 3),
                  Text('$_score',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFF6B9D))),
                  Text('/${_questions.length}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7C5CBF))),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHearts(),
              const SizedBox(width: 12),
              _buildTimerCircle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LayoutBuilder(builder: (_, constraints) {
      final progress = (_index + 1) / _questions.length;
      final barW = constraints.maxWidth;
      final fillW = (barW * progress).clamp(0.0, barW);

      return SizedBox(
        height: 30,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: 0, right: 0, top: 10, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CBF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            left: 0, width: fillW.clamp(8.0, barW), top: 10, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFF9B6FE0)]),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            left: (fillW - 14).clamp(0.0, barW - 20),
            top: -4,
            child: const Text('🐰', style: TextStyle(fontSize: 22)),
          ),
        ]),
      );
    });
  }

  Widget _buildHearts() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final alive = i < _lives;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: alive
              ? const Text('❤️', style: TextStyle(fontSize: 21))
              : Image.asset('assets/kirikkalp.png',
                  width: 18, height: 18, fit: BoxFit.contain),
        );
      }),
    );
  }

  Widget _buildTimerCircle() {
    return AnimatedBuilder(
      animation: _timerAnim,
      builder: (_, __) {
        final p = _timerAnim.value;
        final sec = (p * _uzmanTimerSec).ceil();
        final Color color;
        if (p > 0.5) {
          color = Color.lerp(
              const Color(0xFFFFD93D), const Color(0xFF56C068), (p - 0.5) * 2)!;
        } else {
          color = Color.lerp(
              const Color(0xFFFF5A5A), const Color(0xFFFFD93D), p * 2)!;
        }
        return SizedBox(
          width: 42, height: 42,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(42, 42),
              painter: _TimerPainter(progress: p, color: color),
            ),
            Text('$sec',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ]),
        );
      },
    );
  }

  // ── Question card ─────────────────────────────────────────────────────────

  Widget _buildQuestionCard() {
    final isWrong = _fb == _FB.wrong;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: isWrong
            ? const Color(0xFFFF5A5A).withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: isWrong ? Border.all(color: const Color(0xFFFF5A5A), width: 2) : null,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _current.display,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF7C5CBF)),
        ),
      ),
    );
  }

  Widget _buildAnswerBox() {
    final Color border;
    if (_fb == _FB.correct) border = const Color(0xFF56C068);
    else if (_fb == _FB.wrong) border = const Color(0xFFFF5A5A);
    else border = const Color(0xFFD4C5E2);

    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 3),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7C5CBF).withValues(alpha: 0.08),
              blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _input.isEmpty ? '—' : _input,
            style: TextStyle(
                fontSize: _input.length >= 5 ? 26 : 36,
                fontWeight: FontWeight.bold,
                color: _input.isEmpty
                    ? const Color(0xFFD4C5E2)
                    : const Color(0xFF7C5CBF)),
          ),
          if (_fb == _FB.wrong)
            Text('Doğru: ${_current.answer}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF5A5A),
                    fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildFeedbackBadge() {
    if (_fb == _FB.wrong) {
      return Image.asset('assets/kirikkalp.png',
          width: 200, height: 200, fit: BoxFit.contain);
    }
    return Image.asset('assets/cocukgood$_childIndex.png',
        width: 192, height: 192, fit: BoxFit.contain);
  }

  // ── Keypad ────────────────────────────────────────────────────────────────

  Widget _buildKeypad() {
    final keys = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['-', '0', '⌫'],
    ];
    const colors = [
      Color(0xFF4BBEF5), Color(0xFFFF6B9D), Color(0xFFFFD93D),
      Color(0xFFE05252), Color(0xFFFF9A3C), Color(0xFF9B6FE0),
      Color(0xFF3EC9C0), Color(0xFFFF5A5A), Color(0xFF4BBEF5),
      Color(0xFF7C5CBF), Color(0xFFFF6B9D), Color(0xFF56C068),
    ];
    final disabled = _fb != _FB.none;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          ...keys.asMap().entries.map((rowEntry) {
            final rowIdx = rowEntry.key;
            final row = rowEntry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: row.asMap().entries.map((colEntry) {
                  final colIdx = colEntry.key;
                  final k = colEntry.value;
                  final colorIdx = rowIdx * 3 + colIdx;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: colIdx < 2 ? 10 : 0),
                      child: GestureDetector(
                        onTap: disabled ? null : () => _onKey(k),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: disabled ? 0.5 : 1.0,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: colors[colorIdx % colors.length]
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: colors[colorIdx % colors.length]
                                      .withValues(alpha: 0.35),
                                  blurRadius: 6, offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Center(
                              child: k == '⌫'
                                  ? const Icon(Icons.backspace_rounded,
                                      color: Colors.white, size: 22)
                                  : Text(k,
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          GestureDetector(
            onTap: disabled ? null : _onSubmit,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: disabled ? 0.5 : 1.0,
              child: Container(
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF56C068),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF56C068).withValues(alpha: 0.4),
                        blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: const Center(
                  child: Text('TAMAM',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Level complete ────────────────────────────────────────────────────────

  Widget _buildLevelComplete() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(widget.bgAsset, fit: BoxFit.cover),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_passed ? '🏆' : '😅',
                    style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                Text('Bölüm ${widget.level}',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 6)])),
                const SizedBox(height: 4),
                Text(
                  _passed ? 'TAMAMLANDI! 🎉' : 'Tekrar dene! (%80 gerekli)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w900,
                      color: _passed
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFFF6B9D),
                      shadows: const [
                        Shadow(color: Colors.black45, blurRadius: 6)
                      ]),
                ),
                const SizedBox(height: 12),
                Text('$_score / ${_questions.length} doğru',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70)),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pop(_passed ? _score : null),
                  child: Image.asset(
                      _passed ? 'assets/devamet.png' : 'assets/tekrardene.png',
                      height: 140),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Game over ─────────────────────────────────────────────────────────────

  Widget _buildGameOver() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/bg.png', fit: BoxFit.cover),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/durus$_durusIndex.png', height: 200),
                const SizedBox(height: 20),
                Image.asset('assets/oyunbitti.png', height: 120),
                const SizedBox(height: 12),
                Text('Bölüm ${widget.level}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600,
                        color: Color(0xFF7C5CBF))),
                const SizedBox(height: 8),
                Text('$_score doğru cevap verdin',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFF6B9D))),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(null),
                  child: Image.asset('assets/tekrardene.png', height: 140),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Timer Painter ─────────────────────────────────────────────────────────────

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  static const double _stroke = 5.0;

  const _TimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - _stroke / 2;

    canvas.drawCircle(
        center, radius,
        Paint()
          ..color = const Color(0x22000000)
          ..strokeWidth = _stroke
          ..style = PaintingStyle.stroke);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
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
