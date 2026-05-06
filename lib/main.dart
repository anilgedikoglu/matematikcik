import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'services/audio_service.dart';
import 'screens/intro_screen.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await AudioService.init();
  runApp(
    DevicePreview(
      enabled: false,
      builder: (_) => const MatematikcikApp(),
    ),
  );
  // İlk frame render edildikten hemen sonra native splash kaldır
  // (IntroScreen'de değil burada yapınca ANR riski ortadan kalkar)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}

class MatematikcikApp extends StatelessWidget {
  const MatematikcikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matematikcik',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B9D)),
        useMaterial3: true,
      ),
      home: const IntroScreen(),
    );
  }
}
