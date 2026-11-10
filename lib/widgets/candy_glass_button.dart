import 'dart:ui';
import 'package:flutter/material.dart';

/// Candy Liquid-Glass pill butonu (Magnus 2026-11-08 cam temasından uyarlandı).
/// Arka planı buzlandırır (BackdropFilter), üstüne şeker jölesi renk dolgusu,
/// parlak üst "specular" cila, yanardöner kenar ışığı ve çift renkli yumuşak
/// gölge koyar. [color] butonun kimlik rengidir (jöleyi boyar).
class CandyGlassButton extends StatefulWidget {
  const CandyGlassButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.width = 250,
    this.height = 62,
    this.fontSize = 20,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final double fontSize;

  @override
  State<CandyGlassButton> createState() => _CandyGlassButtonState();
}

class _CandyGlassButtonState extends State<CandyGlassButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    final Color c = widget.color;
    final double r = widget.height / 2;

    // Jölenin üst tonu: kimlik renginin beyazla açılmış pastel hali → cıvıl candy.
    final Color topTint = Color.alphaBlend(Colors.white.withValues(alpha: 0.55), c);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r),
              boxShadow: enabled
                  ? [
                      // kimlik rengi parıltısı
                      BoxShadow(
                        color: c.withValues(alpha: 0.42),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                      // candy çift ton: solda mavi, sağda pembe hale
                      const BoxShadow(
                        color: Color(0x225AA2FF),
                        blurRadius: 22,
                        offset: Offset(-5, 2),
                      ),
                      const BoxShadow(
                        color: Color(0x22FF55C8),
                        blurRadius: 22,
                        offset: Offset(5, 3),
                      ),
                    ]
                  : const [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        topTint.withValues(alpha: 0.88),
                        c.withValues(alpha: 0.84),
                      ],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Parlak üst cila (specular) — jölenin ıslak görünümü
                      Align(
                        alignment: Alignment.topCenter,
                        child: FractionallySizedBox(
                          heightFactor: 0.52,
                          widthFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.55),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Yanardöner candy kenar ışığı
                      CustomPaint(painter: _CandyRim(r)),
                      // Etiket
                      Center(
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                            shadows: const [
                              Shadow(
                                color: Color(0x55000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Candy kenar: yanardöner mavi → mor → pembe ışık + üstte ince beyaz parlama.
/// (Magnus CandyRimPainter'ın sade uyarlaması.)
class _CandyRim extends CustomPainter {
  const _CandyRim(this.radius);

  final double radius;

  static const List<Color> _colors = [
    Color(0xFFD9F1FF),
    Color(0xFF74AEFF),
    Color(0xFF8C9CFF),
    Color(0xFFC07CFF),
    Color(0xFFFF5FC4),
  ];
  static const List<double> _stops = [0.0, 0.28, 0.55, 0.78, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Rect rect = Offset.zero & size;
    final RRect rrect =
        RRect.fromRectAndRadius(rect.deflate(0.8), Radius.circular(radius));
    final Shader gradient = const LinearGradient(
      begin: Alignment(-1, -0.5),
      end: Alignment(1, 0.5),
      colors: _colors,
      stops: _stops,
    ).createShader(rect);

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    // İçe yayılan yumuşak ışık
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..shader = gradient
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    canvas.restore();

    // Keskin ince kenar
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = gradient,
    );
    // Üstte ince beyaz parlama
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.4],
          colors: [
            Colors.white.withValues(alpha: 0.85),
            const Color(0x00FFFFFF),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _CandyRim old) => old.radius != radius;
}
