import 'package:flutter/services.dart';

/// Seviyeli titreşim:
/// - [light] (1): rakam / Tamam / şık seçimi (hafif)
/// - [medium] (2): menü & kompartman tuşları (orta)
/// - [heavy] (3): hata / yanlış cevap (güçlü)
class Haptic {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
}
