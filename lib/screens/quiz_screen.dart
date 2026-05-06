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

  // Seçim butonları için canlı renkler
  static const List<Color> choiceBtns = [
    Color(0xFFFF6B9D),
    Color(0xFF4BBEF5),
    Color(0xFFFFD93D),
    Color(0xFF56C068),
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
  late int _childIndex;
  late int _lives;
  int _durusIndex = 1;
  int  _index  = 0;
  int  _score  = 0;
  String _input = '';
  _FB  _fb     = _FB.none;
  bool _levelDone = false;
  bool _gameOver  = false;
  bool _timeUpGameOver = false;

  // Hangi dünyada olduğumuzu belirler (0-5)
  int get _world => (widget.level - 1) ~/ 10;

  // Seçim modu (world 0-2): buton seçenekleri
  List<int> _buttonChoices = [];

  // Karışık keypad (world 5): rakam sırası
  List<String> _shuffledDigits = [];

  static const int _timerSec = 30;

  late AnimationController _fbCtrl, _shakeCtrl, _cardCtrl, _timerCtrl;
  late Animation<double>   _fbScale, _shakeAnim, _cardFade, _timerAnim;

  @override
  void initState() {
    super.initState();
    _questions = generateLevel(widget.level, _rng);
    _childIndex = _rng.nextInt(4) + 1;
    _lives = widget.state.lives;
    AudioService.playGameMusic();

    if (_world <= 2) _generateButtonChoices();
    if (_world == 5) _reshuffleDigits();

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

  // ── Seçim butonu yardımcıları ─────────────────────────────────────────

  void _generateButtonChoices() {
    final correct = _questions[_index].answer;
    final count = [2, 3, 4][_world.clamp(0, 2)];
    final set = <int>{correct};
    var attempts = 0;
    while (set.length < count && attempts++ < 400) {
      final range = (correct.abs() ~/ 3 + 4).clamp(3, 25);
      int w = correct + _rng.nextInt(range * 2 + 1) - range;
      if (w < 0) w = w.abs().clamp(1, 999);
      if (w != correct) set.add(w);
    }
    _buttonChoices = set.toList()..shuffle(_rng);
  }

  void _reshuffleDigits() {
    _shuffledDigits = ['0','1','2','3','4','5','6','7','8','9']..shuffle(_rng);
  }

  // Soru değişince seçenekleri yenile
  void _onQuestionReady() {
    if (_world <= 2) _generateButtonChoices();
    if (_world == 5) _reshuffleDigits();
  }

  // ── Kalpler ───────────────────────────────────────────────────────────

  Widget _buildHearts() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final alive = i < _lives;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: alive
              ? const Text('❤️', style: TextStyle(fontSize: 16))
              : Image.asset('assets/kirikkalp.png', width: 18, height: 18, fit: BoxFit.contain),
        );
      }),
    );
  }

  // ── Zaman doldu ────────────────────────────────────────────────────────
  void _onTimeUp() {
    if (_fb != _FB.none || _levelDone) return;
    _timeUpGameOver = true;
    _advanceAfterFeedback(correct: false);
  }

  // ── Seçim butonu tıklama ──────────────────────────────────────────────
  void _onButtonChoice(int value) {
    if (_fb != _FB.none) return;
    _timerCtrl.stop();
    _advanceAfterFeedback(correct: value == _current.answer);
  }

  // ── Keypad tuşu ────────────────────────────────────────────────────────
  void _onKey(String key) {
    if (_fb != _FB.none) return;
    if (key == 'backspace') {
      if (_input.isNotEmpty) setState(() => _input = _input.substring(0, _input.length - 1));
    } else if (key == 'check') {
      _submit();
    } else if (_input.length < 4) {
      setState(() => _input += key);
      // Dünya 3-4: doğru cevap girilince otomatik gönder
      if (_world == 3 || _world == 4) {
        final val = int.tryParse(_input);
        if (val != null && val == _current.answer) _submit();
      }
    }
  }

  Future<void> _submit() async {
    if (_input.isEmpty) return;
    final val = int.tryParse(_input);
    if (val == null) return;
    _timerCtrl.stop();
    await _advanceAfterFeedback(correct: val == _current.answer);
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
      if (_lives <= 0) {
        await AudioService.playGameOver();
        _durusIndex = _rng.nextInt(4) + 1;
        setState(() { _fb = _FB.none; _gameOver = true; });
      } else {
        setState(() {
          _fb = _FB.none;
          _input = '';
          if (_index + 1 < questionsPerLevel) {
            _index++;
            _onQuestionReady();
          } else {
            _levelDone = true;
          }
        });
        if (!_levelDone) {
          _cardCtrl.forward(from: 0);
          _timerCtrl.forward(from: 0);
          AudioService.playTransition();
        } else {
          await AudioService.playWin();
        }
      }
      return;
    }

    _score++;
    await _cardCtrl.reverse();

    if (_index + 1 >= questionsPerLevel) {
      setState(() { _fb = _FB.none; _levelDone = true; });
      await AudioService.playWin();
    } else {
      setState(() {
        _fb = _FB.none;
        _input = '';
        _index++;
        _onQuestionReady();
      });
      _cardCtrl.forward(from: 0);
      _timerCtrl.forward(from: 0);
      AudioService.playTransition();
    }
  }

  void _finishLevel() {
    Navigator.of(context).pop(_score * 10 + _lives);
  }

  // ── Build ─────────────────────────────────────────────────────────────

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
    final isButtonMode = _world <= 2;
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            _buildHeader(),
            const Spacer(),
            FadeTransition(opacity: _cardFade, child: _buildQuestionCard()),
            const Spacer(),
            if (!isButtonMode) ...[
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) =>
                    Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
                child: FadeTransition(opacity: _cardFade, child: _buildAnswerBox()),
              ),
              const Spacer(),
            ],
            _buildInputArea(),
            if (_world <= 2) const Spacer(),
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
          // Satır 1: geri | Bölüm X (orta)
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
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          // Satır 2: tavşan bar | ⭐ skor
          Row(
            children: [
              Expanded(child: _buildProgressBar()),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.pink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Text('⭐', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 3),
                  Text('$_score',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold,
                          color: _C.pink)),
                  Text('/$questionsPerLevel',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: _C.purple)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Satır 3: kalpler (ortalı) | sayaç
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
              Positioned(
                left: 0, right: 0, top: 10, bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: _C.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned(
                left: 0, width: fillW.clamp(8.0, barW), top: 10, bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_C.pink, _C.violet]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned(
                left: (fillW - 14).clamp(0.0, barW - 20),
                top: -4,
                child: const Text('🐰', style: TextStyle(fontSize: 22)),
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
          width: 38, height: 38,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(38, 38),
              painter: _TimerPainter(progress: p, color: color),
            ),
            Text('$sec',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: color)),
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
              fontSize: _input.length >= 4 ? 32 : 42, fontWeight: FontWeight.bold,
              color: _input.isEmpty ? _C.purpleLight : _C.purple),
        ),
      ),
    );
  }

  Widget _buildFeedbackBadge() {
    final ok = _fb == _FB.correct;
    if (!ok) {
      return Image.asset('assets/kirikkalp.png', width: 200, height: 200, fit: BoxFit.contain);
    }
    return Image.asset('assets/cocukgood$_childIndex.png', width: 192, height: 192, fit: BoxFit.contain);
  }

  // ── Giriş alanı (mod seçici) ──────────────────────────────────────────

  Widget _buildInputArea() {
    if (_world <= 2) return _buildButtonChoices();
    return _buildNumpad();
  }

  // ── Seçim butonları (world 0-2) ───────────────────────────────────────

  Widget _buildButtonChoices() {
    final disabled = _fb != _FB.none;

    Widget choiceBtn(int val, int colorIdx) {
      final color = _C.choiceBtns[colorIdx % _C.choiceBtns.length];
      return Expanded(
        child: GestureDetector(
          onTap: disabled ? null : () => _onButtonChoice(val),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: disabled ? 0.5 : 1.0,
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )],
              ),
              child: Center(
                child: Text(
                  '$val',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final choices = _buttonChoices;
    if (choices.isEmpty) return const SizedBox.shrink();

    // 2 buton: tek büyük satır
    if (choices.length == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              choiceBtn(choices[0], 0),
              choiceBtn(choices[1], 1),
            ],
          ),
        ),
      );
    }

    // 3 buton: tek satır
    if (choices.length == 3) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              choiceBtn(choices[0], 0),
              choiceBtn(choices[1], 1),
              choiceBtn(choices[2], 2),
            ],
          ),
        ),
      );
    }

    // 4 buton: 2×2 grid
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              choiceBtn(choices[0], 0),
              choiceBtn(choices[1], 1),
            ]),
          ),
          SizedBox(
            height: 110,
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              choiceBtn(choices[2], 2),
              choiceBtn(choices[3], 3),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Numpad (world 3-5) ────────────────────────────────────────────────

  List<List<String>> _getNumpadRows() {
    if (_world == 5 && _shuffledDigits.length == 10) {
      final d = _shuffledDigits;
      return [
        [d[0], d[1], d[2]],
        [d[3], d[4], d[5]],
        [d[6], d[7], d[8]],
        ['backspace', d[9], 'check'],
      ];
    }
    return [
      ['7','8','9'], ['4','5','6'], ['1','2','3'], ['backspace','0','check'],
    ];
  }

  Widget _buildNumpad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _getNumpadRows().map((row) => Padding(
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

  Widget _buildLevelComplete() {
    final pct = (_score / questionsPerLevel * 100).round();
    final emoji = pct >= 90 ? '🏆' : pct >= 70 ? '⭐' : '💪';

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
                Text(emoji, style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                Text('Bölüm ${widget.level}',
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w700, color: _C.purple)),
                const SizedBox(height: 4),
                const Text('TAMAMLANDI!',
                    style: TextStyle(
                        fontSize: 38, fontWeight: FontWeight.w900, color: _C.pink)),
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
                  child: Image.asset('assets/devamet.png', height: 160),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Oyun bitti ────────────────────────────────────────────────────────

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
                Image.asset('assets/oyunbitti.png', height: 160),
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
                  onTap: () => Navigator.of(context).pop(-1),
                  child: Image.asset('assets/tekrardene.png', height: 160),
                ),
              ],
            ),
          ),
        ),
      ],
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
