import 'dart:math';
import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';

const int _totalQuestions = 20;

enum _FB { none, correct, wrong }

class CarpimTablosuScreen extends StatefulWidget {
  const CarpimTablosuScreen({super.key});
  @override
  State<CarpimTablosuScreen> createState() => _CarpimTablosuScreenState();
}

class _CarpimTablosuScreenState extends State<CarpimTablosuScreen>
    with TickerProviderStateMixin {
  final _rng = Random();
  late List<(int, int)> _questionPairs;
  List<int> _choices = [];
  int _index = 0;
  int _score = 0;
  int _lives = 3;
  int _durusIndex = 1;
  int _childIndex = 1;
  _FB _fb = _FB.none;
  bool _done = false;
  bool _gameOver = false;

  late AnimationController _fbCtrl;
  late Animation<double> _fbScale;

  @override
  void initState() {
    super.initState();
    _childIndex = _rng.nextInt(4) + 1;
    _fbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fbScale = CurvedAnimation(parent: _fbCtrl, curve: Curves.elasticOut);
    _buildQuestions();
  }

  @override
  void dispose() {
    _fbCtrl.dispose();
    super.dispose();
  }

  void _buildQuestions() {
    final allPairs = <(int, int)>[];
    for (int a = 1; a <= 9; a++) {
      for (int b = 1; b <= 9; b++) {
        allPairs.add((a, b));
      }
    }
    allPairs.shuffle(_rng);
    final selected = <(int, int)>[];
    for (final pair in allPairs) {
      if (selected.length >= _totalQuestions) break;
      if (selected.isNotEmpty) {
        final last = selected.last;
        if ((pair.$1 == last.$1 && pair.$2 == last.$2) ||
            (pair.$1 == last.$2 && pair.$2 == last.$1)) continue;
      }
      selected.add(pair);
    }
    if (selected.length < _totalQuestions) {
      for (final pair in allPairs) {
        if (selected.length >= _totalQuestions) break;
        if (!selected.contains(pair)) selected.add(pair);
      }
    }
    setState(() {
      _questionPairs = selected;
      _index = 0;
      _score = 0;
      _lives = 3;
      _fb = _FB.none;
      _done = false;
      _gameOver = false;
    });
    _generateChoices();
  }

  (int, int) get _current => _questionPairs[_index];
  int get _correctAnswer => _current.$1 * _current.$2;

  void _generateChoices() {
    final correct = _correctAnswer;
    final choices = <int>{correct};
    while (choices.length < 4) {
      final offset = _rng.nextInt(5) + 1;
      final wrong = correct + (_rng.nextBool() ? offset : -offset);
      if (wrong > 0 && wrong != correct) choices.add(wrong);
    }
    _choices = choices.toList()..shuffle(_rng);
  }

  Future<void> _selectChoice(int choice) async {
    if (_fb != _FB.none || _gameOver || _done) return;
    final isCorrect = choice == _correctAnswer;
    _childIndex = _rng.nextInt(4) + 1;

    setState(() {
      _fb = isCorrect ? _FB.correct : _FB.wrong;
      if (isCorrect) _score++;
      else _lives--;
    });
    _fbCtrl.forward(from: 0);

    if (isCorrect) {
      AudioService.playCorrect();
    }

    // Önce geri bildirim (yeşil/kırmızı + pop-up) görünsün, sonra ilerle
    await Future.delayed(Duration(milliseconds: isCorrect ? 900 : 1500));
    if (!mounted) return;

    if (!isCorrect) {
      // Her 3 yanlışta 1 geçiş reklamı (reklam kapanana kadar bekler)
      await AdService.onWrongAnswer();
      if (!mounted) return;
      if (_lives <= 0) {
        _durusIndex = _rng.nextInt(4) + 1;
        setState(() => _gameOver = true);
        AudioService.playGameOver();
        return;
      }
    }

    if (_index + 1 >= _totalQuestions) {
      setState(() { _fb = _FB.none; _done = true; });
      if (_score == _totalQuestions) {
        AudioService.playWin();
        _showPerfectDialog();
      }
    } else {
      setState(() {
        _index++;
        _fb = _FB.none;
        _generateChoices();
      });
    }
  }

  void _showPerfectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              const Text(
                'HARİKA!',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFFFD700)),
              ),
              const SizedBox(height: 8),
              const Text(
                'ÇARPIM TABLOSU SORULARI\nTAMAMLANDI, 1 YILDIZ ALDIN!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF7C5CBF)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text('Harika!',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_gameOver) {
      return Material(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/bg.png', fit: BoxFit.cover),
            _buildGameOver(),
          ],
        ),
      );
    }
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
          child: _done && _score < _totalQuestions
              ? _buildFailScreen()
              : _buildQuizScreen(),
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            _buildHeader(),
            const Spacer(flex: 2),
            _buildQuestionCard(_current),
            const Spacer(flex: 2),
            _buildChoiceGrid(_choices),
            const Spacer(flex: 1),
          ],
        ),
        if (_fb != _FB.none)
          ScaleTransition(scale: _fbScale, child: _buildFeedbackBadge()),
      ],
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

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
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
              const Text(
                'Çarpım Tablosu',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900,
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
                  color: const Color(0xFF56C068),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('✓ $_score',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LayoutBuilder(builder: (_, constraints) {
      final progress = (_index + 1) / _totalQuestions;
      final barW = constraints.maxWidth;
      final fillW = (barW * progress).clamp(0.0, barW);

      return SizedBox(
        height: 30,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: 0, right: 0, top: 10, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CBF).withValues(alpha: 0.15),
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

  // ── Question card ─────────────────────────────────────────────────────────

  Widget _buildQuestionCard((int, int) pair) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))
        ],
      ),
      child: Text(
        '${pair.$1} × ${pair.$2} = ?',
        style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Color(0xFF7C5CBF)),
      ),
    );
  }

  // ── Choice grid ───────────────────────────────────────────────────────────

  Widget _buildChoiceGrid(List<int> choices) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: choices.map((c) => _choiceBtn(c)).toList(),
      ),
    );
  }

  Widget _choiceBtn(int value) {
    final isCorrectChoice = value == _correctAnswer;
    final disabled = _fb != _FB.none;
    Color bg = const Color(0xFF7C5CBF);
    if (_fb != _FB.none) {
      if (isCorrectChoice) {
        // Doğru ise yeşil, yanlış ise (doğru şıkkı) kırmızı vurgula
        bg = _fb == _FB.correct ? const Color(0xFF56C068) : const Color(0xFFFF5A5A);
      } else {
        bg = const Color(0xFFD4C5E2);
      }
    }
    return GestureDetector(
      // Key: soru değişince eski butonun rengi yeni soruya taşmasın
      key: ValueKey('$_index-$value'),
      onTap: disabled ? null : () => _selectChoice(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: bg.withValues(alpha: 0.4),
                blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Center(
          child: Text(
            '$value',
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ── Fail screen ───────────────────────────────────────────────────────────

  Widget _buildFailScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('😅', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(
          '$_score / $_totalQuestions',
          style: const TextStyle(
              fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF7C5CBF)),
        ),
        const SizedBox(height: 8),
        const Text('20/20 için tekrar dene!',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFF6B9D))),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _buildQuestions,
          child: Image.asset('assets/tekrardene.png', height: 140),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
                color: const Color(0xFFD4C5E2),
                borderRadius: BorderRadius.circular(28)),
            child: const Text('Geri Dön',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ── Game over ─────────────────────────────────────────────────────────────

  Widget _buildGameOver() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/durus$_durusIndex.png', height: 200),
              const SizedBox(height: 20),
              Image.asset('assets/oyunbitti.png', height: 120),
              const SizedBox(height: 12),
              const Text('Çarpım Tablosu',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600,
                      color: Color(0xFF7C5CBF))),
              const SizedBox(height: 8),
              Text('$_score doğru cevap verdin',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500,
                      color: Color(0xFFFF6B9D))),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _buildQuestions,
                child: Image.asset('assets/tekrardene.png', height: 140),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFD4C5E2),
                      borderRadius: BorderRadius.circular(28)),
                  child: const Text('Geri Dön',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
