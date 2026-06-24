import 'dart:math';
import 'package:flutter/material.dart';
import '../models/uzman_level_questions.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../services/ad_service.dart';

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
  String _input = '';
  bool _levelDone = false;
  bool _wrong = false;
  int _wrongCount = 0;

  late AnimationController _shakeCtrl, _cardCtrl;
  late Animation<double> _shakeAnim, _cardFade;

  @override
  void initState() {
    super.initState();
    _questions = generateUzmanLevel(widget.level, _rng);

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = Tween(begin: 0.0, end: 1.0).animate(_shakeCtrl);

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn);
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  Question get _current => _questions[_index];

  void _onKey(String key) {
    if (_levelDone || _wrong) return;
    setState(() {
      if (key == '⌫') {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
      } else if (key == '-') {
        if (_input.isEmpty) _input = '-';
        else if (_input == '-') _input = '';
      } else if (_input.length < 8) {
        _input += key;
      }
    });
  }

  Future<void> _onSubmit() async {
    if (_levelDone || _wrong) return;
    final val = int.tryParse(_input);
    if (val == null) return;

    if (val == _current.answer) {
      await AudioService.playCorrect();
      setState(() { _score++; });
      _advance();
    } else {
      setState(() { _wrong = true; });
      _wrongCount++;
      _shakeCtrl.forward(from: 0);

      AdService.onWrongAnswer().then((_) {
        if (!mounted) return;
        _advance();
      });
    }
  }

  void _advance() {
    if (!mounted) return;
    if (_index + 1 >= _questions.length) {
      setState(() {
        _wrong = false;
        _input = '';
        _levelDone = true;
      });
    } else {
      _cardCtrl.reset();
      setState(() {
        _index++;
        _input = '';
        _wrong = false;
      });
      _cardCtrl.forward();
    }
  }

  bool get _passed => _score >= uzmanPassThreshold;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(widget.bgAsset, fit: BoxFit.cover),
          SafeArea(
            child: _levelDone ? _buildResult() : _buildQuiz(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    return Column(
      children: [
        _buildHeader(),
        const Spacer(flex: 1),
        _buildQuestionCard(),
        const SizedBox(height: 20),
        _buildKeypad(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader() {
    final total = _questions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(null),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF7C5CBF), size: 18),
            ),
          ),
          const Spacer(),
          // Score boxes
          Row(
            children: [
              _scoreChip('✓ $_score', const Color(0xFF56C068)),
              const SizedBox(width: 8),
              _scoreChip('${_index + 1}/$total', const Color(0xFF7C5CBF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
  );

  Widget _buildQuestionCard() {
    final isWrong = _wrong;
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        final shake = isWrong
            ? sin(_shakeAnim.value * 8 * pi) * 10
            : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: FadeTransition(
        opacity: _cardFade,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: _wrong ? const Color(0xFFFF5A5A).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: _wrong ? Border.all(color: const Color(0xFFFF5A5A), width: 2) : null,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              Text(
                _current.display,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF7C5CBF)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _input.isEmpty ? '—' : _input,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _wrong ? const Color(0xFFFF5A5A) : const Color(0xFF4A3080),
                  ),
                ),
              ),
              if (_wrong)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Doğru: ${_current.answer}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFFFF5A5A), fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
    final keyList = keys.expand((r) => r).toList();

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
                        onTap: () => _onKey(k),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: colors[colorIdx % colors.length].withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colors[colorIdx % colors.length].withValues(alpha: 0.35),
                                blurRadius: 6, offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Center(
                            child: k == '⌫'
                                ? const Icon(Icons.backspace_rounded, color: Colors.white, size: 22)
                                : Text(k, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          // TAMAM button
          GestureDetector(
            onTap: _onSubmit,
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF56C068),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF56C068).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Center(
                child: Text('TAMAM', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final levelStr = 'Bölüm ${widget.level}';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_passed ? '🏆' : '😅', style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(
          '$_score / ${_questions.length}',
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white,
              shadows: [Shadow(color: Colors.black45, blurRadius: 6)]),
        ),
        const SizedBox(height: 8),
        Text(
          _passed ? '$levelStr Tamamlandı! 🎉' : 'Tekrar dene! (%80 gerekli)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: _passed ? const Color(0xFFFFD700) : Colors.white70,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
        const SizedBox(height: 36),
        // Buttons
        GestureDetector(
          onTap: () => Navigator.of(context).pop(_passed ? _score : null),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            decoration: BoxDecoration(
              color: _passed ? const Color(0xFF56C068) : const Color(0xFFFF6B9D),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text(
              _passed ? 'Devam Et' : 'Tekrar Dene',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(null),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(28)),
            child: const Text('Haritaya Dön', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white70)),
          ),
        ),
      ],
    );
  }
}
