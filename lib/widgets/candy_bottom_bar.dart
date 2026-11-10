import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// Candy liquid-glass alt kompartman (Magnus cam alt barından, candy modelde).
/// Sol: Ana Menü · Orta: yükseltilmiş Play · Sağ: Ayarlar.
class CandyBottomBar extends StatelessWidget {
  const CandyBottomBar({
    super.key,
    required this.onHome,
    required this.onPlay,
    required this.onSettings,
  });

  final VoidCallback onHome;
  final VoidCallback onPlay;
  final VoidCallback onSettings;

  static const double barHeight = 62;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Buzlu candy cam bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(barHeight / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0.32),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(barHeight / 2),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x225AA2FF),
                          blurRadius: 20,
                          offset: Offset(-4, 4)),
                      BoxShadow(
                          color: Color(0x22FF55C8),
                          blurRadius: 20,
                          offset: Offset(4, 6)),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Üst cila
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
                      CustomPaint(painter: _BarRim(barHeight / 2)),
                      Row(
                        children: [
                          Expanded(
                            child: _IconBtn(
                              icon: Icons.home_rounded,
                              color: const Color(0xFF4BBEF5),
                              onTap: onHome,
                            ),
                          ),
                          const SizedBox(width: 84),
                          Expanded(
                            child: _IconBtn(
                              icon: Icons.settings_rounded,
                              color: const Color(0xFF9B6BD6),
                              onTap: onSettings,
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
          // Yükseltilmiş Play candy butonu
          Positioned(
            bottom: barHeight - 40,
            child: _PlayBtn(onTap: onPlay),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        Haptic.medium();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: SizedBox(
          height: CandyBottomBar.barHeight,
          child: Center(
            child: Icon(
              widget.icon,
              size: 30,
              color: widget.color,
              shadows: [
                Shadow(
                  color: widget.color.withValues(alpha: 0.45),
                  blurRadius: 10,
                ),
                const Shadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayBtn extends StatefulWidget {
  const _PlayBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_PlayBtn> createState() => _PlayBtnState();
}

class _PlayBtnState extends State<_PlayBtn> {
  static const Color _c = Color(0xFFFF6B9D); // candy pembe
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const double d = 66;
    final Color top = Color.alphaBlend(Colors.white.withValues(alpha: 0.5), _c);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        Haptic.medium();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: _c.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 5)),
              const BoxShadow(
                  color: Color(0x22FF55C8),
                  blurRadius: 22,
                  offset: Offset(0, 2)),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [top.withValues(alpha: 0.98), _c],
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
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.6),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    CustomPaint(painter: _CircleRim()),
                    const Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
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

const List<Color> _kRimColors = [
  Color(0xFFD9F1FF),
  Color(0xFF74AEFF),
  Color(0xFF8C9CFF),
  Color(0xFFC07CFF),
  Color(0xFFFF5FC4),
];

class _BarRim extends CustomPainter {
  const _BarRim(this.radius);
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Rect rect = Offset.zero & size;
    final RRect rr =
        RRect.fromRectAndRadius(rect.deflate(0.8), Radius.circular(radius));
    final Shader g = const LinearGradient(
      begin: Alignment(-1, -0.5),
      end: Alignment(1, 0.5),
      colors: _kRimColors,
    ).createShader(rect);
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
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
          stops: const [0.0, 0.4],
          colors: [Colors.white.withValues(alpha: 0.85), const Color(0x00FFFFFF)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _BarRim old) => old.radius != radius;
}

class _CircleRim extends CustomPainter {
  const _CircleRim();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Rect rect = Offset.zero & size;
    final Shader g = const LinearGradient(
      begin: Alignment(-1, -0.6),
      end: Alignment(1, 0.6),
      colors: _kRimColors,
    ).createShader(rect);
    canvas.drawArc(
      rect.deflate(0.8),
      0,
      6.2832,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = g,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleRim old) => false;
}
