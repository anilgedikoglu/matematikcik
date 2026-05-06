import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'save_service.dart';

class AudioService {
  static final _bg  = AudioPlayer(); // loop müzik
  static final _sfx = AudioPlayer(); // tek atış efektler
  static bool _enabled = true;
  static final _rng = Random();

  static Future<void> init() async {
    _enabled = await SaveService.soundEnabled();
    await _bg.setReleaseMode(ReleaseMode.loop);
    // Sfx sesi bg müziği durdurmadan üstüne çalsın
    await _sfx.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    ));
  }

  static void setEnabled(bool val) {
    _enabled = val;
    SaveService.setSoundEnabled(val);
    if (!val) _bg.stop();
  }

  static bool get enabled => _enabled;

  // ── Arka plan müzikleri (loop) ──────────────────────────────────────────

  static Future<void> playMenuMusic() async {
    if (!_enabled) return;
    try {
      await _bg.stop();
      await _bg.setReleaseMode(ReleaseMode.loop);
      await _bg.play(AssetSource('sounds/menu.mp3'));
    } catch (_) {}
  }

  static Future<void> playMapMusic() async {
    if (!_enabled) return;
    try {
      await _bg.stop();
      await _bg.setReleaseMode(ReleaseMode.loop);
      await _bg.play(AssetSource('sounds/yol.mp3'));
    } catch (_) {}
  }

  /// Her bölüm başında random bir oyun müziği seçip loop olarak başlatır.
  static Future<void> playGameMusic() async {
    if (!_enabled) return;
    try {
      final track = _rng.nextInt(4) + 1;
      await _bg.stop();
      await _bg.setReleaseMode(ReleaseMode.loop);
      await _bg.play(AssetSource('sounds/oyun$track.mp3'));
    } catch (_) {}
  }

  static Future<void> stopMusic() async {
    try { await _bg.stop(); } catch (_) {}
  }

  // ── Ses efektleri (tek atış) ────────────────────────────────────────────

  /// Doğru cevapta tik sesi
  static Future<void> playCorrect() async {
    if (!_enabled) return;
    try { await _sfx.play(AssetSource('sounds/dogru.mp3')); } catch (_) {}
  }

  /// Oyun bitti ekranında — bg müziği durur
  static Future<void> playGameOver() async {
    try { await _bg.stop(); } catch (_) {}
    if (!_enabled) return;
    try { await _sfx.play(AssetSource('sounds/oyunbitti.mp3')); } catch (_) {}
  }

  /// Sorular arası geçiş tıklaması
  static Future<void> playTransition() async {
    if (!_enabled) return;
    try { await _sfx.play(AssetSource('sounds/chlink.mp3')); } catch (_) {}
  }

  /// Level tamamlandı — bg müziği durur
  static Future<void> playWin() async {
    try { await _bg.stop(); } catch (_) {}
    if (!_enabled) return;
    try { await _sfx.play(AssetSource('sounds/win.mp3')); } catch (_) {}
  }
}
