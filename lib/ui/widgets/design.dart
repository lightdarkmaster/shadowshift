import 'package:material_ui/material_ui.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/theme.dart';

/// Shared layout rhythm for every screen. Keeping these values in one place
/// stops individual pages from drifting by a few pixels at a time.
abstract final class AppLayout {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;

  static const double gutter = xl;
  static const double pageTop = md;
  static const double pageBottom = xxl;
  static const double maxContentWidth = 620;
  static const double gridGap = md;
  static const double sectionGap = 22;

  /// One padding value for every scrollable page body.
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    gutter,
    pageTop,
    gutter,
    pageBottom,
  );
}

/// Shared type ramp so headings and captions keep the same hierarchy on
/// every screen.
abstract final class AppTextStyles {
  static const screenTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.8,
  );
  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
  );
  static const caption = TextStyle(fontSize: 11, color: AppColors.muted);
  static const micro = TextStyle(fontSize: 10, color: AppColors.muted);
}

/// Corner radii shared by cards, buttons, chips and list tiles.
abstract final class AppRadius {
  static const double card = 20;
  static const double button = 18;
  static const double compactButton = 14;
  static const double chip = 12;
  static const double iconTile = 14;
  static const double progress = 6;
}

/// Wrap whose children share one calculated width, so grids fill the space
/// available instead of leaving a ragged half-empty row on common phones.
class ResponsiveTileWrap extends StatelessWidget {
  const ResponsiveTileWrap({
    super.key,
    required this.children,
    this.minTileWidth = 100,
    this.tileHeight,
    this.spacing = AppLayout.gridGap,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double? tileHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth + spacing) ~/ (minTileWidth + spacing);
        final count = columns < 1 ? 1 : columns;
        final width =
            (constraints.maxWidth - spacing * (count - 1)) / count;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: width,
                height: tileHeight,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.compact = false,
    this.color,
    this.enabled = true,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool compact;
  final Color? color;
  final bool enabled;

  /// Keeps an equipped item at full opacity instead of rendering it disabled.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.cyan;
    final interactive = enabled || selected;
    // Scale the whole label down on narrow screens instead of letting a long
    // uppercase label with letter spacing overflow the button's padding.
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: compact ? 18 : 21, color: accent),
          if (icon != null) const SizedBox(width: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondary ? AppColors.text : const Color(0xFF04121A),
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
    return AnimatedScale(
      scale: interactive && onPressed != null ? 1 : 0.97,
      duration: const Duration(milliseconds: 160),
      child: Opacity(
        opacity: interactive ? 1 : 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
                compact ? AppRadius.compactButton : AppRadius.button,
              ),
            gradient: secondary
                ? null
                : LinearGradient(colors: [accent, accent.withValues(alpha: 0.62)]),
            color: secondary ? AppColors.surfaceLight.withValues(alpha: 0.55) : null,
            border: Border.all(
              color: secondary ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.2),
              width: secondary ? 1.3 : 1,
            ),
            boxShadow: secondary
                ? null
                : [BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 18, spreadRadius: -4)],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                compact ? AppRadius.compactButton : AppRadius.button,
              ),
              onTap: interactive ? onPressed : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : AppLayout.lg,
                  vertical: compact ? 12 : 16,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppLayout.lg),
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: AppColors.surface.withValues(alpha: 0.66),
        border: Border.all(color: borderColor ?? AppColors.cyan.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 26, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4), gradient: neonGradient,
        )),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.sectionTitle),
              if (subtitle != null)
                Text(subtitle!, style: AppTextStyles.caption),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    this.color = AppColors.cyan,
    this.fill = false,
  });

  final IconData icon;
  final String value;
  final Color color;

  /// Fills its parent when used in equal-width stat rows.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fill ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientLabel extends StatelessWidget {
  const GradientLabel(this.text, {super.key, this.fontSize = 42, this.letterSpacing = 4});

  final String text;
  final double fontSize;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => neonGradient.createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: letterSpacing,
          color: Colors.white,
          height: 1.05,
        ),
      ),
    );
  }
}

class LevelBar extends StatelessWidget {
  const LevelBar({super.key, required this.level, required this.current, required this.total});

  final int level;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('LEVEL $level', style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppColors.cyan,
            )),
            Text('$current / $total XP', style: const TextStyle(
              fontSize: 11, color: AppColors.muted,
            )),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.progress),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.violet),
          ),
        ),
      ],
    );
  }
}
