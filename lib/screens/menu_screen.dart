import 'package:flutter/material.dart';
import '../services/save_service.dart';
import '../services/audio_service.dart';
import '../models/game_state.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    _checkSave();
    AudioService.playMenuMusic();
  }

  @override
  void dispose() {
    // Başka ekrana geçişte müzik o ekranın initState'i durduracak.
    // Sadece uygulama kapanırsa temizle.
    super.dispose();
  }

  Future<void> _checkSave() async {
    final has = await SaveService.hasSave();
    if (mounted) setState(() => _hasSave = has);
  }

  void _newGame() async {
    await SaveService.deleteSave();
    final state = GameState.fresh();
    await SaveService.save(state);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MapScreen(state: state)),
    );
  }

  void _continueGame() async {
    final state = await SaveService.load();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MapScreen(state: state)),
    );
  }

  void _settings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bg.png', fit: BoxFit.cover),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double mat1H = 130;
                const double shift = 90; // 1.5 × 60px (mat1 position anchor)
                // mat1 top is anchored to the old centered+shifted position
                const double anchorContentH = mat1H + 32 + 60 * 3 + 16 * 2; // 396
                final double mat1Top =
                    ((constraints.maxHeight - anchorContentH) / 2 - shift).clamp(0.0, double.infinity);
                const double gap = 92; // 32 base + 60 (1 button down)
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: mat1Top),
                    Center(child: Image.asset('assets/mat1.png', height: mat1H)),
                    const SizedBox(height: gap),
                    _menuButton('YENİ OYUN', const Color(0xFFFF6B9D), _newGame),
                    const SizedBox(height: 16),
                    _menuButton(
                      'DEVAM ET',
                      _hasSave ? const Color(0xFF56C068) : const Color(0xFFD4C5E2),
                      _hasSave ? _continueGame : null,
                    ),
                    const SizedBox(height: 16),
                    _menuButton('AYARLAR', const Color(0xFF4BBEF5), _settings),
                  ],
                );
              },
            ),
          ),
        ],
      ),
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
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    )
                  ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
