import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Liquid-glass aç/kapa sürgüsü (Magnus bildirim düğmesi ruhundan, shader'sız).
/// Buzlu cam iz + kayan glossy cam knob + AÇIK/KAPALI crossfade yazı +
/// mavi(kapalı)→amber(açık) renk geçişi + hafif yay + haptik.
class GlassToggle extends StatefulWidget {
  const GlassToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 138,
    this.height = 46,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  @override
  State<GlassToggle> createState() => _GlassToggleState();
}

class _GlassToggleState extends State<GlassToggle>
    with SingleTickerProviderStateMixin {
  static const Color _off = Color(0xFF6F86FF); // kapalı: mavi
  static const Color _on = Color(0xFFFFA82E); // açık: amber

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: widget.value ? 1 : 0,
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeOutBack,
  );

  @override
  void didUpdateWidget(covariant GlassToggle old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      widget.value ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final double w = widget.width, h = widget.height;
    const double inset = 3;
    final double knobW = w * 0.52;
    final double knobH = h - 2 * inset;
    final double travel = w - knobW - 2 * inset;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: SizedBox(
        width: w,
        height: h,
        child: AnimatedBuilder(
          animation: _a,
          builder: (_, __) {
            final double t = _a.value.clamp(0.0, 1.0);
            final Color knob = Color.lerp(_off, _on, t)!;
            final Color knobTop =
                Color.alphaBlend(Colors.white.withValues(alpha: 0.5), knob);
            return Stack(
              children: [
                // Buzlu cam iz
                ClipRRect(
                  borderRadius: BorderRadius.circular(h / 2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      width: w,
                      height: h,
                      decoration: BoxDecoration(
                        color: Color.lerp(const Color(0x33203050),
                            const Color(0x33402A10), t),
                        borderRadius: BorderRadius.circular(h / 2),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Kayan glossy cam knob
                Positioned(
                  left: inset + travel * t,
                  top: inset,
                  child: Container(
                    width: knobW,
                    height: knobH,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(knobH / 2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [knobTop.withValues(alpha: 0.96), knob],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: knob.withValues(alpha: 0.55),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Parlak üst cila
                        Align(
                          alignment: Alignment.topCenter,
                          child: FractionallySizedBox(
                            heightFactor: 0.5,
                            widthFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(knobH / 2)),
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
                        // Yanardöner kenar
                        CustomPaint(painter: _ToggleRim(knobH / 2)),
                        // AÇIK / KAPALI crossfade
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: (1 - t * 2).clamp(0.0, 1.0),
                                child: const Text('KAPALI', style: _lbl),
                              ),
                              Opacity(
                                opacity: (t * 2 - 1).clamp(0.0, 1.0),
                                child: const Text('AÇIK', style: _lbl),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static const TextStyle _lbl = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.8,
    shadows: [Shadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 1))],
  );
}

class _ToggleRim extends CustomPainter {
  const _ToggleRim(this.radius);
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
    final RRect rrect =
        RRect.fromRectAndRadius(rect.deflate(0.7), Radius.circular(radius));
    final Shader g = const LinearGradient(
      begin: Alignment(-1, -0.5),
      end: Alignment(1, 0.5),
      colors: _colors,
    ).createShader(rect);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = g,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.45],
          colors: [Colors.white.withValues(alpha: 0.85), const Color(0x00FFFFFF)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ToggleRim old) => old.radius != radius;
}
