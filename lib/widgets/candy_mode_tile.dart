import 'dart:ui';
import 'package:flutter/material.dart';

/// Ana menüdeki candy liquid-glass mod karesi (ikon + ad + ilerleme).
class CandyModeTile extends StatefulWidget {
  const CandyModeTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.size = 142,
  });

  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  State<CandyModeTile> createState() => _CandyModeTileState();
}

class _CandyModeTileState extends State<CandyModeTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final Color c = widget.color;
    final Color top = Color.alphaBlend(Colors.white.withValues(alpha: 0.5), c);
    const double r = 28;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            boxShadow: [
              BoxShadow(
                  color: c.withValues(alpha: 0.42),
                  blurRadius: 18,
                  offset: const Offset(0, 9)),
              const BoxShadow(
                  color: Color(0x225AA2FF),
                  blurRadius: 22,
                  offset: Offset(-5, 2)),
              const BoxShadow(
                  color: Color(0x22FF55C8),
                  blurRadius: 22,
                  offset: Offset(5, 3)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [top.withValues(alpha: 0.9), c.withValues(alpha: 0.88)],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.5,
                        widthFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.5),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    CustomPaint(painter: _TileRim(r)),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.emoji,
                            style: const TextStyle(fontSize: 46, shadows: [
                              Shadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 2))
                            ])),
                        const SizedBox(height: 6),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 1))
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.95),
                            shadows: const [
                              Shadow(color: Color(0x4D000000), blurRadius: 2, offset: Offset(0, 1))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TileRim extends CustomPainter {
  const _TileRim(this.radius);
  final double radius;

  static const List<Color> _colors = [
    Color(0xFFD9F1FF),
    Color(0xFF74AEFF),
    Color(0xFF8C9CFF),
    Color(0xFFC07CFF),
    Color(0xFFFF5FC4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Rect rect = Offset.zero & size;
    final RRect rr =
        RRect.fromRectAndRadius(rect.deflate(0.9), Radius.circular(radius));
    final Shader g = const LinearGradient(
      begin: Alignment(-1, -1),
      end: Alignment(1, 1),
      colors: _colors,
    ).createShader(rect);
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..shader = g,
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.35],
          colors: [Colors.white.withValues(alpha: 0.8), const Color(0x00FFFFFF)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _TileRim old) => old.radius != radius;
}
