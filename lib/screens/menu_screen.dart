import 'package:flutter/material.dart';
import '../services/save_service.dart';
import '../services/audio_service.dart';
import '../models/game_state.dart';
import 'map_screen.dart';
import 'uzman_map_screen.dart';
import 'mode_selection_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  GameState? _savedState;
  int _uzmanLevel = 1;
  int _carpimStars = 0;
  int _maceraStars = 0;
  int _uzmanStars = 0;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _checkSave();
    AudioService.playMenuMusic();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _checkSave() async {
    final has = await SaveService.hasSave();
    final uzmanLvl    = await SaveService.loadUzmanLevel();
    final carpimStars = await SaveService.loadCarpimStars();
    final maceraStars = await SaveService.loadMaceraStars();
    final uzmanStars  = await SaveService.loadUzmanStars();
    if (!has) {
      if (mounted) setState(() {
        _savedState = null; _uzmanLevel = uzmanLvl;
        _carpimStars = carpimStars; _maceraStars = maceraStars; _uzmanStars = uzmanStars;
      });
      return;
    }
    final state = await SaveService.load();
    if (mounted) setState(() {
      _savedState = state; _uzmanLevel = uzmanLvl;
      _carpimStars = carpimStars; _maceraStars = maceraStars; _uzmanStars = uzmanStars;
    });
  }

  void _newGame() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
    ).then((_) => _checkSave());
  }

  void _settings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  bool get _hasMaceraProgress => _savedState != null && (_savedState!.unlockedLevel) > 1;
  bool get _hasUzmanProgress => _uzmanLevel > 1;
  bool get _hasAnyProgress => _hasMaceraProgress || _hasUzmanProgress;

  void _continueGame() {
    if (!_hasAnyProgress) return;
    // Eğer sadece bir modda ilerleme varsa direkt gir
    if (_hasMaceraProgress && !_hasUzmanProgress) {
      _continueMacera();
      return;
    }
    if (_hasUzmanProgress && !_hasMaceraProgress) {
      _continueUzman();
      return;
    }
    // Her iki modda da ilerleme var → popup sor
    _showContinueDialog();
  }

  void _showContinueDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hangi moddan devam etmek istiyorsun?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF7C5CBF)),
              ),
              const SizedBox(height: 20),
              _dialogBtn(
                label: 'Macera Modu',
                subtitle: '${_savedState?.unlockedLevel ?? 1}. bölümden',
                color: const Color(0xFF56C068),
                active: _hasMaceraProgress,
                onTap: () { Navigator.of(context).pop(); _continueMacera(); },
              ),
              const SizedBox(height: 12),
              _dialogBtn(
                label: 'Uzman Modu',
                subtitle: '$_uzmanLevel. bölümden',
                color: const Color(0xFF7C5CBF),
                active: _hasUzmanProgress,
                onTap: () { Navigator.of(context).pop(); _continueUzman(); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogBtn({
    required String label,
    required String subtitle,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedOpacity(
        opacity: active ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continueMacera() async {
    final state = _savedState ?? await SaveService.load();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MapScreen(state: state)),
    );
    _checkSave();
  }

  Future<void> _continueUzman() async {
    final scores = await SaveService.loadUzmanScores();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UzmanMapScreen(initialLevel: _uzmanLevel, initialScores: scores)),
    );
    _checkSave();
  }

  @override
  Widget build(BuildContext context) {
    final hasSave = _savedState != null;
    final level = _savedState?.unlockedLevel ?? 1;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bg.png', fit: BoxFit.cover),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Transform.translate(
                    offset: const Offset(-6, 0),
                    child: Image.asset('assets/mat1.png', height: 118),
                  ),
                ),
                const Spacer(flex: 1),
                if (hasSave || _uzmanLevel > 1 || _carpimStars > 0)
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) {
                      final glow = _glowAnim.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF4D8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(255, 215, 0, glow * 0.85),
                              blurRadius: 8 + glow * 22,
                              spreadRadius: glow * 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/karakter_$level.png',
                              height: 110, width: 110,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'En Yüksek Başarı',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB89A00)),
                                ),
                                const SizedBox(height: 8),
                                _achievementRow('🗺️', 'Macera', _maceraStars > 0 ? '⭐' * _maceraStars : (hasSave ? '$level. bölüm' : '—')),
                                const SizedBox(height: 6),
                                _achievementRow('🧠', 'Uzman', _uzmanStars > 0 ? '⭐' * _uzmanStars : (_uzmanLevel > 1 ? '$_uzmanLevel. bölüm' : '—')),
                                const SizedBox(height: 6),
                                _achievementRow('✖️', 'Çarpım', _carpimStars > 0 ? '⭐' * _carpimStars : '—'),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const Spacer(flex: 1),
                _menuButton('YENİ OYUN', const Color(0xFFFF6B9D), _newGame),
                const SizedBox(height: 16),
                _menuButton(
                  'DEVAM ET',
                  _hasAnyProgress ? const Color(0xFF56C068) : const Color(0xFFD4C5E2),
                  _hasAnyProgress ? _continueGame : null,
                ),
                const SizedBox(height: 16),
                _menuButton('AYARLAR', const Color(0xFF4BBEF5), _settings),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementRow(String icon, String modeName, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          modeName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C5CBF)),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4A3080)),
        ),
      ],
    );
  }

  Widget _menuButton(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.45 : 1.0,
        child: Container(
          width: 240,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: onTap == null
                ? []
                : [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1),
            ),
          ),
        ),
      ),
    );
  }
}
