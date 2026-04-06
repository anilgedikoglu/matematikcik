import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/save_service.dart';
import '../services/audio_service.dart';
import 'quiz_screen.dart';
import 'menu_screen.dart';

// ── Haritadaki 10 level'in konumları (görsel analizi sonucu) ───────────────
// Offset(sol-sağ 0.0-1.0, yukarı-aşağı 0.0-1.0)
const List<Offset> _levelPos = [
  Offset(0.42, 0.92), // 1 — alt ortada, mavi robot
  Offset(0.67, 0.82), // 2 — sağda, abaküs
  Offset(0.42, 0.73), // 3 — orta, turuncu karakter
  Offset(0.20, 0.64), // 4 — solda
  Offset(0.72, 0.57), // 5 — sağda, ayı
  Offset(0.43, 0.50), // 6 — orta, kitap
  Offset(0.22, 0.42), // 7 — solda, piramitler
  Offset(0.43, 0.35), // 8 — orta, kum saati
  Offset(0.68, 0.27), // 9 — sağda, yıldız
  Offset(0.43, 0.17), // 10 — üst orta, kupa
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

  Future<void> _startLevel(int level) async {
    final result = await Navigator.of(context).push<int>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            QuizScreen(level: level, state: _state),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    if (!mounted) return;
    // Quiz'den döndüğünde yol müziğini yeniden başlat
    AudioService.playMapMusic();
    if (result != null) {
      final newUnlocked =
          (level >= _state.unlockedLevel && level < 10) ? level + 1 : _state.unlockedLevel;
      final newScores = Map<int, int>.from(_state.levelScores)..[level] = result;
      final newState = _state.copyWith(
        unlockedLevel: newUnlocked > _state.unlockedLevel ? newUnlocked : _state.unlockedLevel,
        levelScores: newScores,
      );
      await SaveService.save(newState);
      setState(() => _state = newState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // ── Arka plan ──────────────────────────────────────────────────
          Positioned.fill(
            child: Image.asset('assets/orman.png', fit: BoxFit.cover),
          ),

          // ── Level düğümleri ────────────────────────────────────────────
          LayoutBuilder(builder: (ctx, constraints) {
            return Stack(
              children: List.generate(10, (i) {
                final level = i + 1;
                final pos = _levelPos[i];
                final x = pos.dx * constraints.maxWidth;
                final y = pos.dy * constraints.maxHeight;
                return Positioned(
                  left: x - 28,
                  top: y - 28,
                  child: _LevelNode(
                    level: level,
                    state: _state,
                    pulseAnim: _pulseAnim,
                    onTap: () => _startLevel(level),
                  ),
                );
              }),
            );
          }),

          // ── Geri butonu (Scaffold yok — touch event sormaz) ───────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MenuScreen()),
                  ),
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
}

// ── Level düğümü ─────────────────────────────────────────────────────────

class _LevelNode extends StatelessWidget {
  final int level;
  final GameState state;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _LevelNode({
    required this.level,
    required this.state,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = level <= state.unlockedLevel;
    final isCurrent  = level == state.unlockedLevel;
    final isDone     = state.levelScores.containsKey(level);

    if (!isUnlocked) {
      return _circle(
        color: const Color(0xAA888888),
        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
      );
    }

    if (isCurrent) {
      // Aktif — yanıp sönen kırmızı çember (sadece border, dolgu yok)
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
                  '$level',
                  style: const TextStyle(
                    fontSize: 22,
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

    // Tamamlanmış
    return GestureDetector(
      onTap: onTap,
      child: _circle(
        color: const Color(0xFFFFD93D),
        child: isDone
            ? const Icon(Icons.star_rounded, color: Colors.white, size: 26)
            : Text(
                '$level',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _circle({required Color color, required Widget child}) =>
      Container(
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
