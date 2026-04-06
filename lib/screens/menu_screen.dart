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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF0F5), Color(0xFFEDF4FF), Color(0xFFFFF8E7)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset('assets/matematikciikon.png',
                      width: 120, height: 120, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Matematikçik',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7C5CBF),
                  ),
                ),
                const SizedBox(height: 48),
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
            ),
          ),
        ),
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
