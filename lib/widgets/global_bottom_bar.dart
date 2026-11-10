import 'package:flutter/material.dart';
import 'candy_bottom_bar.dart';
import '../models/game_state.dart';
import '../services/save_service.dart';
import '../screens/map_screen.dart';
import '../screens/uzman_map_screen.dart';
import '../screens/settings_screen.dart';

/// Tüm ekranlarda altta duran kalıcı candy kompartman.
/// Yığını sığ tutmak için her aksiyon önce ana menüye döner.
/// Ana menüde menu_screen kendi (yenileyen) bar'ını kullanır.
class GlobalBottomBar extends StatelessWidget {
  const GlobalBottomBar({super.key});

  Future<void> _play(NavigatorState nav) async {
    nav.popUntil((r) => r.isFirst);
    // Oynanan oyuna devam: önce Macera, sonra Uzman; yoksa Macera başlat.
    if (await SaveService.hasSave()) {
      final s = await SaveService.load();
      if (s.unlockedLevel > 1) {
        nav.push(MaterialPageRoute(builder: (_) => MapScreen(state: s)));
        return;
      }
    }
    final ulvl = await SaveService.loadUzmanLevel();
    if (ulvl > 1) {
      final scores = await SaveService.loadUzmanScores();
      nav.push(MaterialPageRoute(
          builder: (_) =>
              UzmanMapScreen(initialLevel: ulvl, initialScores: scores)));
      return;
    }
    final fresh = GameState.fresh();
    await SaveService.save(fresh);
    nav.push(MaterialPageRoute(builder: (_) => MapScreen(state: fresh)));
  }

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: CandyBottomBar(
            onHome: () => nav.popUntil((r) => r.isFirst),
            onPlay: () => _play(nav),
            onSettings: () {
              nav.popUntil((r) => r.isFirst);
              nav.push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ),
      ),
    );
  }
}
