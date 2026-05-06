import 'package:flutter/material.dart';
import '../services/audio_service.dart';

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
          Image.asset('assets/bg2.png', fit: BoxFit.cover),
          SafeArea(
            child: Column(
              children: [
                // Üst bar: geri butonu + başlık
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C5CBF).withValues(alpha: 0.15),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFF7C5CBF)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Ayarlar',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFD93D),
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
                // Ses Efektleri kartı dikeyde ortalı
                Expanded(
                  child: Center(
                    child: Container(
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
                          )
                        ],
                      ),
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
                                color: Color(0xFF7C5CBF),
                              ),
                            ),
                          ),
                          Switch(
                            value: _sound,
                            activeColor: const Color(0xFF56C068),
                            onChanged: (val) {
                              setState(() => _sound = val);
                              AudioService.setEnabled(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
