import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

/// "Diğer Oyunlar": geliştiricinin mağaza sayfasını açar
/// (diğer Futurastic oyunlarıyla aynı davranış).
class DigerOyunlar {
  static final Uri _ios =
      Uri.parse('https://apps.apple.com/developer/id1612979370');
  static final Uri _android = Uri.parse(
      'https://play.google.com/store/apps/developer?id=Futurastic+Teknoloji+Limited+%C5%9Eirketi');

  static Future<void> ac() async {
    final uri = Platform.isIOS ? _ios : _android;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
