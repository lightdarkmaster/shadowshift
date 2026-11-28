import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/progression/shop_examples.dart';
import 'package:shadowshift/ui/widgets/design.dart';

/// Detail sheet opened when a shop item is tapped. It always includes a
/// concrete run example, plus a live preview that mirrors the gameplay visuals.
class ShopItemDetailDialog extends StatefulWidget {
  const ShopItemDetailDialog({
    super.key,
    required this.item,
    required this.category,
    required this.isOwned,
    required this.selected,
    required this.onUse,
  });

  final ShopItem item;
  final String category;
  final bool isOwned;
  final bool selected;
  final VoidCallback onUse;

  @override
  State<ShopItemDetailDialog> createState() => _ShopItemDetailDialogState();
}

class _ShopItemDetailDialogState extends State<ShopItemDetailDialog>
    with SingleTickerProviderStateMixin {
  /// Long enough that the preview never loops during a normal visit.
  static const _previewLength = Duration(seconds: 3600);
  static const _animationDelay = Duration(milliseconds: 1500);

  late final AnimationController _controller;
  Timer? _startTimer;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _previewLength);
    _startTimer = Timer(_animationDelay, () {
      if (!mounted) return;
      setState(() => _animating = true);
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final example = ShopExamples.forItem(widget.category, item.id);
    final maxHeight = (MediaQuery.of(context).size.height * 0.84)
        .clamp(400.0, 700.0)
        .toDouble();
    final actionLabel = widget.selected
        ? 'EQUIPPED'
        : widget.isOwned
            ? 'EQUIP NOW'
            : 'UNLOCK FOR ${item.price}';

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: item.color.withValues(alpha: 0.35)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: item.color.withValues(alpha: 0.5)),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            color: item.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_categoryLabel(widget.category)} - ${item.description}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _animating ? item.color : AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _animating ? 'LIVE PREVIEW' : 'STATIC PREVIEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            color: _animating ? item.color : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 132,
                      width: double.infinity,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _PreviewPainter(
                              category: widget.category,
                              id: item.id,
                              color: item.color,
                              time: _animating ? _controller.value * _previewLength.inSeconds : 0,
                              animating: _animating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'EXAMPLE IN A RUN',
                      style: TextStyle(
                        color: item.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      example.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      example.detail,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.text,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ExampleValue(
                            label: 'BEFORE',
                            value: example.before,
                            color: AppColors.muted,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward, size: 18, color: item.color),
                        ),
                        Expanded(
                          child: _ExampleValue(
                            label: 'WITH THIS',
                            value: example.after,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CLOSE'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeonButton(
                      label: actionLabel,
                      icon: widget.selected
                          ? Icons.check
                          : widget.isOwned
                              ? Icons.palette
                              : Icons.paid,
                      color: item.color,
                      secondary: widget.selected,
                      selected: widget.selected,
                      compact: true,
                      onPressed: widget.selected
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              widget.onUse();
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _categoryLabel(String category) => switch (category) {
        'skin' => 'SKIN',
        'effect' => 'EFFECT',
        'ability' => 'CORE',
        'companion' => 'COMPANION',
        _ => category.toUpperCase(),
      };
}

class _ExampleValue extends StatelessWidget {
  const _ExampleValue({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.micro.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  const _PreviewPainter({
    required this.category,
    required this.id,
    required this.color,
    required this.time,
    required this.animating,
  });

  final String category;
  final String id;
  final Color color;
  final double time;
  final bool animating;

  double get t => animating ? time : 0;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      background,
    );

    final laneLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (double y = 24; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), laneLine);
    }

    final floor = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.78),
      Offset(size.width * 0.84, size.height * 0.78),
      floor,
    );

    final runner = Offset(size.width * 0.29, size.height * 0.54);

    switch (category) {
      case 'skin':
        _drawSkin(canvas, runner);
      case 'effect':
        _drawEffect(canvas, runner, size);
      case 'ability':
        _drawCore(canvas, runner, size);
      case 'companion':
        _drawCompanion(canvas, runner);
      default:
        _drawRunner(canvas, runner, color);
    }
  }

  void _drawSkin(Canvas canvas, Offset runner) {
    if (id == 'spectrum') {
      final hues = [
        HSVColor.fromAHSV(1, (t * 0.4 * 360) % 360, 0.82, 1).toColor(),
        HSVColor.fromAHSV(1, (t * 0.4 * 360 + 120) % 360, 0.82, 1).toColor(),
        HSVColor.fromAHSV(1, (t * 0.4 * 360 + 240) % 360, 0.82, 1).toColor(),
      ];
      for (var i = 0; i < hues.length; i++) {
        _drawRunner(
          canvas,
          runner.translate(-i * 15.0, i * 4.0),
          hues[i],
          radius: 13 - i * 1.5,
          opacity: 0.9 - i * 0.2,
        );
      }
      return;
    }

    final pulse = animating ? math.sin(t * 2.4) * 1.6 : 0.0;
    for (var i = 3; i >= 1; i--) {
      final drift = i * 18.0 + (animating ? (t * 14) % 18 : 0.0);
      canvas.drawCircle(
        runner.translate(-drift, i * 2.0),
        13 - i * 1.4,
        Paint()..color = color.withValues(alpha: 0.08 * (4 - i)),
      );
    }
    _drawRunner(canvas, runner, color, radius: 14 + pulse);
  }

  void _drawEffect(Canvas canvas, Offset runner, Size size) {
    _drawRunner(canvas, runner, color, radius: 12);

    switch (id) {
      case 'classic':
        final phase = (t * 0.55) % 1;
        _ring(
          canvas,
          runner,
          18 + phase * 30,
          color.withValues(alpha: (1 - phase) * 0.75),
          2.2,
        );
      case 'comet':
        for (var i = 0; i < 3; i++) {
          final phase = (t * 0.75 + i / 3) % 1;
          final start = runner.translate(-18 - phase * 48, -10 + i * 10);
          final end = runner.translate(8, -4 + i * 5);
          canvas.drawLine(
            start,
            end,
            Paint()
              ..color = color.withValues(alpha: (1 - phase) * 0.65)
              ..strokeWidth = 3 - i * 0.5,
          );
          canvas.drawCircle(
            start,
            2.5,
            Paint()..color = color.withValues(alpha: 0.9),
          );
        }
      case 'pulse':
        for (var ring = 0; ring < 3; ring++) {
          final phase = (t * 0.85 + ring / 3) % 1;
          _ring(
            canvas,
            runner,
            16 + phase * 38,
            color.withValues(alpha: (1 - phase) * 0.55),
            2.4 - ring * 0.4,
          );
        }
      case 'void':
        final phase = (t * 0.5) % 1;
        _ring(
          canvas,
          runner,
          22 + phase * 26,
          color.withValues(alpha: (1 - phase) * 0.55),
          3,
        );
        for (var i = 0; i < 5; i++) {
          final rise = animating ? (t * 22 + i * 11) % 50 : i * 11.0;
          canvas.drawCircle(
            runner.translate(18 + i * 8 + math.sin(t + i) * 3, 12 - rise),
            2.5,
            Paint()..color = AppColors.pink.withValues(alpha: 0.85),
          );
        }
      case 'nova':
        final rotation = t * 0.7;
        final radius = 30 + (animating ? math.sin(t * 2) * 6 : 0.0);
        for (var i = 0; i < 10; i++) {
          final angle = i * math.pi / 5 + rotation;
          canvas.drawLine(
            runner.translate(math.cos(angle) * radius * 0.55, math.sin(angle) * radius * 0.55),
            runner.translate(math.cos(angle) * radius * 1.15, math.sin(angle) * radius * 1.15),
            Paint()
              ..color = color.withValues(alpha: 0.75)
              ..strokeWidth = 2.5,
          );
        }
      case 'glitch':
        final shift = animating ? math.sin(t * 6) * 4 : 3.0;
        _drawRunner(canvas, runner.translate(-shift, -3), AppColors.danger,
            radius: 11, opacity: 0.55);
        _drawRunner(canvas, runner.translate(shift, 3), AppColors.cyan,
            radius: 11, opacity: 0.55);
        final offset = (t * 110) % 26;
        final scan = Paint()..color = Colors.white.withValues(alpha: 0.25);
        for (double y = runner.dy - 24 + offset; y < runner.dy + 28; y += 9) {
          canvas.drawLine(Offset(runner.dx - 46, y), Offset(runner.dx + 46, y), scan);
        }
      case 'blizzard':
        for (var i = 0; i < 8; i++) {
          final x = (i * 31.0 + t * (28 + (i % 5) * 12)) % (size.width + 20) - 10;
          final y = (i * 47.0 + t * (20 + (i % 3) * 10)) % size.height;
          canvas.drawCircle(
            Offset(x, y),
            2 + (i % 2),
            Paint()..color = color.withValues(alpha: 0.7),
          );
        }
      case 'prism':
        for (var ring = 0; ring < 3; ring++) {
          final phase = (t * 0.7 + ring / 3) % 1;
          final hue = HSVColor.fromAHSV(1, (t * 0.5 * 360 + ring * 120) % 360, 0.82, 1)
              .toColor();
          _ring(
            canvas,
            runner,
            18 + phase * 34,
            hue.withValues(alpha: (1 - phase) * 0.8),
            2.2,
          );
        }
    }
  }

  void _drawCore(Canvas canvas, Offset runner, Size size) {
    final baseWidth = size.width * (id == 'none' ? 0.54 : 0.30);
    final base = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.30, baseWidth, 18),
      const Radius.circular(9),
    );
    canvas.drawRRect(base, Paint()..color = Colors.white.withValues(alpha: 0.18));

    final boostWidth = size.width * 0.54;
    final boost = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.55, boostWidth, 18),
      const Radius.circular(9),
    );
    canvas.drawRRect(boost, Paint()..color = color.withValues(alpha: 0.72));

    if (animating) {
      final marker = size.width * 0.18 + boostWidth * ((t * 0.45) % 1);
      canvas.drawCircle(
        Offset(marker, size.height * 0.55 + 9),
        4,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }

    if (id == 'none') return;
    _drawRunner(canvas, runner, AppColors.cyan, radius: 11);

    final center = Offset(size.width * 0.78, size.height * 0.34);
    switch (id) {
      case 'overclock':
        for (var i = 0; i < 3; i++) {
          final phase = (t * 0.8 + i / 3) % 1;
          canvas.drawCircle(
            runner.translate(18 + (1 - phase) * 40, -8 + i * 8),
            4,
            Paint()..color = AppColors.gold.withValues(alpha: 1 - phase),
          );
        }
      case 'magnet_core':
        for (var ring = 0; ring < 3; ring++) {
          final phase = (t * 0.9 + ring / 3) % 1;
          _ring(
            canvas,
            center,
            10 + phase * 26,
            color.withValues(alpha: (1 - phase) * 0.8),
            2,
          );
        }
      case 'phase_core':
        _ring(
          canvas,
          runner,
          20 + (animating ? math.sin(t * 3) * 2 : 0),
          AppColors.violet.withValues(alpha: 0.75),
          3,
        );
      case 'chrono_core':
        _ring(canvas, center, 20, color.withValues(alpha: 0.65), 2);
        final angle = t * 1.6;
        canvas.drawLine(
          center,
          center.translate(math.cos(angle) * 15, math.sin(angle) * 15),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.9)
            ..strokeWidth = 2,
        );
      case 'double_core':
        _label(canvas, 'x2', center, Colors.white, fontSize: 18);
      case 'aegis_core':
        _ring(canvas, runner, 24, AppColors.cyan.withValues(alpha: 0.8), 3);
        _label(canvas, '+50%', center, Colors.white, fontSize: 11);
      case 'momentum_core':
        for (var i = 0; i < 3; i++) {
          final phase = (t * 1.1 + i / 3) % 1;
          canvas.drawLine(
            runner.translate(14 + phase * 40, -10 + i * 10),
            runner.translate(30 + phase * 40, -10 + i * 10),
            Paint()
              ..color = color.withValues(alpha: 1 - phase)
              ..strokeWidth = 3,
          );
        }
    }
  }

  void _drawCompanion(Canvas canvas, Offset runner) {
    if (id == 'none') {
      _drawRunner(canvas, runner, color);
      return;
    }

    // Same bob timing as the live companion in ShadowPainter.
    final ally = runner.translate(
      58 + (animating ? math.sin(t * 2.3) * 6 : 0),
      -30 + (animating ? math.cos(t * 1.7) * 9 : 0),
    );
    canvas.drawLine(
      runner,
      ally,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 2,
    );
    _drawRunner(canvas, runner, AppColors.cyan, radius: 13);

    final pulse = animating ? math.sin(t * 2.8) * 2 : 0.0;
    canvas.drawCircle(
      ally,
      18 + pulse,
      Paint()..color = color.withValues(alpha: 0.2),
    );
    canvas.drawCircle(ally, 9, Paint()..color = color.withValues(alpha: 0.9));
    canvas.drawCircle(
      ally,
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    _ring(canvas, ally, 18, color.withValues(alpha: 0.45), 1.5);

    switch (id) {
      case 'sentinel':
        _ring(canvas, runner, 24, color.withValues(alpha: 0.55), 2);
      case 'spark':
        for (var i = 0; i < 4; i++) {
          final angle = t * 1.4 + i * math.pi / 2;
          canvas.drawLine(
            ally.translate(math.cos(angle) * 13, math.sin(angle) * 13),
            ally.translate(math.cos(angle) * 20, math.sin(angle) * 20),
            Paint()
              ..color = color.withValues(alpha: 0.8)
              ..strokeWidth = 2,
          );
        }
      case 'beacon':
        for (var ring = 0; ring < 2; ring++) {
          final phase = (t * 0.8 + ring / 2) % 1;
          _ring(
            canvas,
            ally,
            14 + phase * 24,
            color.withValues(alpha: (1 - phase) * 0.7),
            1.8,
          );
        }
    }
  }

  void _drawRunner(
    Canvas canvas,
    Offset position,
    Color runnerColor, {
    double radius = 14,
    double opacity = 1,
  }) {
    canvas.drawCircle(
      position,
      radius * 1.6,
      Paint()
        ..color = runnerColor.withValues(alpha: 0.16 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      position,
      radius,
      Paint()..color = runnerColor.withValues(alpha: 0.92 * opacity),
    );
    canvas.drawCircle(
      position,
      radius * 0.38,
      Paint()..color = Colors.white.withValues(alpha: 0.8 * opacity),
    );
  }

  void _ring(Canvas canvas, Offset center, double radius, Color ringColor, double width) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = ringColor
        ..strokeWidth = width,
    );
  }

  void _label(
    Canvas canvas,
    String text,
    Offset center,
    Color labelColor, {
    double fontSize = 14,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: labelColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) =>
      oldDelegate.category != category ||
      oldDelegate.id != id ||
      oldDelegate.color != color ||
      oldDelegate.time != time ||
      oldDelegate.animating != animating;
}
