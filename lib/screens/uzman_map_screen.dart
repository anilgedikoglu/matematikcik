import 'package:flutter/material.dart';
import '../services/save_service.dart';
import '../services/audio_service.dart';
import 'uzman_quiz_screen.dart';
import 'menu_screen.dart';

const List<String> _uzmanBgs = [
  'assets/uzmanmodubg.png',
  'assets/uzmanmodubg2.png',
  'assets/uzmanmodubg3.png',
  'assets/uzmanmodubg4.png',
  'assets/uzmanmodubg5.png',
];

const int _uzmanMaxLevel = 50;

const List<Offset> _levelPos = [
  Offset(0.42, 0.92),
  Offset(0.67, 0.82),
  Offset(0.42, 0.73),
  Offset(0.20, 0.64),
  Offset(0.72, 0.57),
  Offset(0.43, 0.50),
  Offset(0.22, 0.42),
  Offset(0.43, 0.35),
  Offset(0.68, 0.27),
  Offset(0.43, 0.17),
];

class UzmanMapScreen extends StatefulWidget {
  final int initialLevel;
  final Map<int, int> initialScores;
  const UzmanMapScreen({
    super.key,
    this.initialLevel = 1,
    this.initialScores = const {},
  });
  @override
  State<UzmanMapScreen> createState() => _UzmanMapScreenState();
}

class _UzmanMapScreenState extends State<UzmanMapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late int _unlockedLevel;
  late Map<int, int> _scores;
  bool _showComplete = false;

  int get _world => ((_unlockedLevel - 1) ~/ 10).clamp(0, 4);
  int get _worldStart => _world * 10;
  String get _bgAsset => _uzmanBgs[_world];

  @override
  void initState() {
    super.initState();
    _unlockedLevel = widget.initialLevel;
    _scores = Map.from(widget.initialScores);
    AudioService.playMapMusic();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startLevel(int actualLevel) async {
    final levelBg = _uzmanBgs[((actualLevel - 1) ~/ 10).clamp(0, 4)];
    final result = await Navigator.of(context).push<int?>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => UzmanQuizScreen(level: actualLevel, bgAsset: levelBg),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    if (!mounted) return;
    AudioService.playMapMusic();

    if (result != null && result > 0) {
      if (actualLevel == _uzmanMaxLevel) {
        // Oyun tamamlandı — yıldız kazan ve sıfırla
        await SaveService.addUzmanStar();
        await SaveService.saveUzmanProgress(1, {});
        setState(() { _showComplete = true; _unlockedLevel = 1; _scores = {}; });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _goToMainMenu();
        });
      } else {
        final newUnlocked = (actualLevel >= _unlockedLevel && actualLevel < _uzmanMaxLevel)
            ? actualLevel + 1
            : _unlockedLevel;
        final newScores = Map<int, int>.from(_scores)..[actualLevel] = result;
        final saveLevel = newUnlocked > _unlockedLevel ? newUnlocked : _unlockedLevel;
        await SaveService.saveUzmanProgress(saveLevel, newScores);
        setState(() { _unlockedLevel = saveLevel; _scores = newScores; });
      }
    }
  }

  void _goToMainMenu() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showComplete) return _buildComplete();
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/uzmanmodubg.png', fit: BoxFit.cover),
          ),
          LayoutBuilder(builder: (ctx, constraints) {
            final bottomPad = MediaQuery.of(ctx).padding.bottom;
            return Stack(
              children: List.generate(10, (i) {
                final nodeIndex = i + 1;
                final actualLevel = _worldStart + nodeIndex;
                final pos = _levelPos[i];
                final x = pos.dx * constraints.maxWidth;
                final y = pos.dy * constraints.maxHeight -
                    (i == 0 ? bottomPad + 28 : 0) + 52;
                return Positioned(
                  left: x - 28,
                  top: y - 28,
                  child: _UzmanLevelNode(
                    actualLevel: actualLevel,
                    unlockedLevel: _unlockedLevel,
                    scores: _scores,
                    pulseAnim: _pulseAnim,
                    onTap: () => _startLevel(actualLevel),
                  ),
                );
              }),
            );
          }),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: _goToMainMenu,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF7C5CBF)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplete() {
    return GestureDetector(
      onTap: _goToMainMenu,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_bgAsset, fit: BoxFit.cover),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('⭐ 🌟 ⭐ 🌟 ⭐', style: TextStyle(fontSize: 44)),
                  SizedBox(height: 32),
                  Text('UZMAN MODU', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFFFFD700), shadows: [Shadow(color: Colors.black26, blurRadius: 8)])),
                  Text('BİTİRDİN!', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFFFFD700), shadows: [Shadow(color: Colors.black26, blurRadius: 8)])),
                  SizedBox(height: 32),
                  Text('⭐ 🌟 ⭐ 🌟 ⭐', style: TextStyle(fontSize: 44)),
                  SizedBox(height: 40),
                  Text('Devam etmek için dokun', style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UzmanLevelNode extends StatelessWidget {
  final int actualLevel;
  final int unlockedLevel;
  final Map<int, int> scores;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _UzmanLevelNode({
    required this.actualLevel,
    required this.unlockedLevel,
    required this.scores,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = actualLevel <= unlockedLevel;
    final isCurrent = actualLevel == unlockedLevel;
    final isDone = scores.containsKey(actualLevel);

    if (!isUnlocked) {
      return _circle(
        color: const Color(0xAA888888),
        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
      );
    }

    if (isCurrent) {
      return AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: pulseAnim.value,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(color: const Color(0xFFFF3B30), width: 3.5),
                ),
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: _circle(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.70),
                child: Text('$actualLevel', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: _circle(
        color: const Color(0xFFFFD93D),
        child: isDone
            ? const Icon(Icons.star_rounded, color: Colors.white, size: 26)
            : Text('$actualLevel', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }

  Widget _circle({required Color color, required Widget child}) => Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(child: child),
      );
}
