import 'dart:math';
import 'package:flutter/material.dart';
import '../services/ad_service.dart';

const int _totalQuestions = 20;

class CarpimTablosuScreen extends StatefulWidget {
  const CarpimTablosuScreen({super.key});
  @override
  State<CarpimTablosuScreen> createState() => _CarpimTablosuScreenState();
}

class _CarpimTablosuScreenState extends State<CarpimTablosuScreen>
    with TickerProviderStateMixin {
  final _rng = Random();
  late List<(int, int)> _questionPairs; // sequence of 20 pairs
  int _index = 0;
  int _score = 0;
  int? _selectedChoice;
  bool _answered = false;
  bool _done = false;

  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackScale;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _feedbackScale = Tween(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _feedbackCtrl, curve: Curves.easeOut),
    );
    _buildQuestions();
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _buildQuestions() {
    // All pairs 1-9 × 1-9 (81 total)
    final allPairs = <(int, int)>[];
    for (int a = 1; a <= 9; a++) {
      for (int b = 1; b <= 9; b++) {
        allPairs.add((a, b));
      }
    }

    // Pick 20 pairs with no-consecutive-commuted constraint
    allPairs.shuffle(_rng);
    final selected = <(int, int)>[];
    for (final pair in allPairs) {
      if (selected.length >= _totalQuestions) break;
      if (selected.isNotEmpty) {
        final last = selected.last;
        // Skip if same or commuted
        if ((pair.$1 == last.$1 && pair.$2 == last.$2) ||
            (pair.$1 == last.$2 && pair.$2 == last.$1)) continue;
      }
      selected.add(pair);
    }

    // If we couldn't fill 20 (unlikely), re-add remaining pairs allowing some commuted
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
    });
  }

  (int, int) get _current => _questionPairs[_index];
  int get _correctAnswer => _current.$1 * _current.$2;

  List<int> _generateChoices() {
    final correct = _correctAnswer;
    final choices = <int>{correct};
    while (choices.length < 4) {
      final offset = _rng.nextInt(5) + 1;
      final wrong = correct + (_rng.nextBool() ? offset : -offset);
      if (wrong > 0 && wrong != correct) choices.add(wrong);
    }
    final list = choices.toList()..shuffle(_rng);
    return list;
  }

  void _selectChoice(int choice) {
    if (_answered) return;
    final isCorrect = choice == _correctAnswer;
    setState(() {
      _answered = true;
      _selectedChoice = choice;
      if (isCorrect) _score++;
    });
    _feedbackCtrl.forward(from: 0);
    if (!isCorrect) AdService.onWrongAnswer();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_index + 1 >= _totalQuestions) {
        setState(() { _done = true; });
        if (_score == _totalQuestions) {
          _showPerfectDialog();
        }
      } else {
        setState(() {
          _index++;
          _answered = false;
          _selectedChoice = null;
        });
        _feedbackCtrl.reset();
      }
    });
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
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ÇARPIM TABLOSU SORULARI\nTAMAMLANDI, 1 YILDIZ ALDIN!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7C5CBF),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(true); // return true = star earned
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text('Harika!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bg2.png', fit: BoxFit.cover),
          SafeArea(
            child: _done && _score < _totalQuestions
                ? _buildFailScreen()
                : _done
                    ? const SizedBox.shrink()
                    : _buildQuizScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    final pair = _current;
    final choices = _generateChoices();

    return Column(
      children: [
        const SizedBox(height: 12),
        // Progress + score
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF7C5CBF), size: 18),
                ),
              ),
              Text(
                '${_index + 1} / $_totalQuestions',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF56C068),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('✓ $_score', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ),

        const Spacer(flex: 2),

        // Question card
        AnimatedBuilder(
          animation: _feedbackScale,
          builder: (_, __) => Transform.scale(
            scale: _answered ? _feedbackScale.value : 1.0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))],
              ),
              child: Column(
                children: [
                  Text(
                    '${pair.$1} × ${pair.$2} = ?',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF7C5CBF)),
                  ),
                  if (_answered)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _selectedChoice == _correctAnswer ? '✓  $_correctAnswer' : '✗  $_correctAnswer',
                        style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: _selectedChoice == _correctAnswer ? const Color(0xFF56C068) : const Color(0xFFFF5A5A),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const Spacer(flex: 2),

        // 2×2 choices
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: choices.map((c) => _choiceBtn(c)).toList(),
          ),
        ),

        const Spacer(flex: 1),
      ],
    );
  }

  Widget _choiceBtn(int value) {
    final isCorrect = value == _correctAnswer;
    Color bg = const Color(0xFF7C5CBF);
    if (_answered) {
      if (value == _selectedChoice) {
        bg = isCorrect ? const Color(0xFF56C068) : const Color(0xFFFF5A5A);
      } else if (isCorrect) {
        bg = const Color(0xFF56C068);
      } else {
        bg = const Color(0xFFD4C5E2);
      }
    }
    return GestureDetector(
      onTap: () => _selectChoice(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Text(
            '$value',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFailScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('😅', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(
          '$_score / $_totalQuestions',
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white,
              shadows: [Shadow(color: Colors.black45, blurRadius: 6)]),
        ),
        const SizedBox(height: 8),
        const Text('20/20 için tekrar dene!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white70)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _buildQuestions,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFFFF6B9D), borderRadius: BorderRadius.circular(28)),
            child: const Text('Tekrar Dene', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFFD4C5E2), borderRadius: BorderRadius.circular(28)),
            child: const Text('Geri Dön', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
