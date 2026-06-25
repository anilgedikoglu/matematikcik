import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/save_service.dart';
import 'map_screen.dart';
import 'uzman_map_screen.dart';
import 'carpim_tablosu_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});
  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  int _carpimStars = 0;

  @override
  void initState() {
    super.initState();
    _loadStars();
  }

  Future<void> _loadStars() async {
    final stars = await SaveService.loadCarpimStars();
    if (mounted) setState(() => _carpimStars = stars);
  }

  Future<void> _startMaceraModu() async {
    final fresh = GameState.fresh();
    await SaveService.save(fresh);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MapScreen(state: fresh)),
    );
  }

  Future<void> _startUzmanModu() async {
    await SaveService.deleteUzmanSave();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UzmanMapScreen()),
    );
  }

  Future<void> _startCarpimTablosu() async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CarpimTablosuScreen()),
    );
    if (result == true) {
      await SaveService.addCarpimStar();
      await _loadStars();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [Color(0xFFFFF0F5), Color(0xFFEDF4FF), Color(0xFFFFF8E7)],
          ),
        ),
        child: SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
                const Spacer(flex: 1),
                _modeButton(
                  asset: 'assets/uzmanmodu.png',
                  label: 'Uzman Modu',
                  onTap: _startUzmanModu,
                ),
                const SizedBox(height: 20),
                _modeButton(
                  asset: 'assets/maceramodu.png',
                  label: 'Macera Modu',
                  onTap: _startMaceraModu,
                ),
                const SizedBox(height: 20),
                _modeButton(
                  asset: 'assets/carpimtablosu.png',
                  label: 'Çarpım Tablosu',
                  stars: _carpimStars,
                  onTap: _startCarpimTablosu,
                ),
                const Spacer(flex: 1),
              ],
            ),
        ),
      ),
    );
  }

  Widget _modeButton({
    required String asset,
    required String label,
    required VoidCallback onTap,
    int stars = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFFF3B30), width: 2),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Opacity(
                opacity: 0.9,
                child: Image.asset(asset, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (stars > 0)
            Text(
              '⭐' * stars.clamp(0, 10),
              style: const TextStyle(fontSize: 15),
            ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7C5CBF),
            ),
          ),
        ],
      ),
    );
  }
}
