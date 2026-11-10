import 'package:flutter/material.dart';
import '../services/save_service.dart';
import '../services/audio_service.dart';
import '../models/game_state.dart';
import '../widgets/candy_mode_tile.dart';
import '../widgets/candy_bottom_bar.dart';
import 'map_screen.dart';
import 'uzman_map_screen.dart';
import 'carpim_tablosu_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _hasSave = false;
  int _maceraLevel = 1;
  int _uzmanLevel = 1;
  int _carpimStars = 0;
  int _maceraStars = 0;
  int _uzmanStars = 0;

  @override
  void initState() {
    super.initState();
    _checkSave();
    AudioService.playMenuMusic();
  }

  Future<void> _checkSave() async {
    final has = await SaveService.hasSave();
    final uzmanLvl = await SaveService.loadUzmanLevel();
    final carpimStars = await SaveService.loadCarpimStars();
    final maceraStars = await SaveService.loadMaceraStars();
    final uzmanStars = await SaveService.loadUzmanStars();
    int maceraLvl = 1;
    if (has) {
      final s = await SaveService.load();
      maceraLvl = s.unlockedLevel;
    }
    if (mounted) {
      setState(() {
        _hasSave = has;
        _maceraLevel = maceraLvl;
        _uzmanLevel = uzmanLvl;
        _carpimStars = carpimStars;
        _maceraStars = maceraStars;
        _uzmanStars = uzmanStars;
      });
    }
  }

  bool get _hasMaceraProgress => _hasSave && _maceraLevel > 1;
  bool get _hasUzmanProgress => _uzmanLevel > 1;

  // ── Modlara giriş ──
  Future<void> _enterMacera() async {
    GameState state;
    if (await SaveService.hasSave()) {
      state = await SaveService.load();
    } else {
      state = GameState.fresh();
      await SaveService.save(state);
    }
    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => MapScreen(state: state)));
    _checkSave();
  }

  Future<void> _enterUzman() async {
    final level = await SaveService.loadUzmanLevel();
    final scores = await SaveService.loadUzmanScores();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            UzmanMapScreen(initialLevel: level, initialScores: scores)));
    _checkSave();
  }

  Future<void> _enterCarpim() async {
    final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const CarpimTablosuScreen()));
    if (result == true) {
      await SaveService.addCarpimStar();
    }
    _checkSave();
  }

  void _settings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()))
        .then((_) => _checkSave());
  }

  // Alt bardaki Play: oynanan oyuna devam (yoksa Macera başlat).
  void _play() {
    if (_hasMaceraProgress) {
      _enterMacera();
    } else if (_hasUzmanProgress) {
      _enterUzman();
    } else {
      _enterMacera();
    }
  }

  String _maceraSub() {
    if (_maceraStars > 0) return '⭐' * _maceraStars.clamp(1, 6);
    return _hasMaceraProgress ? '$_maceraLevel. bölüm' : 'Başla';
  }

  String _uzmanSub() {
    if (_uzmanStars > 0) return '⭐' * _uzmanStars.clamp(1, 6);
    return _hasUzmanProgress ? '$_uzmanLevel. bölüm' : 'Başla';
  }

  String _carpimSub() {
    if (_carpimStars > 0) return '⭐' * _carpimStars.clamp(1, 6);
    return 'Başla';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/anamenubg.jpg', fit: BoxFit.cover),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: 300,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    CandyModeTile(
                      emoji: '🗺️',
                      label: 'Macera',
                      subtitle: _maceraSub(),
                      color: const Color(0xFFFF6B9D),
                      onTap: _enterMacera,
                    ),
                    CandyModeTile(
                      emoji: '🧠',
                      label: 'Uzman',
                      subtitle: _uzmanSub(),
                      color: const Color(0xFF9B6BD6),
                      onTap: _enterUzman,
                    ),
                    CandyModeTile(
                      emoji: '✖️',
                      label: 'Çarpım',
                      subtitle: _carpimSub(),
                      color: const Color(0xFF4BBEF5),
                      onTap: _enterCarpim,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: CandyBottomBar(
                  onHome: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  onPlay: _play,
                  onSettings: _settings,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
