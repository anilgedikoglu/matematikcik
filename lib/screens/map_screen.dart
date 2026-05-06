import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/save_service.dart';
import '../services/audio_service.dart';
import 'quiz_screen.dart';
import 'menu_screen.dart';

// ── Haritadaki 10 node'un konumları (her dünya için aynı) ──────────────────
const List<Offset> _levelPos = [
  Offset(0.42, 0.92), // 1
  Offset(0.67, 0.82), // 2
  Offset(0.42, 0.73), // 3
  Offset(0.20, 0.64), // 4
  Offset(0.72, 0.57), // 5
  Offset(0.43, 0.50), // 6
  Offset(0.22, 0.42), // 7
  Offset(0.43, 0.35), // 8
  Offset(0.68, 0.27), // 9
  Offset(0.43, 0.17), // 10
];

// Dünya index (0-5) → arka plan asset
const List<String> _worldBg = [
  'assets/orman.png',
  'assets/orman2.png',
  'assets/orman3.png',
  'assets/orman4.png',
  'assets/orman5.png',
  'assets/orman6.png',
];

class MapScreen extends StatefulWidget {
  final GameState state;
  const MapScreen({super.key, required this.state});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late GameState _state;
  bool _showGameComplete = false;

  // Mevcut dünya (0-5) ve o dünyanın ilk leveli
  int get _world => ((_state.unlockedLevel - 1) ~/ 10).clamp(0, 5);
  int get _worldStart => _world * 10; // 0, 10, 20, 30, 40, 50

  @override
  void initState() {
    super.initState();
    _state = widget.state;
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
    final result = await Navigator.of(context).push<int>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            QuizScreen(level: actualLevel, state: _state),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    if (!mounted) return;
    AudioService.playMapMusic();

    if (result == -1) {
      // Tüm canlar bitti → oyunu sıfırla
      await SaveService.deleteSave();
      final fresh = GameState.fresh();
      await SaveService.save(fresh);
      setState(() => _state = fresh);
      return;
    }

    if (result != null && result >= 0) {
      final score = result ~/ 10;
      final remainingLives = result % 10;
      final newUnlocked = (actualLevel >= _state.unlockedLevel && actualLevel < 60)
          ? actualLevel + 1
          : _state.unlockedLevel;
      final newScores = Map<int, int>.from(_state.levelScores)..[actualLevel] = score;
      final newState = _state.copyWith(
        unlockedLevel: newUnlocked > _state.unlockedLevel ? newUnlocked : _state.unlockedLevel,
        levelScores: newScores,
        lives: remainingLives,
      );
      await SaveService.save(newState);
      setState(() => _state = newState);

      if (actualLevel == 60) {
        setState(() => _showGameComplete = true);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _goToMainMenu();
        });
      }
    }
  }

  void _goToMainMenu() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showGameComplete) return _buildGameComplete();

    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // ── Arka plan (dünyaya göre değişir) ──────────────────────────
          Positioned.fill(
            child: Image.asset(_worldBg[_world], fit: BoxFit.cover),
          ),

          // ── Level düğümleri ────────────────────────────────────────────
          LayoutBuilder(builder: (ctx, constraints) {
            final bottomPad = MediaQuery.of(ctx).padding.bottom;
            return Stack(
              children: List.generate(10, (i) {
                final nodeIndex = i + 1; // 1-10
                final actualLevel = _worldStart + nodeIndex;
                final pos = _levelPos[i];
                final x = pos.dx * constraints.maxWidth;
                final y = pos.dy * constraints.maxHeight -
                    (i == 0 ? bottomPad + 28 : 0);
                return Positioned(
                  left: x - 28,
                  top: y - 28,
                  child: _LevelNode(
                    actualLevel: actualLevel,
                    state: _state,
                    pulseAnim: _pulseAnim,
                    onTap: () => _startLevel(actualLevel),
                  ),
                );
              }),
            );
          }),

          // ── Geri butonu ────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: _goToMainMenu,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF7C5CBF)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameComplete() {
    return GestureDetector(
      onTap: _goToMainMenu,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/bg.png', fit: BoxFit.cover),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⭐ 🌟 ⭐ 🌟 ⭐',
                      style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 32),
                  const Text(
                    'HARİKA,',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD700),
                      shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                    ),
                  ),
                  const Text(
                    'OYUNU BİTİRDİN!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD700),
                      shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('⭐ 🌟 ⭐ 🌟 ⭐',
                      style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 40),
                  const Text(
                    'Devam etmek için dokun',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Level düğümü ─────────────────────────────────────────────────────────

class _LevelNode extends StatelessWidget {
  final int actualLevel;
  final GameState state;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _LevelNode({
    required this.actualLevel,
    required this.state,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = actualLevel <= state.unlockedLevel;
    final isCurrent = actualLevel == state.unlockedLevel;
    final isDone = state.levelScores.containsKey(actualLevel);

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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: const Color(0xFFFF3B30),
                    width: 3.5,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: _circle(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.70),
                child: Text(
                  '$actualLevel',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
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
            : Text(
                '$actualLevel',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _circle({required Color color, required Widget child}) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(child: child),
      );
}
