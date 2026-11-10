import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/diger_oyunlar.dart';
import '../widgets/glass_toggle.dart';
import '../widgets/global_bottom_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sound = AudioService.enabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/ayarlarbg.jpg', fit: BoxFit.cover),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 18),
                const Text(
                  'Ayarlar',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFD93D),
                    shadows: [Shadow(color: Colors.black38, blurRadius: 5)],
                  ),
                ),
                const Spacer(),
                // Ses Efektleri
                _card(
                  child: Row(
                    children: [
                      const Text('🔊', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ses Efektleri',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7C5CBF)),
                        ),
                      ),
                      GlassToggle(
                        value: _sound,
                        onChanged: (val) {
                          setState(() => _sound = val);
                          AudioService.setEnabled(val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Diğer Oyunlar
                GestureDetector(
                  onTap: () => DigerOyunlar.ac(),
                  behavior: HitTestBehavior.opaque,
                  child: _card(
                    child: Row(
                      children: const [
                        Text('🎮', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Diğer Oyunlar',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7C5CBF)),
                          ),
                        ),
                        Icon(Icons.open_in_new_rounded,
                            color: Color(0xFF9B6BD6), size: 24),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                const SizedBox(height: 92), // alt bar payı
              ],
            ),
          ),
          const GlobalBottomBar(),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C5CBF).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
