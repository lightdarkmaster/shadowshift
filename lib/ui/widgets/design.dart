import 'package:flutter/material.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/theme.dart';

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
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool compact;
  final Color? color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.cyan;
    final child = Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
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
    );
    return AnimatedScale(
      scale: enabled && onPressed != null ? 1 : 0.97,
      duration: const Duration(milliseconds: 160),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
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
              borderRadius: BorderRadius.circular(compact ? 14 : 18),
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 20,
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
    this.padding = const EdgeInsets.all(18),
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
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface.withValues(alpha: 0.66),
        border: Border.all(color: borderColor ?? AppColors.cyan.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
              Text(title, style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1.6,
              )),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.icon, required this.value, this.color = AppColors.cyan});

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
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
          borderRadius: BorderRadius.circular(6),
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
