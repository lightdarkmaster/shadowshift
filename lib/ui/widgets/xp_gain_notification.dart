import 'package:material_ui/material_ui.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/ranks.dart';
import 'package:shadowshift/ui/widgets/design.dart';

/// Small, finite animation shown with run XP. It never repeats, so it cannot
/// hurt frame rate during gameplay or keep widget tests unsettled.
class XpGainNotification extends StatelessWidget {
  const XpGainNotification({
    super.key,
    required this.awards,
    required this.total,
    this.color = AppColors.violet,
  });

  final List<RankXpAward> awards;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        final eased = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        '+$total XP',
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  if (awards.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final award in awards)
                          Text(
                            '${award.label} +${award.amount}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
