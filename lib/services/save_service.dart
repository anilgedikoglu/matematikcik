import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

class SaveService {
  static const _keyUnlocked = 'unlocked_level';
  static const _keyScores   = 'level_scores';
  static const _keyExists   = 'save_exists';
  static const _keySound    = 'sound_enabled';

  static Future<bool> hasSave() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyExists) ?? false;
  }

  static Future<GameState> load() async {
    final p = await SharedPreferences.getInstance();
    final unlocked = p.getInt(_keyUnlocked) ?? 1;
    final raw = p.getStringList(_keyScores) ?? [];
    final scores = <int, int>{};
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        final lvl   = int.tryParse(parts[0]);
        final score = int.tryParse(parts[1]);
        if (lvl != null && score != null) scores[lvl] = score;
      }
    }
    return GameState(unlockedLevel: unlocked, levelScores: scores);
  }

  static Future<void> save(GameState state) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyExists, true);
    await p.setInt(_keyUnlocked, state.unlockedLevel);
    final raw = state.levelScores.entries
        .map((e) => '${e.key}:${e.value}')
        .toList();
    await p.setStringList(_keyScores, raw);
  }

  static Future<bool> soundEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keySound) ?? true;
  }

  static Future<void> setSoundEnabled(bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keySound, val);
  }

  static Future<void> deleteSave() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyExists);
    await p.remove(_keyUnlocked);
    await p.remove(_keyScores);
  }
}
